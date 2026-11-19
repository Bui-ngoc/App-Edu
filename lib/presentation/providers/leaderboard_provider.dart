import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/repositories/interfaces.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/leaderboard_datasource.dart';

enum LeaderboardUiState { initial, loading, success, error }

class LeaderboardProvider extends ChangeNotifier {
  final ILeaderboardRepository _repo;
  StreamSubscription<List<LeaderboardEntry>>? _sub;

  LeaderboardProvider({required ILeaderboardRepository repo}) : _repo = repo {
    loadLeaderboard();
    _subscribeRealtime();
  }

  void _subscribeRealtime() {
    _sub?.cancel();
    _sub = _repo.getRealtimeLeaderboard().listen((entries) {
      _entries = List.from(entries)..sort((a, b) => b.xp.compareTo(a.xp));
      _state = LeaderboardUiState.success;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  LeaderboardUiState _state = LeaderboardUiState.initial;
  LeaderboardUiState get state => _state;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  List<LeaderboardEntry> _entries = [];
  List<LeaderboardEntry> get entries => _entries;

  List<String> _groups = [];
  List<String> get availableGroups => _groups;

  String _selectedGroup = 'Nhóm 01';
  String get selectedGroup => _selectedGroup;

  List<LeaderboardEntry> get filteredEntries {
    final list = _entries.where((e) => e.groupName == _selectedGroup).toList();
    list.sort((a, b) => b.xp.compareTo(a.xp));
    return list;
  }

  void selectGroup(String group) {
    final clean = group.trim();
    if (clean.isEmpty || _selectedGroup == clean) return;
    _selectedGroup = clean;
    notifyListeners();
  }

  // ── Thống kê theo nhóm học cho Giáo viên ─────────────────────────────────

  int getGroupStudentCount(String groupName) {
    return _entries.where((e) => e.groupName == groupName).length;
  }

  int getGroupAverageXp(String groupName) {
    final members = _entries.where((e) => e.groupName == groupName).toList();
    if (members.isEmpty) return 0;
    final total = members.fold<int>(0, (sum, e) => sum + e.xp);
    return (total / members.length).round();
  }

  LeaderboardEntry? getGroupTopStudent(String groupName) {
    final members = _entries.where((e) => e.groupName == groupName).toList();
    if (members.isEmpty) return null;
    members.sort((a, b) => b.xp.compareTo(a.xp));
    return members.first;
  }

  // ── Quản lý Nhóm học tập (Dành cho Giáo viên) ───────────────────────────

  Future<void> createGroup(String groupName) async {
    final clean = groupName.trim();
    if (clean.isEmpty) return;
    await _repo.createGroup(clean);
    _selectedGroup = clean;
    await loadLeaderboard(force: true);
  }

  Future<void> deleteGroup(String groupName) async {
    final clean = groupName.trim();
    if (clean.isEmpty) return;
    await _repo.deleteGroup(clean);
    await loadLeaderboard(force: true);
    if (_groups.isNotEmpty) {
      _selectedGroup = _groups.first;
    }
    notifyListeners();
  }

  Future<void> renameGroup(String oldName, String newName) async {
    final cleanOld = oldName.trim();
    final cleanNew = newName.trim();
    if (cleanNew.isEmpty || cleanOld == cleanNew) return;
    await _repo.renameGroup(cleanOld, cleanNew);
    if (_selectedGroup == cleanOld) {
      _selectedGroup = cleanNew;
    }
    await loadLeaderboard(force: true);
  }

  Future<void> moveStudentToGroup(String studentId, String newGroupName) async {
    final clean = newGroupName.trim();
    if (clean.isEmpty) return;
    await _repo.moveStudentToGroup(studentId, clean);
    await loadLeaderboard(force: true);
  }

  Future<void> addStudentToGroup({
    required String name,
    required String groupName,
    int initialXp = 0,
  }) async {
    final cleanName = name.trim();
    final cleanGroup = groupName.trim();
    if (cleanName.isEmpty || cleanGroup.isEmpty) return;
    await _repo.addStudentToGroup(name: cleanName, groupName: cleanGroup, initialXp: initialXp);
    await loadLeaderboard(force: true);
  }

  Future<({bool success, String message, String studentName})> addStudentToGroupById({
    required String studentId,
    required String targetGroup,
  }) async {
    final cleanId = studentId.trim();
    if (cleanId.isEmpty) {
      return (success: false, message: 'Vui lòng nhập mã ID sinh viên.', studentName: '');
    }

    final authDataSource = AuthLocalDataSource(leaderboardDataSource: _repo as LeaderboardDataSource);
    final user = await authDataSource.getUserById(cleanId);

    if (user == null || user.isTeacher) {
      return (
        success: false,
        message: 'Không tìm thấy tài khoản Sinh viên với mã ID "$cleanId". Vui lòng kiểm tra lại!',
        studentName: ''
      );
    }

    // 1. Update user group in auth local datasource
    await authDataSource.updateUserGroup(user.id, targetGroup);

    // 2. Explicitly save student UserProfile with currentGroup = targetGroup
    final leaderboardDs = _repo as LeaderboardDataSource;
    final studentProfile = await leaderboardDs.getUserProfile(email: user.email);
    final updatedProfile = studentProfile.copyWith(
      name: user.name,
      email: user.email,
      currentGroup: targetGroup,
    );
    await leaderboardDs.saveUserProfile(updatedProfile);

    // 3. Move student in leaderboard entries
    await moveStudentToGroup(user.id, targetGroup);
    await loadLeaderboard(force: true);

    return (
      success: true,
      message: 'Đã thêm sinh viên ${user.name} (Mã ID: ${user.id}) vào "$targetGroup"',
      studentName: user.name,
    );
  }

  int getRank(LeaderboardEntry entry) {
    final list = filteredEntries;
    final idx = list.indexWhere((e) => e.id == entry.id);
    return idx >= 0 ? idx + 1 : 0;
  }

  LeaderboardEntry? findUserEntry(String userId) {
    try {
      return _entries.firstWhere((e) => e.id == userId || e.id == 'user_current');
    } catch (_) {
      return null;
    }
  }

  Future<void> syncUser({
    required String userId,
    String? name,
    String? groupName,
    int? xp,
  }) async {
    await _repo.updateUserLeaderboard(
      userId: userId,
      userName: name,
      groupName: groupName,
      xp: xp,
    );
    await loadLeaderboard(force: true);
  }

  Future<void> loadLeaderboard({bool force = false}) async {
    if (!force && _entries.isNotEmpty && _state == LeaderboardUiState.success) return;
    _state = LeaderboardUiState.loading;
    notifyListeners();

    try {
      _groups = await _repo.getGroups();
      _entries = await _repo.getRealtimeLeaderboard().first;
      _entries.sort((a, b) => b.xp.compareTo(a.xp));

      if (_groups.isNotEmpty && !_groups.contains(_selectedGroup)) {
        _selectedGroup = _groups.first;
      }
      _state = LeaderboardUiState.success;
    } catch (e) {
      _state = LeaderboardUiState.error;
      _errorMessage = 'Lỗi nạp dữ liệu: ${e.toString()}';
    }
    notifyListeners();
  }
}
