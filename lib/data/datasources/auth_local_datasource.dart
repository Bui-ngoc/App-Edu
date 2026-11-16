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

  /// Get list of registered users. Seed default accounts if missing.
  Future<List<AuthUser>> getRegisteredUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_usersKey);
    List<AuthUser> users = [];

    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(jsonStr);
        users = list.map((e) => AuthUser.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      } catch (_) {}
    }

    bool needsSave = false;

    // Ensure default student account exists
    if (!users.any((u) => u.email.trim().toLowerCase() == 'student@edumaster.edu.vn')) {
      users.add(AuthUser(
        id: 'user_student_1',
        name: 'Bùi Ngọc (Sinh viên)',
        email: 'student@edumaster.edu.vn',
        password: '123456',
        role: 'student',
        group: 'Sinh viên EduMaster',
        createdAt: DateTime.now(),
      ));
      needsSave = true;
    }

    // Ensure default teacher account exists
    if (!users.any((u) => u.email.trim().toLowerCase() == 'teacher@edumaster.edu.vn')) {
      users.add(AuthUser(
        id: 'user_teacher_1',
        name: 'TS. Nguyễn Văn (Giáo viên)',
        email: 'teacher@edumaster.edu.vn',
        password: '123456',
        role: 'teacher',
        group: 'Bộ môn Lập trình',
        createdAt: DateTime.now(),
      ));
      needsSave = true;
    }

    if (needsSave || jsonStr == null || jsonStr.isEmpty) {
      await prefs.setString(_usersKey, json.encode(users.map((e) => e.toMap()).toList()));
    }

    return users;
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
    String role = 'student',
    String group = 'Thành viên EduMaster',
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
      role: cleanRole == 'teacher' ? 'teacher' : 'student',
      group: cleanRole == 'teacher' ? 'Giảng viên' : 'Sinh viên',
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
  Future<AuthUser> quickDemoLogin({String role = 'student'}) async {
    final users = await getRegisteredUsers();
    final targetRole = role.toLowerCase();
    AuthUser? demoUser;

    try {
      demoUser = users.firstWhere((u) => u.role == targetRole);
    } catch (_) {
      if (users.isNotEmpty) demoUser = users.first;
    }

    if (demoUser != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentSessionKey, demoUser.email);
      await prefs.setBool(_isLoggedInKey, true);
      await _syncProfile(demoUser);
      return demoUser;
    }

    final isTeacher = targetRole == 'teacher';
    return register(
      name: isTeacher ? 'TS. Nguyễn Văn (Giáo viên)' : 'Bùi Ngọc (Sinh viên)',
      email: isTeacher ? 'teacher@edumaster.edu.vn' : 'student@edumaster.edu.vn',
      password: '123456',
      role: isTeacher ? 'teacher' : 'student',
    );
  }

  /// Switch role for current account
  Future<AuthUser> switchRole(String email, String newRole) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await getRegisteredUsers();
    final cleanEmail = email.trim().toLowerCase();
    final cleanRole = newRole.trim().toLowerCase() == 'teacher' ? 'teacher' : 'student';

    final userIdx = users.indexWhere((u) => u.email.trim().toLowerCase() == cleanEmail);
    if (userIdx >= 0) {
      final oldUser = users[userIdx];
      final updatedUser = oldUser.copyWith(
        role: cleanRole,
        group: cleanRole == 'teacher' ? 'Giảng viên' : 'Sinh viên',
      );
      users[userIdx] = updatedUser;
      await prefs.setString(_usersKey, json.encode(users.map((e) => e.toMap()).toList()));
      await _syncProfile(updatedUser);
      return updatedUser;
    }
    throw Exception('Không tìm thấy người dùng');
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
