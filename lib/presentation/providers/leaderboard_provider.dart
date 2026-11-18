import 'package:flutter/foundation.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/repositories/interfaces.dart';

enum LeaderboardUiState { initial, loading, success, error }

class LeaderboardProvider extends ChangeNotifier {
  final ILeaderboardRepository _repo;

  LeaderboardProvider({required ILeaderboardRepository repo}) : _repo = repo {
    loadLeaderboard();
  }

  LeaderboardUiState _state = LeaderboardUiState.initial;
  LeaderboardUiState get state => _state;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  List<LeaderboardEntry> _entries = [];
  List<LeaderboardEntry> get entries => _entries;

  String _selectedGroup = 'Tất cả';
  String get selectedGroup => _selectedGroup;

  List<String> get availableGroups {
    final groups = <String>{};
    for (final e in _entries) {
      if (e.groupName.trim().isNotEmpty) {
        groups.add(e.groupName.trim());
      }
    }
    return groups.toList()..sort();
  }

  List<LeaderboardEntry> get filteredEntries {
    if (_selectedGroup == 'Tất cả') {
      return List.unmodifiable(_entries);
    }
    return _entries.where((e) => e.groupName == _selectedGroup).toList();
  }

  void selectGroup(String group) {
    if (_selectedGroup == group) return;
    _selectedGroup = group;
    notifyListeners();
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
      _entries = await _repo.getRealtimeLeaderboard().first;
      _entries.sort((a, b) => b.xp.compareTo(a.xp));
      _state = LeaderboardUiState.success;
    } catch (e) {
      _state = LeaderboardUiState.error;
      _errorMessage = 'Lỗi nạp dữ liệu: ${e.toString()}';
    }
    notifyListeners();
  }
}
