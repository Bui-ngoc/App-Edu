import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/auth_user.dart';
import 'leaderboard_datasource.dart';

class AuthLocalDataSource {
  static const String _usersKey = 'edumaster_registered_users';
  static const String _currentSessionKey = 'edumaster_current_session_email';
  static const String _isLoggedInKey = 'edumaster_is_user_logged_in';

  final LeaderboardDataSource _leaderboardDataSource;

  AuthLocalDataSource({required LeaderboardDataSource leaderboardDataSource})
      : _leaderboardDataSource = leaderboardDataSource;

  /// Get list of registered users. Seed default account if empty.
  Future<List<AuthUser>> getRegisteredUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_usersKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      final defaultUsers = [
        AuthUser(
          id: 'user_u1',
          name: 'Bùi Ngọc',
          email: 'student@edumaster.edu.vn',
          password: '123456',
          group: 'Nhóm F - Lập trình Di động',
          createdAt: DateTime.now(),
        ),
      ];
      await prefs.setString(
        _usersKey,
        json.encode(defaultUsers.map((e) => e.toMap()).toList()),
      );
      return defaultUsers;
    }

    try {
      final List<dynamic> list = json.decode(jsonStr);
      return list.map((e) => AuthUser.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  /// Check whether a user is currently logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  /// Get currently logged in user
  Future<AuthUser?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
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
    required String group,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();
    final cleanName = name.trim();
    final cleanGroup = group.trim();

    if (cleanName.isEmpty) {
      throw Exception('Vui lòng nhập họ và tên của bạn.');
    }
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw Exception('Vui lòng nhập địa chỉ email hợp lệ.');
    }
    if (cleanPassword.length < 6) {
      throw Exception('Mật khẩu phải có độ dài tối thiểu 6 ký tự.');
    }

    final prefs = await SharedPreferences.getInstance();
    final users = await getRegisteredUsers();

    final exists = users.any((u) => u.email.trim().toLowerCase() == cleanEmail);
    if (exists) {
      throw Exception('Email "$cleanEmail" đã được đăng ký. Vui lòng đăng nhập!');
    }

    final newUser = AuthUser(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: cleanName,
      email: cleanEmail,
      password: cleanPassword,
      group: cleanGroup.isNotEmpty ? cleanGroup : 'Khối 12 - Ôn thi KTHP',
      createdAt: DateTime.now(),
    );

    users.add(newUser);
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentSessionKey, cleanEmail);
    await prefs.setBool(_isLoggedInKey, true);

    // Sync to UserProfile
    await _syncProfile(user);

    return user;
  }

  /// Quick Demo Login (for grading/quick presentation)
  Future<AuthUser> quickDemoLogin() async {
    final users = await getRegisteredUsers();
    if (users.isNotEmpty) {
      final demoUser = users.first;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentSessionKey, demoUser.email);
      await prefs.setBool(_isLoggedInKey, true);
      await _syncProfile(demoUser);
      return demoUser;
    }

    return register(
      name: 'Bùi Ngọc (Sinh viên)',
      email: 'student@edumaster.edu.vn',
      password: '123456',
      group: 'Nhóm F - Lập trình Di động',
    );
  }

  /// Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.remove(_currentSessionKey);
  }

  Future<void> _syncProfile(AuthUser user) async {
    final currentProfile = await _leaderboardDataSource.getUserProfile();
    final updated = currentProfile.copyWith(
      name: user.name,
      email: user.email,
      currentGroup: user.group,
    );
    await _leaderboardDataSource.saveUserProfile(updated);
  }
}
