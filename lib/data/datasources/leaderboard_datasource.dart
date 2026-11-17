import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/leaderboard_entry.dart';

class LeaderboardDataSource {
  static const String _profileKey = 'edumaster_user_profile';
  static const String _leaderboardKey = 'edumaster_leaderboard_list';

  SharedPreferences? _prefs;
  List<LeaderboardEntry>? _cachedEntries;
  UserProfile? _cachedProfile;

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

  Future<UserProfile> getUserProfile() async {
    if (_cachedProfile != null) return _cachedProfile!;

    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_profileKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      const defaultProfile = UserProfile(
        uid: 'user_current',
        name: 'Bùi Ngọc (Sinh viên)',
        email: 'buingoc@edumaster.edu.vn',
        totalXp: 1850,
        streakDays: 5,
        badges: ['Tân binh EduMaster', 'Chiến binh Học tập'],
        currentGroup: 'Nhóm F - Lập trình Di động',
      );
      await saveUserProfile(defaultProfile);
      _cachedProfile = defaultProfile;
      return defaultProfile;
    }

    try {
      _cachedProfile = UserProfile.fromMap(json.decode(jsonStr) as Map<String, dynamic>);
      return _cachedProfile!;
    } catch (_) {
      _cachedProfile = const UserProfile(uid: 'user_current', name: 'Sinh viên', email: 'student@edumaster.edu.vn');
      return _cachedProfile!;
    }
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    _cachedProfile = profile;
    final prefs = await _getPrefs();
    await prefs.setString(_profileKey, json.encode(profile.toMap()));

    // Keep leaderboard in sync
    final entries = await getEntries();
    final idx = entries.indexWhere((e) => e.id == profile.uid);
    if (idx >= 0) {
      entries[idx] = LeaderboardEntry(
        id: profile.uid,
        userName: '${profile.name} (Bạn)',
        avatarUrl: profile.localAvatarPath ?? '',
        xp: profile.totalXp,
        streakDays: profile.streakDays,
        testsCompleted: entries[idx].testsCompleted,
        badges: profile.badges,
        groupName: profile.currentGroup,
      );
      entries.sort((a, b) => b.xp.compareTo(a.xp));
      _cachedEntries = entries;
      await prefs.setString(_leaderboardKey, json.encode(entries.map((e) => e.toMap()).toList()));
    }
  }

  void dispose() {}
}
