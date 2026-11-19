import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/auth_user.dart';
import 'leaderboard_datasource.dart';

class AuthLocalDataSource {
  static const String _usersKey = 'edumaster_registered_users_v2';
  static const String _currentSessionKey = 'edumaster_current_session_email';
  static const String _isLoggedInKey = 'edumaster_is_user_logged_in';

  final LeaderboardDataSource _leaderboardDataSource;
  SharedPreferences? _prefs;
  List<AuthUser>? _cachedUsers;

  AuthLocalDataSource({required LeaderboardDataSource leaderboardDataSource})
      : _leaderboardDataSource = leaderboardDataSource;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Get list of registered users.
  Future<List<AuthUser>> getRegisteredUsers() async {
    if (_cachedUsers != null && _cachedUsers!.isNotEmpty) {
      return _cachedUsers!;
    }

    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_usersKey);
    List<AuthUser> users = [];

    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(jsonStr);
        users = list.map((e) => AuthUser.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      } catch (_) {}
    }

    _cachedUsers = users;
    return users;
  }

  /// Check whether a user is currently logged in
  Future<bool> isLoggedIn() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  /// Get currently logged in user
  Future<AuthUser?> getCurrentUser() async {
    final prefs = await _getPrefs();
    final loggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    if (!loggedIn) return null;

    final email = prefs.getString(_currentSessionKey);
    if (email == null || email.isEmpty) return null;

    final users = await getRegisteredUsers();
    try {
      return users.firstWhere(
        (u) => u.email.trim().toLowerCase() == email.trim().toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Register a new account
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
    String role = 'student',
    String group = '',
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();
    final cleanName = name.trim();
    final cleanRole = role.trim().toLowerCase();

    if (cleanName.isEmpty) {
      throw Exception('Vui lòng nhập họ và tên của bạn.');
    }
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw Exception('Vui lòng nhập địa chỉ email hợp lệ.');
    }
    if (cleanPassword.length < 6) {
      throw Exception('Mật khẩu phải có độ dài tối thiểu 6 ký tự.');
    }

    final users = await getRegisteredUsers();

    final exists = users.any((u) => u.email.trim().toLowerCase() == cleanEmail);
    if (exists) {
      throw Exception('Email "$cleanEmail" đã được đăng ký. Vui lòng đăng nhập!');
    }

    final prefix = cleanRole == 'teacher' ? 'GV' : 'SV';
    final randNum = 1000 + (DateTime.now().millisecondsSinceEpoch % 9000);
    final newUser = AuthUser(
      id: '$prefix$randNum',
      name: cleanName,
      email: cleanEmail,
      password: cleanPassword,
      role: cleanRole == 'teacher' ? 'teacher' : 'student',
      group: cleanRole == 'teacher' ? 'Bộ môn Lập trình' : '',
      createdAt: DateTime.now(),
    );

    users.add(newUser);
    _cachedUsers = users;

    final prefs = await _getPrefs();
    await prefs.setString(
      _usersKey,
      json.encode(users.map((e) => e.toMap()).toList()),
    );

    // Save session
    await prefs.setString(_currentSessionKey, cleanEmail);
    await prefs.setBool(_isLoggedInKey, true);

    // Sync to UserProfile in LeaderboardDataSource
    await _syncProfile(newUser);

    return newUser;
  }

  /// Login with email and password
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty) {
      throw Exception('Vui lòng nhập email đăng nhập.');
    }
    if (cleanPassword.isEmpty) {
      throw Exception('Vui lòng nhập mật khẩu.');
    }

    final users = await getRegisteredUsers();
    final userIdx = users.indexWhere(
      (u) => u.email.trim().toLowerCase() == cleanEmail,
    );

    if (userIdx < 0) {
      throw Exception('Tài khoản email này chưa được đăng ký trong hệ thống.');
    }

    final user = users[userIdx];
    if (user.password != cleanPassword) {
      throw Exception('Mật khẩu không chính xác. Vui lòng kiểm tra lại!');
    }

    final prefs = await _getPrefs();
    await prefs.setString(_currentSessionKey, cleanEmail);
    await prefs.setBool(_isLoggedInKey, true);

    // Sync to UserProfile
    await _syncProfile(user);

    return user;
  }



  /// Find a user by Student/Teacher ID or Email
  Future<AuthUser?> getUserById(String idOrEmail) async {
    final clean = idOrEmail.trim().toLowerCase();
    if (clean.isEmpty) return null;
    final users = await getRegisteredUsers();
    try {
      return users.firstWhere(
        (u) =>
            u.id.toLowerCase() == clean ||
            u.email.toLowerCase() == clean,
      );
    } catch (_) {
      return null;
    }
  }

  /// Update user's study group
  Future<void> updateUserGroup(String userId, String newGroupName) async {
    final users = await getRegisteredUsers();
    final cleanId = userId.trim().toLowerCase();
    final idx = users.indexWhere((u) => u.id.toLowerCase() == cleanId);

    if (idx >= 0) {
      final updated = users[idx].copyWith(group: newGroupName.trim());
      users[idx] = updated;
      _cachedUsers = users;

      final prefs = await _getPrefs();
      await prefs.setString(_usersKey, json.encode(users.map((e) => e.toMap()).toList()));
      await _syncProfile(updated);
    }
  }

  /// Logout
  Future<void> logout() async {
    final prefs = await _getPrefs();
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.remove(_currentSessionKey);
    _leaderboardDataSource.clearProfileCache();
  }

  Future<void> _syncProfile(AuthUser user) async {
    final email = user.email.trim().toLowerCase();
    final currentProfile = await _leaderboardDataSource.getUserProfile(email: email);
    final updated = currentProfile.copyWith(
      name: user.name,
      email: user.email,
      currentGroup: user.group,
    );
    await _leaderboardDataSource.saveUserProfile(updated);
  }
}
