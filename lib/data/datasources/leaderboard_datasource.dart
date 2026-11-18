import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/leaderboard_entry.dart';

class LeaderboardDataSource {
  static const String _profileKeyPrefix = 'edumaster_user_profile_';
  static const String _leaderboardKey = 'edumaster_leaderboard_list';

  SharedPreferences? _prefs;
  List<LeaderboardEntry>? _cachedEntries;
  final Map<String, UserProfile> _profileCache = {};
  String? _currentActiveEmail;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Stream<List<LeaderboardEntry>> get leaderboardStream async* {
    final list = await getEntries();
    yield list;
  }

  Future<List<LeaderboardEntry>> getEntries() async {
    if (_cachedEntries != null && _cachedEntries!.isNotEmpty) {
      return _cachedEntries!;
    }

    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_leaderboardKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      final initialData = [
        const LeaderboardEntry(
          id: 'user_u1',
          userName: 'Đặng Mai Phương',
          avatarUrl: '',
          xp: 2850,
          streakDays: 14,
          testsCompleted: 38,
          badges: ['Thợ săn Tri thức', 'Bậc thầy Trắc nghiệm', '7 Ngày Chăm chỉ'],
          groupName: 'Nhóm F - KTHP',
        ),
        const LeaderboardEntry(
          id: 'user_u2',
          userName: 'Trần Bảo Long',
          avatarUrl: '',
          xp: 2420,
          streakDays: 9,
          testsCompleted: 29,
          badges: ['Chiến binh SM-2', 'Chuyên gia IT'],
          groupName: 'Nhóm F - KTHP',
        ),
        const LeaderboardEntry(
          id: 'user_u3',
          userName: 'Nguyễn Thị Hải Yến',
          avatarUrl: '',
          xp: 2190,
          streakDays: 12,
          testsCompleted: 25,
          badges: ['Ngôi sao Song ngữ', 'Người tiên phong'],
          groupName: 'Nhóm F - KTHP',
        ),
        const LeaderboardEntry(
          id: 'user_current',
          userName: 'Bạn (Sinh viên CNTT)',
          avatarUrl: '',
          xp: 1850,
          streakDays: 5,
          testsCompleted: 18,
          badges: ['Tân binh EduMaster', 'Khám phá Từ điển'],
          groupName: 'Nhóm F - KTHP',
        ),
        const LeaderboardEntry(
          id: 'user_u5',
          userName: 'Lê Minh Tuấn',
          avatarUrl: '',
          xp: 1420,
          streakDays: 4,
          testsCompleted: 12,
          badges: ['Tân binh'],
          groupName: 'Nhóm F - KTHP',
        ),
        // Thành viên Nhóm 1 - Lập trình Di động
        const LeaderboardEntry(
          id: 'user_u6',
          userName: 'Phạm Hoàng Nam',
          avatarUrl: '',
          xp: 3200,
          streakDays: 21,
          testsCompleted: 45,
          badges: ['Thần đồng Lập trình', 'Top 1 Server'],
          groupName: 'Nhóm 1 - Lập trình Di động',
        ),
        const LeaderboardEntry(
          id: 'user_u7',
          userName: 'Vũ Thị Minh Châu',
          avatarUrl: '',
          xp: 2650,
          streakDays: 11,
          testsCompleted: 33,
          badges: ['Chiến binh Bền bỉ'],
          groupName: 'Nhóm 1 - Lập trình Di động',
        ),
        const LeaderboardEntry(
          id: 'user_u8',
          userName: 'Đỗ Tuấn Kiệt',
          avatarUrl: '',
          xp: 1980,
          streakDays: 7,
          testsCompleted: 22,
          badges: ['Bậc thầy SM-2'],
          groupName: 'Nhóm 1 - Lập trình Di động',
        ),
        const LeaderboardEntry(
          id: 'user_u9',
          userName: 'Hoàng Quốc Bảo',
          avatarUrl: '',
          xp: 1530,
          streakDays: 5,
          testsCompleted: 16,
          badges: ['Khám phá Tri thức'],
          groupName: 'Nhóm 1 - Lập trình Di động',
        ),
        // Thành viên Nhóm 2 - Kiến trúc Flutter
        const LeaderboardEntry(
          id: 'user_u10',
          userName: 'Bùi Gia Huy',
          avatarUrl: '',
          xp: 2950,
          streakDays: 16,
          testsCompleted: 39,
          badges: ['Kiến trúc sư Clean Code'],
          groupName: 'Nhóm 2 - Kiến trúc Flutter',
        ),
        const LeaderboardEntry(
          id: 'user_u11',
          userName: 'Ngô Thanh Thảo',
          avatarUrl: '',
          xp: 2310,
          streakDays: 10,
          testsCompleted: 28,
          badges: ['Ngôi sao Song ngữ'],
          groupName: 'Nhóm 2 - Kiến trúc Flutter',
        ),
        const LeaderboardEntry(
          id: 'user_u12',
          userName: 'Trịnh Đức Anh',
          avatarUrl: '',
          xp: 1720,
          streakDays: 6,
          testsCompleted: 19,
          badges: ['Chăm chỉ Mỗi ngày'],
          groupName: 'Nhóm 2 - Kiến trúc Flutter',
        ),
      ];
      _cachedEntries = initialData;
      await prefs.setString(_leaderboardKey, json.encode(initialData.map((e) => e.toMap()).toList()));
      return initialData;
    }

    try {
      final List<dynamic> list = json.decode(jsonStr);
      final entries = list.map((e) => LeaderboardEntry.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      entries.sort((a, b) => b.xp.compareTo(a.xp));
      _cachedEntries = entries;
      return entries;
    } catch (_) {
      _cachedEntries = [];
      return [];
    }
  }

  Future<void> updateUserLeaderboard({
    required String userId,
    String? userName,
    String? groupName,
    int? xp,
  }) async {
    final entries = await getEntries();
    final idx = entries.indexWhere((e) => e.id == userId || e.id == 'user_current');
    if (idx >= 0) {
      final old = entries[idx];
      entries[idx] = LeaderboardEntry(
        id: old.id,
        userName: userName ?? old.userName,
        avatarUrl: old.avatarUrl,
        xp: xp ?? old.xp,
        streakDays: old.streakDays,
        testsCompleted: old.testsCompleted,
        badges: old.badges,
        groupName: groupName ?? old.groupName,
      );
    } else {
      entries.add(
        LeaderboardEntry(
          id: userId,
          userName: userName ?? 'Bạn (Sinh viên CNTT)',
          avatarUrl: '',
          xp: xp ?? 0,
          streakDays: 1,
          testsCompleted: 0,
          badges: const ['Tân binh EduMaster'],
          groupName: groupName ?? 'Nhóm F - KTHP',
        ),
      );
    }
    entries.sort((a, b) => b.xp.compareTo(a.xp));
    _cachedEntries = entries;
    final prefs = await _getPrefs();
    await prefs.setString(_leaderboardKey, json.encode(entries.map((e) => e.toMap()).toList()));
  }

  Future<void> updateXp(String userId, int addedXp) async {
    final entries = await getEntries();
    final idx = entries.indexWhere((e) => e.id == userId);
    if (idx >= 0) {
      final old = entries[idx];
      entries[idx] = LeaderboardEntry(
        id: old.id,
        userName: old.userName,
        avatarUrl: old.avatarUrl,
        xp: old.xp + addedXp,
        streakDays: old.streakDays,
        testsCompleted: old.testsCompleted + 1,
        badges: old.badges,
        groupName: old.groupName,
      );
      entries.sort((a, b) => b.xp.compareTo(a.xp));
      _cachedEntries = entries;

      final prefs = await _getPrefs();
      await prefs.setString(_leaderboardKey, json.encode(entries.map((e) => e.toMap()).toList()));
    }
  }

  /// Get user profile per user email. Newly registered users get clean 0 XP / 0 Streak Days profile.
  Future<UserProfile> getUserProfile({String? email}) async {
    final prefs = await _getPrefs();
    final targetEmail = (email ?? _currentActiveEmail ?? prefs.getString('edumaster_current_session_email') ?? '').trim().toLowerCase();

    if (targetEmail.isNotEmpty && _profileCache.containsKey(targetEmail)) {
      return _profileCache[targetEmail]!;
    }

    final key = '$_profileKeyPrefix$targetEmail';
    final jsonStr = prefs.getString(key);

    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final profile = UserProfile.fromMap(json.decode(jsonStr) as Map<String, dynamic>);
        if (targetEmail.isNotEmpty) _profileCache[targetEmail] = profile;
        return profile;
      } catch (_) {}
    }

    // Default profiles for Demo Accounts vs Clean Data for New Accounts
    UserProfile profile;
    if (targetEmail == 'student@edumaster.edu.vn') {
      profile = const UserProfile(
        uid: 'user_student_1',
        name: 'Bùi Ngọc (Sinh viên)',
        email: 'student@edumaster.edu.vn',
        totalXp: 1850,
        streakDays: 5,
        badges: ['Tân binh EduMaster', 'Chiến binh Học tập'],
        currentGroup: 'Sinh viên EduMaster',
      );
    } else if (targetEmail == 'teacher@edumaster.edu.vn') {
      profile = const UserProfile(
        uid: 'user_teacher_1',
        name: 'TS. Nguyễn Văn (Giáo viên)',
        email: 'teacher@edumaster.edu.vn',
        totalXp: 3500,
        streakDays: 14,
        badges: ['Giảng viên Xuất sắc', 'Bậc thầy Tạo đề'],
        currentGroup: 'Bộ môn Lập trình',
      );
    } else {
      // NEW REGISTERED USER: 100% Clean profile data with 0 XP & 0 Streak Days
      profile = UserProfile(
        uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Thành viên mới',
        email: targetEmail,
        totalXp: 0,
        streakDays: 0,
        badges: const [],
        currentGroup: 'Sinh viên EduMaster',
      );
    }

    if (targetEmail.isNotEmpty) {
      await saveUserProfile(profile);
    }
    return profile;
  }

  /// Save user profile for a specific user
  Future<void> saveUserProfile(UserProfile profile) async {
    final email = profile.email.trim().toLowerCase();
    _currentActiveEmail = email;
    if (email.isNotEmpty) {
      _profileCache[email] = profile;
    }

    final prefs = await _getPrefs();
    final key = '$_profileKeyPrefix$email';
    await prefs.setString(key, json.encode(profile.toMap()));

    // Also keep general fallback key in sync
    await prefs.setString('edumaster_user_profile', json.encode(profile.toMap()));
  }

  void clearProfileCache() {
    _profileCache.clear();
    _currentActiveEmail = null;
  }

  void dispose() {}
}
