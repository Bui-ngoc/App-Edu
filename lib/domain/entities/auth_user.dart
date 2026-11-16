class AuthUser {
  final String id;
  final String name;
  final String email;
  final String password;
  final String role; // 'teacher' or 'student'
  final String group;
  final String? avatarPath;
  final DateTime createdAt;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.role = 'student',
    this.group = 'Thành viên EduMaster',
    this.avatarPath,
    required this.createdAt,
  });

  bool get isTeacher => role.toLowerCase() == 'teacher';
  bool get isStudent => !isTeacher;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'group': group,
      'avatarPath': avatarPath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AuthUser.fromMap(Map<String, dynamic> map) {
    String roleVal = map['role']?.toString() ?? '';
    if (roleVal.isEmpty) {
      final emailStr = (map['email']?.toString() ?? '').toLowerCase();
      final groupStr = (map['group']?.toString() ?? '').toLowerCase();
      final nameStr  = (map['name']?.toString() ?? '').toLowerCase();

      if (emailStr.contains('teacher') ||
          emailStr.contains('giangvien') ||
          emailStr.contains('giaovien') ||
          emailStr.contains('gv') ||
          groupStr.contains('giáo viên') ||
          groupStr.contains('giảng viên') ||
          groupStr.contains('bộ môn') ||
          nameStr.contains('giáo viên') ||
          nameStr.contains('giảng viên') ||
          nameStr.contains('ts.') ||
          nameStr.contains('ths.') ||
          nameStr.contains('gs.')) {
        roleVal = 'teacher';
      } else {
        roleVal = 'student';
      }
    }

    return AuthUser(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Người dùng',
      email: map['email']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      role: roleVal,
      group: map['group']?.toString() ?? 'Thành viên EduMaster',
      avatarPath: map['avatarPath']?.toString(),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  AuthUser copyWith({
    String? name,
    String? email,
    String? password,
    String? role,
    String? group,
    String? avatarPath,
  }) {
    return AuthUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      group: group ?? this.group,
      avatarPath: avatarPath ?? this.avatarPath,
      createdAt: createdAt,
    );
  }
}
