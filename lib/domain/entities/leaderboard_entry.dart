class LeaderboardEntry {
  final String id;
  final String userName;
  final String avatarUrl; // local file path or cloud url
  final int xp;
  final int streakDays;
  final int testsCompleted;
  final List<String> badges;
  final String groupName;

  const LeaderboardEntry({
    required this.id,
    required this.userName,
    required this.avatarUrl,
    required this.xp,
    required this.streakDays,
    required this.testsCompleted,
    required this.badges,
    required this.groupName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userName': userName,
      'avatarUrl': avatarUrl,
      'xp': xp,
      'streakDays': streakDays,
      'testsCompleted': testsCompleted,
      'badges': badges,
      'groupName': groupName,
    };
  }

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      id: map['id']?.toString() ?? '',
      userName: map['userName']?.toString() ?? 'Thành viên',
      avatarUrl: map['avatarUrl']?.toString() ?? '',
      xp: (map['xp'] as num?)?.toInt() ?? 0,
      streakDays: (map['streakDays'] as num?)?.toInt() ?? 1,
      testsCompleted: (map['testsCompleted'] as num?)?.toInt() ?? 0,
      badges: (map['badges'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      groupName: map['groupName']?.toString() ?? 'Nhóm F - KTHP',
    );
  }
}

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String? localAvatarPath;
  final int totalXp;
  final int streakDays;
  final List<String> badges;
  final String currentGroup;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.localAvatarPath,
    this.totalXp = 0,
    this.streakDays = 1,
    this.badges = const ['Tân binh EduMaster'],
    this.currentGroup = 'Nhóm F - Lập trình Di động',
  });

  UserProfile copyWith({
    String? name,
    String? email,
    String? localAvatarPath,
    int? totalXp,
    int? streakDays,
    List<String>? badges,
    String? currentGroup,
  }) {
    return UserProfile(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      localAvatarPath: localAvatarPath ?? this.localAvatarPath,
      totalXp: totalXp ?? this.totalXp,
      streakDays: streakDays ?? this.streakDays,
      badges: badges ?? this.badges,
      currentGroup: currentGroup ?? this.currentGroup,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'localAvatarPath': localAvatarPath,
      'totalXp': totalXp,
      'streakDays': streakDays,
      'badges': badges,
      'currentGroup': currentGroup,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid']?.toString() ?? 'user_1',
      name: map['name']?.toString() ?? 'Sinh viên CNTT',
      email: map['email']?.toString() ?? 'student@edumaster.edu.vn',
      localAvatarPath: map['localAvatarPath']?.toString(),
      totalXp: (map['totalXp'] as num?)?.toInt() ?? 150,
      streakDays: (map['streakDays'] as num?)?.toInt() ?? 3,
      badges: (map['badges'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['Tân binh EduMaster'],
      currentGroup: map['currentGroup']?.toString() ?? 'Nhóm F - Lập trình Di động',
    );
  }
}
