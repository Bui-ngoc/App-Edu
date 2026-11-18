import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/repositories/interfaces.dart';

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

  String _selectedGroup = 'Nhóm 01 - KTHP';
  String get selectedGroup => _selectedGroup;

  /// CHỈ SO SÁNH GIỮA CÁC SINH VIÊN CÙNG NHÓM HỌC
  /// Tuyệt đối không so sánh toàn trường.
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
