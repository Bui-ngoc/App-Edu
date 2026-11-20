import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/leaderboard_entry.dart';
import 'app_database.dart';

class LeaderboardDataSource {
  static const String _profileKeyPrefix = 'edumaster_user_profile_v8_';
  static const String _globalLeaderboardKey = 'edumaster_global_leaderboard_list_v8';
  static const String _globalGroupsListKey = 'edumaster_global_study_groups_list_v8';
  static const String _groupOwnersKey = 'edumaster_group_creators_map_v8';

  String get _leaderboardKey => _globalLeaderboardKey;
  String get _groupsListKey => _globalGroupsListKey;

  void switchUser(String userId, {String? email}) {
    _cachedEntries = null;
  }

  SharedPreferences? _prefs;
  List<LeaderboardEntry>? _cachedEntries;
  final Map<String, UserProfile> _profileCache = {};

  final StreamController<List<LeaderboardEntry>> _streamController =
      StreamController<List<LeaderboardEntry>>.broadcast();

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Stream<List<LeaderboardEntry>> get leaderboardStream {
    getEntries().then((entries) {
      if (!_streamController.isClosed) {
        _streamController.add(entries);
      }
    });
    return _streamController.stream;
  }

  void _emitRealtime(List<LeaderboardEntry> list) {
    if (!_streamController.isClosed) {
      _streamController.add(List.unmodifiable(list));
    }
  }



  Future<List<LeaderboardEntry>> getEntries() async {
    if (_cachedEntries != null && _cachedEntries!.isNotEmpty) {
      return _cachedEntries!;
    }

    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_leaderboardKey);
    List<LeaderboardEntry> entries = [];

    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(jsonStr);
        entries = list.map((e) => LeaderboardEntry.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      } catch (_) {}
    }

    // Tự động làm sạch các tài khoản mẫu mock từ phiên bản cũ (user_u01..user_u30 hoặc Nhóm 01 mẫu)
    final initialLength = entries.length;
    entries.removeWhere((e) =>
        e.id.startsWith('user_u') ||
        (e.groupName == 'Nhóm 01' && (e.id.startsWith('user_') || e.id.contains('u'))));

    if (entries.length != initialLength) {
      await prefs.setString(_leaderboardKey, json.encode(entries.map((e) => e.toMap()).toList()));
    }

    entries.sort((a, b) => b.xp.compareTo(a.xp));
    _cachedEntries = entries;
    _emitRealtime(entries);
    return entries;
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
          groupName: groupName ?? '',
        ),
      );
    }
    entries.sort((a, b) => b.xp.compareTo(a.xp));
    _cachedEntries = entries;
    final prefs = await _getPrefs();
    await prefs.setString(_leaderboardKey, json.encode(entries.map((e) => e.toMap()).toList()));
    _emitRealtime(entries);
  }

  // ── Quản lý nhóm học tập (Giáo viên tạo nhóm, phân công SV) ─────────────

  // ── Quản lý nhóm học tập (Giáo viên tạo nhóm, phân công SV) ─────────────

  Future<List<String>> getGroups() async {
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_groupsListKey);
    List<String> groups = [];
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(jsonStr);
        groups = list.map((e) => e.toString().trim()).where((g) => g.isNotEmpty).toList();
      } catch (_) {}
    }

    // Lọc bỏ 'Nhóm 01' nếu nó chỉ là nhóm mẫu mock cũ và không có sinh viên thực tế nào
    final entries = await getEntries();
    final hasRealStudentsInNhom01 = entries.any((e) => e.groupName == 'Nhóm 01' && !e.id.startsWith('user_u'));
    if (!hasRealStudentsInNhom01) {
      groups.remove('Nhóm 01');
    }
    // Lọc bỏ các nhóm rác khác nếu còn sót lại
    groups.removeWhere((g) => g.contains('KTHP') || g.contains('Flutter Pro') || g.contains('Lập Trình Di Động'));

    // Đảm bảo mọi nhóm có sinh viên thực tế thuộc về đều được hiển thị
    for (final e in entries) {
      final g = e.groupName.trim();
      if (g.isNotEmpty && !groups.contains(g)) {
        groups.add(g);
      }
    }

    await prefs.setString(_groupsListKey, json.encode(groups));
    return groups;
  }

  Future<Map<String, String>> _getGroupOwners() async {
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_groupOwnersKey);
    if (jsonStr == null || jsonStr.isEmpty) return {};
    try {
      return Map<String, String>.from(json.decode(jsonStr));
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveGroupOwners(Map<String, String> owners) async {
    final prefs = await _getPrefs();
    await prefs.setString(_groupOwnersKey, json.encode(owners));
  }

  /// Trả về danh sách nhóm do giáo viên cụ thể quản lý (tài khoản mới bắt đầu với 0 nhóm)
  Future<List<String>> getTeacherGroups(String teacherId) async {
    final cleanId = teacherId.trim().toLowerCase();
    final allGroups = await getGroups();
    if (cleanId.isEmpty) return allGroups;

    final owners = await _getGroupOwners();

    // Đối với các nhóm thực tế đã tạo từ trước mà chưa ghi nhận chủ sở hữu (ví dụ nhom test),
    // tự động gán cho giáo viên hiện tại để bảo toàn nhóm đã tạo
    bool updatedOwners = false;
    for (final grp in allGroups) {
      if (!owners.containsKey(grp)) {
        owners[grp] = cleanId;
        updatedOwners = true;
      }
    }
    if (updatedOwners) {
      await _saveGroupOwners(owners);
    }

    return allGroups.where((g) => owners[g]?.toLowerCase() == cleanId).toList();
  }

  Future<void> createGroup(String groupName, {String? teacherId}) async {
    final clean = groupName.trim();
    if (clean.isEmpty) return;
    final groups = await getGroups();
    if (!groups.contains(clean)) {
      groups.add(clean);
      final prefs = await _getPrefs();
      await prefs.setString(_groupsListKey, json.encode(groups));
    }
    if (teacherId != null && teacherId.trim().isNotEmpty) {
      final owners = await _getGroupOwners();
      owners[clean] = teacherId.trim().toLowerCase();
      await _saveGroupOwners(owners);
    }
    try {
      await AppDatabase.instance.insertStudyGroup(clean, teacherId ?? 'teacher');
    } catch (_) {}
  }

  Future<void> deleteGroup(String groupName, {String? teacherId}) async {
    final clean = groupName.trim();
    final groups = await getGroups();
    groups.remove(clean);
    final prefs = await _getPrefs();
    await prefs.setString(_groupsListKey, json.encode(groups));

    final owners = await _getGroupOwners();
    owners.remove(clean);
    await _saveGroupOwners(owners);

    final fallbackGroup = groups.isNotEmpty ? groups.first : '';
    final entries = await getEntries();
    bool modified = false;
    for (int i = 0; i < entries.length; i++) {
      if (entries[i].groupName == clean) {
        entries[i] = LeaderboardEntry(
          id: entries[i].id,
          userName: entries[i].userName,
          avatarUrl: entries[i].avatarUrl,
          xp: entries[i].xp,
          streakDays: entries[i].streakDays,
          testsCompleted: entries[i].testsCompleted,
          badges: entries[i].badges,
          groupName: fallbackGroup,
        );
        modified = true;
      }
    }
    if (modified) {
      _cachedEntries = entries;
      await prefs.setString(_leaderboardKey, json.encode(entries.map((e) => e.toMap()).toList()));
      _emitRealtime(entries);
    }
  }

  Future<void> renameGroup(String oldName, String newName, {String? teacherId}) async {
    final cleanOld = oldName.trim();
    final cleanNew = newName.trim();
    if (cleanNew.isEmpty || cleanOld == cleanNew) return;

    final groups = await getGroups();
    final idx = groups.indexOf(cleanOld);
    if (idx >= 0) {
      groups[idx] = cleanNew;
    } else {
      groups.add(cleanNew);
    }
    final prefs = await _getPrefs();
    await prefs.setString(_groupsListKey, json.encode(groups));

    final owners = await _getGroupOwners();
    final oldOwner = owners.remove(cleanOld);
    final newOwner = oldOwner ?? (teacherId != null && teacherId.trim().isNotEmpty ? teacherId.trim().toLowerCase() : null);
    if (newOwner != null) {
      owners[cleanNew] = newOwner;
    }
    await _saveGroupOwners(owners);

    final entries = await getEntries();
    bool modified = false;
    for (int i = 0; i < entries.length; i++) {
      if (entries[i].groupName == cleanOld) {
        entries[i] = LeaderboardEntry(
          id: entries[i].id,
          userName: entries[i].userName,
          avatarUrl: entries[i].avatarUrl,
          xp: entries[i].xp,
          streakDays: entries[i].streakDays,
          testsCompleted: entries[i].testsCompleted,
          badges: entries[i].badges,
          groupName: cleanNew,
        );
        modified = true;
      }
    }
    if (modified) {
      _cachedEntries = entries;
      await prefs.setString(_leaderboardKey, json.encode(entries.map((e) => e.toMap()).toList()));
      _emitRealtime(entries);
    }
  }

  /// Giáo viên chuyển hoặc thêm sinh viên sang một nhóm học khác
  Future<void> moveStudentToGroup(
    String studentId,
    String newGroupName, {
    String? studentName,
    String? studentEmail,
  }) async {
    final cleanGroup = newGroupName.trim();
    if (cleanGroup.isEmpty) return;
    await createGroup(cleanGroup);

    final entries = await getEntries();
    final cleanId = studentId.trim();
    final idx = entries.indexWhere((e) => e.id.toLowerCase() == cleanId.toLowerCase());
    if (idx >= 0) {
      final old = entries[idx];
      entries[idx] = LeaderboardEntry(
        id: old.id,
        userName: studentName ?? old.userName,
        avatarUrl: old.avatarUrl,
        xp: old.xp,
        streakDays: old.streakDays,
        testsCompleted: old.testsCompleted,
        badges: old.badges,
        groupName: cleanGroup,
      );
    } else {
      // Sinh viên mới chưa có trong danh sách bảng xếp hạng -> Thêm mới vào nhóm
      entries.add(
        LeaderboardEntry(
          id: cleanId,
          userName: studentName ?? 'Sinh viên ($cleanId)',
          avatarUrl: '',
          xp: 0,
          streakDays: 1,
          testsCompleted: 0,
          badges: const ['Tân binh EduMaster'],
          groupName: cleanGroup,
        ),
      );
    }
    _cachedEntries = entries;
    final prefs = await _getPrefs();
    await prefs.setString(_leaderboardKey, json.encode(entries.map((e) => e.toMap()).toList()));
    _emitRealtime(entries);

    // Đồng bộ trực tiếp vào UserProfile nếu có email
    if (studentEmail != null && studentEmail.trim().isNotEmpty) {
      final profile = await getUserProfile(email: studentEmail);
      await saveUserProfile(profile.copyWith(currentGroup: cleanGroup));
    }
  }

  /// Giáo viên thêm mới một sinh viên vào nhóm học
  Future<void> addStudentToGroup({
    required String name,
    required String groupName,
    int initialXp = 0,
  }) async {
    final cleanGroup = groupName.trim();
    final cleanName = name.trim();
    if (cleanGroup.isEmpty || cleanName.isEmpty) return;
    await createGroup(cleanGroup);

    final entries = await getEntries();
    final newStudent = LeaderboardEntry(
      id: 'user_sv_${DateTime.now().millisecondsSinceEpoch}',
      userName: cleanName,
      avatarUrl: '',
      xp: initialXp,
      streakDays: 1,
      testsCompleted: 0,
      badges: const ['Tân binh EduMaster'],
      groupName: cleanGroup,
    );
    entries.add(newStudent);
    entries.sort((a, b) => b.xp.compareTo(a.xp));
    _cachedEntries = entries;
    final prefs = await _getPrefs();
    await prefs.setString(_leaderboardKey, json.encode(entries.map((e) => e.toMap()).toList()));
    _emitRealtime(entries);
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
      _emitRealtime(entries);
    }
  }

  /// Get user profile per user email. Always reads fresh data from disk.
  Future<UserProfile> getUserProfile({String? email}) async {
    final prefs = await _getPrefs();
    final currentSessionEmail = prefs.getString('edumaster_current_session_email') ?? '';
    final targetEmail = (email != null && email.trim().isNotEmpty
        ? email.trim()
        : currentSessionEmail).trim().toLowerCase();

    final key = '$_profileKeyPrefix$targetEmail';
    final jsonStr = prefs.getString(key);

    // Lấy thông tin nhóm mới nhất từ danh sách AuthUser đã đăng ký
    String groupFromAuth = '';
    String nameFromAuth = 'Thành viên mới';
    final authUsersJson = prefs.getString('edumaster_registered_users_v2');
    if (authUsersJson != null && authUsersJson.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(authUsersJson);
        final found = list.firstWhere(
          (u) =>
              u['email']?.toString().trim().toLowerCase() == targetEmail ||
              u['id']?.toString().trim().toLowerCase() == targetEmail,
          orElse: () => null,
        );
        if (found != null) {
          groupFromAuth = found['group']?.toString().trim() ?? '';
          nameFromAuth = found['name']?.toString().trim() ?? nameFromAuth;
        }
      } catch (_) {}
    }

    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final profile = UserProfile.fromMap(json.decode(jsonStr) as Map<String, dynamic>);
        // Nếu auth user đã được GV phân nhóm nhưng profile chưa cập nhật, tự động sync!
        if (groupFromAuth.isNotEmpty && profile.currentGroup != groupFromAuth) {
          final updated = profile.copyWith(currentGroup: groupFromAuth);
          if (targetEmail.isNotEmpty) _profileCache[targetEmail] = updated;
          await saveUserProfile(updated);
          return updated;
        }
        if (targetEmail.isNotEmpty) _profileCache[targetEmail] = profile;
        return profile;
      } catch (_) {}
    }

    // Clean data for registered user: 0 XP, 0 Streak, kèm nhóm từ Auth nếu có
    UserProfile profile = UserProfile(
      uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: nameFromAuth,
      email: targetEmail,
      totalXp: 0,
      streakDays: 0,
      badges: const [],
      currentGroup: groupFromAuth,
    );

    if (targetEmail.isNotEmpty) {
      await saveUserProfile(profile);
    }
    return profile;
  }

  /// Check and record daily streak when user enters the app/logs in
  Future<({UserProfile profile, bool isNewStreak})> checkAndRecordDailyStreak({String? email}) async {
    final prefs = await _getPrefs();
    final profile = await getUserProfile(email: email);
    final targetEmail = profile.email.trim().toLowerCase();

    final lastActiveKey = 'edumaster_last_streak_date_$targetEmail';
    final lastActiveStr = prefs.getString(lastActiveKey);
    final todayStr = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

    if (lastActiveStr == todayStr && profile.streakDays > 0) {
      return (profile: profile, isNewStreak: false);
    }

    int newStreak = profile.streakDays;
    if (lastActiveStr == null || lastActiveStr.isEmpty || profile.streakDays == 0) {
      // First active day for user -> Day 1!
      newStreak = 1;
    } else {
      try {
        final parts = lastActiveStr.split('-');
        final lastDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        final todayDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
        final diffInDays = todayDate.difference(lastDate).inDays;

        if (diffInDays == 1) {
          newStreak = profile.streakDays + 1;
        } else if (diffInDays > 1) {
          newStreak = 1; // Reset streak if user missed days
        }
      } catch (_) {
        newStreak = 1;
      }
    }

    final updatedBadges = List<String>.from(profile.badges);
    if (newStreak >= 1 && !updatedBadges.contains('Tân binh EduMaster')) {
      updatedBadges.add('Tân binh EduMaster');
    }

    final updatedProfile = profile.copyWith(
      streakDays: newStreak,
      badges: updatedBadges,
    );

    await prefs.setString(lastActiveKey, todayStr);
    await saveUserProfile(updatedProfile);

    return (profile: updatedProfile, isNewStreak: true);
  }

  /// Save user profile for a specific user
  Future<void> saveUserProfile(UserProfile profile) async {
    final email = profile.email.trim().toLowerCase();
    if (email.isNotEmpty) {
      _profileCache[email] = profile;
    }

    final prefs = await _getPrefs();
    final key = '$_profileKeyPrefix$email';
    await prefs.setString(key, json.encode(profile.toMap()));

    // Also keep general fallback key in sync
    await prefs.setString('edumaster_user_profile', json.encode(profile.toMap()));

    // Sync to SQLite AppDatabase for Database Inspector
    try {
      await AppDatabase.instance.insertUserProfile(profile);
    } catch (_) {}
  }

  void clearProfileCache() {
    _profileCache.clear();
  }

  void dispose() {}
}
