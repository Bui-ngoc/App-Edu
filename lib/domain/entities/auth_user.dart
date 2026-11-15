class AuthUser {
  final String id;
  final String name;
  final String email;
  final String password;
  final String group;
  final String? avatarPath;
  final DateTime createdAt;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.group,
    this.avatarPath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'group': group,
      'avatarPath': avatarPath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AuthUser.fromMap(Map<String, dynamic> map) {
    return AuthUser(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Học viên',
      email: map['email']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      group: map['group']?.toString() ?? 'Khối 12 - Ôn thi KTHP',
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
    String? group,
    String? avatarPath,
  }) {
    return AuthUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      group: group ?? this.group,
      avatarPath: avatarPath ?? this.avatarPath,
      createdAt: createdAt,
    );
  }
}
