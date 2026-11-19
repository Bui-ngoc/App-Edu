import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/leaderboard_entry.dart';

class LeaderboardDataSource {
  static const String _profileKeyPrefix = 'edumaster_user_profile_v7_';
  static const String _leaderboardKeyPrefix = 'edumaster_leaderboard_list_v7_';
  static const String _groupsListKeyPrefix = 'edumaster_study_groups_list_v7_';

  String _userId = 'default';
  String _activeEmail = '';

  String get _leaderboardKey => '$_leaderboardKeyPrefix${_userId}_${_activeEmail.replaceAll('@', '_').replaceAll('.', '_')}';
  String get _groupsListKey => '$_groupsListKeyPrefix${_userId}_${_activeEmail.replaceAll('@', '_').replaceAll('.', '_')}';

  void switchUser(String userId, {String? email}) {
    final cleanId = userId.trim().toLowerCase();
    _userId = cleanId.isEmpty ? 'default' : cleanId;
    if (email != null && email.trim().isNotEmpty) {
      _activeEmail = email.trim().toLowerCase();
      _currentActiveEmail = _activeEmail;
    }
    _cachedEntries = null;
  }

  SharedPreferences? _prefs;
  List<LeaderboardEntry>? _cachedEntries;
  final Map<String, UserProfile> _profileCache = {};
  String? _currentActiveEmail;

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

  /// 30 thành viên mẫu của "Nhóm 01" với điểm tích lũy hoạt động EXP để xếp hạng
  static List<LeaderboardEntry> _createDefault30Members() {
    return const [
      LeaderboardEntry(
        id: 'user_u01',
        userName: 'Đặng Mai Phương',
        avatarUrl: '',
        xp: 3650,
        streakDays: 24,
        testsCompleted: 48,
        badges: ['Thợ săn Tri thức', 'Bậc thầy Trắc nghiệm', '14 Ngày Chăm chỉ'],
        groupName: 'Nhóm 01',
      ),
      LeaderboardEntry(
        id: 'user_u02',
        userName: 'Phạm Hoàng Nam',
        avatarUrl: '',
        xp: 3420,
        streakDays: 20,
        testsCompleted: 44,
        badges: ['Thần đồng Lập trình', 'Top Server'],
        groupName: 'Nhóm 01',
      ),
      LeaderboardEntry(
        id: 'user_u03',
        userName: 'Vũ Thị Minh Châu',
        avatarUrl: '',
        xp: 3290,
        streakDays: 18,
        testsCompleted: 41,
        badges: ['Chiến binh Bền bỉ', 'Ngôi sao Song ngữ'],
        groupName: 'Nhóm 01',
      ),
      LeaderboardEntry(
        id: 'user_u04',
        userName: 'Trần Bảo Long',
        avatarUrl: '',
        xp: 3100,
        streakDays: 16,
        testsCompleted: 38,
        badges: ['Chiến binh SM-2', 'Chuyên gia IT'],
        groupName: 'Nhóm 01',
      ),
      LeaderboardEntry(
        id: 'user_u05',
        userName: 'Bùi Gia Huy',
        avatarUrl: '',
        xp: 2950,
        streakDays: 15,
        testsCompleted: 36,
        badges: ['Kiến trúc sư Clean Code'],
        groupName: 'Nhóm 01',
      ),
      LeaderboardEntry(
        id: 'user_u06',
        userName: 'Nguyễn Thị Hải Yến',
        avatarUrl: '',
        xp: 2820,
        streakDays: 14,
        testsCompleted: 33,
        badges: ['Người tiên phong'],
        groupName: 'Nhóm 01',
      ),
      LeaderboardEntry(
        id: 'user_u07',
        userName: 'Ngô Thanh Thảo',
        avatarUrl: '',
        xp: 2710,
        streakDays: 13,
        testsCompleted: 31,
        badges: ['Ngôi sao Song ngữ'],
        groupName: 'Nhóm 01',
      ),
      LeaderboardEntry(
        id: 'user_u08',
        userName: 'Đỗ Tuấn Kiệt',
        avatarUrl: '',
        xp: 2580,
        streakDays: 12,
        testsCompleted: 29,
        badges: ['Bậc thầy SM-2'],
        groupName: 'Nhóm 01',
      ),
      LeaderboardEntry(
        id: 'user_u09',
        userName: 'Lê Minh Tuấn',
        avatarUrl: '',
        xp: 2450,
        streakDays: 11,
        testsCompleted: 27,
        badges: ['Tân binh Chăm chỉ'],
        groupName: 'Nhóm 01',
      ),
      LeaderboardEntry(
        id: 'user_u10',
        userName: 'Trịnh Đức Anh',
        avatarUrl: '',
        xp: 2320,
        streakDays: 10,
        testsCompleted: 25,
        badges: ['Chăm chỉ Mỗi ngày'],
        groupName: 'Nhóm 01',
      ),
      // Tài khoản Sinh viên demo trong Nhóm 01
      LeaderboardEntry(
        id: 'user_student_1',
        userName: 'Bùi Ngọc (Sinh viên)',
        avatarUrl: '',
        xp: 2190,
        streakDays: 8,
        testsCompleted: 22,
        badges: ['Tân binh EduMaster', 'Khám phá Từ điển'],
        groupName: 'Nhóm 01',
      ),
      LeaderboardEntry(
        id: 'user_u12',
        userName: 'Hoàng Quốc Bảo',
        avatarUrl: '',
        xp: 2080,
        streakDays: 8,
        testsCompleted: 21,
        badges: ['Khám phá Tri thức'],
        groupName: 'Nhóm 01',
      ),
      LeaderboardEntry(
        id: 'user_u13',
        userName: 'Mai Xuân Bách',
        avatarUrl: '',
        xp: 1970,
        streakDays: 7,
        testsCompleted: 20,
        badges: ['Học viên Tích cực'],
        groupName: 'Nhóm 01',
      ),
      LeaderboardEntry(
        id: 'user_u14',
        userName: 'Đinh Phương Linh',
        avatarUrl: '',
        xp: 1880,
        streakDays: 7,
        testsCompleted: 19,
        badges: ['Ngôi sao Từ vựng'],
        groupName: 'Nhóm 01',
      ),
      LeaderboardEntry(
        id: 'user_u15',
        userName: 'Dương Quang Vinh',
        avatarUrl: '',
        xp: 1790,
        streakDays: 6,
        testsCompleted: 18,
        badges: ['Chiến binh Bứt phá'],
        groupName: 'Nhóm 01',
      ),
      LeaderboardEntry(
        id: 'user_u16',
        userName: 'Lý Hải Đăng',
        avatarUrl: '',
        xp: 1710,
        streakDays: 6,
        testsCompleted: 17,
        badges: ['Chiến binh Bền bỉ'],
        groupName: 'Nhóm 01',
      ),
      LeaderboardEntry(
        id: 'user_u17',
        userName: 'Phan Thu Trang',
        avatarUrl: '',
        xp: 1630,
        streakDays: 5,
        testsCompleted: 16,
        badges: ['Tân binh Xuất sắc'],
        groupName: 'Nhóm 01',
      ),
      LeaderboardEntry(
        id: 'user_u18',
        userName: 'Hà Công Minh',
        avatarUrl: '',
        xp: 1560,
        streakDays: 5,
        testsCompleted: 15,
        badges: ['Người kiên trì'],
        groupName: 'Nhóm 01',
      ),
      LeaderboardEntry(
        id: 'user_u19',
        userName: 'Võ Hoàng Yến',
        avatarUrl: '',
        xp: 1490,
        streakDays: 5,
        testsCompleted: 14,
        badges: ['Chiến binh Học tập'],
        groupName: 'Nhóm 01',
      ),
      LeaderboardEntry(
        id: 'user_u20',
        userName: 'Chu Văn An',
        avatarUrl: '',
        xp: 1420,
        streakDays: 4,
        testsCompleted: 14,
        badges: ['Học viên Tinh nhuệ'],
        groupName: 'Nhóm 01',
      ),
      LeaderboardEntry(
        id: 'user_u21',
        userName: 'Tạ Đình Phong',
        avatarUrl: '',
        xp: 1350,
        streakDays: 4,
        testsCompleted: 13,
        badges: ['Học viên Năng nổ'],
        groupName: 'Nhóm 01',
      ),
      LeaderboardEntry(
        id: 'user_u22',
        userName: 'Đoàn Minh Trí',
        avatarUrl: '',
        xp: 1280,
        streakDays: 4,
        testsCompleted: 12,
        badges: ['Bứt phá Vươn lên'],
        groupName: 'Nhóm 01',
      ),
      LeaderboardEntry(
        id: 'user_u23',
        userName: 'Cao Thị Thanh',
        avatarUrl: '',
        xp: 1210,
        streakDays: 3,
        testsCompleted: 11,
        badges: ['Người đồng hành'],
        groupName: 'Nhóm 01',
      ),
      LeaderboardEntry(
        id: 'user_u24',
        userName: 'Lương Triều Vĩ',
        avatarUrl: '',
        xp: 1150,
        streakDays: 3,
        testsCompleted: 10,
        badges: ['Tân binh Nỗ lực'],
        groupName: 'Nhóm 01',
      ),
      LeaderboardEntry(
        id: 'user_u25',
        userName: 'Tống Khánh Linh',
        avatarUrl: '',
        xp: 1090,
        streakDays: 3,
        testsCompleted: 9,
        badges: ['Hạt giống Tri thức'],
        groupName: 'Nhóm 01',
      ),
      LeaderboardEntry(
        id: 'user_u26',
        userName: 'Hồ Ngọc Hà',
        avatarUrl: '',
        xp: 1020,
        streakDays: 2,
        testsCompleted: 8,
        badges: ['Bước đầu Vững chắc'],
        groupName: 'Nhóm 01',
      ),
      LeaderboardEntry(
        id: 'user_u27',
        userName: 'Đào Trọng Nghĩa',
        avatarUrl: '',
        xp: 960,
        streakDays: 2,
        testsCompleted: 7,
        badges: ['Tân binh'],
        groupName: 'Nhóm 01',
      ),
      LeaderboardEntry(
        id: 'user_u28',
        userName: 'Quách Tuấn Du',
        avatarUrl: '',
        xp: 900,
        streakDays: 2,
        testsCompleted: 6,
        badges: ['Khởi đầu Mới'],
        groupName: 'Nhóm 01',
      ),
      LeaderboardEntry(
        id: 'user_u29',
        userName: 'Nghiêm Xuân Tú',
        avatarUrl: '',
        xp: 840,
        streakDays: 1,
        testsCompleted: 5,
        badges: ['Khám phá EduMaster'],
        groupName: 'Nhóm 01',
      ),
      LeaderboardEntry(
        id: 'user_u30',
        userName: 'Lâm Khánh Chi',
        avatarUrl: '',
        xp: 780,
        streakDays: 1,
        testsCompleted: 4,
        badges: ['Tân binh Nhập môn'],
        groupName: 'Nhóm 01',
      ),
    ];
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

    if (entries.isEmpty) {
      // Demo Teacher & Demo Student get demo group 01, while NEW accounts start clean []
      if (_userId == 'user_teacher_1' || _userId == 'user_student_1' || _userId == 'sv1001' || _userId == 'gv2001' || _userId.contains('student@edumaster.edu.vn') || _userId.contains('teacher@edumaster.edu.vn')) {
        final default30 = _createDefault30Members();
        entries = [...default30];
        entries.sort((a, b) => b.xp.compareTo(a.xp));
        _cachedEntries = entries;
        await prefs.setString(_leaderboardKey, json.encode(entries.map((e) => e.toMap()).toList()));
        _emitRealtime(entries);
        return entries;
      }
      _cachedEntries = [];
      _emitRealtime([]);
      return [];
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
          groupName: groupName ?? 'Nhóm 01',
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

    if (groups.isEmpty) {
      if (_userId == 'user_teacher_1' || _userId == 'user_student_1' || _userId == 'sv1001' || _userId == 'gv2001' || _userId.contains('student@edumaster.edu.vn') || _userId.contains('teacher@edumaster.edu.vn')) {
        groups = ['Nhóm 01'];
        await prefs.setString(_groupsListKey, json.encode(groups));
        return groups;
      }
      // NEW Teacher / Student accounts start with 0 created groups []!
      return [];
    }
    // Lọc bỏ các nhóm cũ nếu còn sót lại
    groups.removeWhere((g) => g.contains('KTHP') || g.contains('Flutter Pro') || g.contains('Lập Trình Di Động'));

    await prefs.setString(_groupsListKey, json.encode(groups));

    // Đảm bảo mọi nhóm có sinh viên trong entries đều được hiển thị cho GV
    final entries = await getEntries();
    for (final e in entries) {
      final g = e.groupName.trim();
      if (g.isNotEmpty && !groups.contains(g)) {
        groups.add(g);
      }
    }
    return groups;
  }

  Future<void> createGroup(String groupName) async {
    final clean = groupName.trim();
    if (clean.isEmpty) return;
    final groups = await getGroups();
    if (!groups.contains(clean)) {
      groups.add(clean);
      final prefs = await _getPrefs();
      await prefs.setString(_groupsListKey, json.encode(groups));
    }
  }

  Future<void> deleteGroup(String groupName) async {
    final clean = groupName.trim();
    final groups = await getGroups();
    groups.remove(clean);
    final prefs = await _getPrefs();
    await prefs.setString(_groupsListKey, json.encode(groups));

    // Chuyển các sinh viên trong nhóm bị xóa về Nhóm 01
    final fallbackGroup = groups.isNotEmpty ? groups.first : 'Nhóm 01';
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

  Future<void> renameGroup(String oldName, String newName) async {
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

  /// Giáo viên chuyển sinh viên sang một nhóm học khác
  Future<void> moveStudentToGroup(String studentId, String newGroupName) async {
    final cleanGroup = newGroupName.trim();
    if (cleanGroup.isEmpty) return;
    await createGroup(cleanGroup);

    final entries = await getEntries();
    final idx = entries.indexWhere((e) => e.id == studentId);
    if (idx >= 0) {
      final old = entries[idx];
      entries[idx] = LeaderboardEntry(
        id: old.id,
        userName: old.userName,
        avatarUrl: old.avatarUrl,
        xp: old.xp,
        streakDays: old.streakDays,
        testsCompleted: old.testsCompleted,
        badges: old.badges,
        groupName: cleanGroup,
      );
      _cachedEntries = entries;
      final prefs = await _getPrefs();
      await prefs.setString(_leaderboardKey, json.encode(entries.map((e) => e.toMap()).toList()));
      _emitRealtime(entries);

      // Nếu là sinh viên demo, đồng bộ luôn vào profile
      if (old.id == 'user_student_1' || old.userName.contains('Bùi Ngọc')) {
        final profile = await getUserProfile(email: 'student@edumaster.edu.vn');
        await saveUserProfile(profile.copyWith(currentGroup: cleanGroup));
      }
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
    final targetEmail = (email ?? _currentActiveEmail ?? prefs.getString('edumaster_current_session_email') ?? '').trim().toLowerCase();

    final key = '$_profileKeyPrefix$targetEmail';
    final jsonStr = prefs.getString(key);

    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final profile = UserProfile.fromMap(json.decode(jsonStr) as Map<String, dynamic>);
        if (targetEmail.isNotEmpty) _profileCache[targetEmail] = profile;
        return profile;
      } catch (_) {}
    }

    // Clean data for registered user: 0 XP, 0 Streak, empty group
    UserProfile profile = UserProfile(
      uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Thành viên mới',
      email: targetEmail,
      totalXp: 0,
      streakDays: 0,
      badges: const [],
      currentGroup: '',
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
