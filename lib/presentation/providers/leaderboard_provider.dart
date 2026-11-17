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

  Future<void> loadLeaderboard({bool force = false}) async {
    if (!force && _entries.isNotEmpty && _state == LeaderboardUiState.success) return;
    _state = LeaderboardUiState.loading;
    notifyListeners();

    try {
      _entries = await _repo.getRealtimeLeaderboard().first;
      _state = LeaderboardUiState.success;
    } catch (e) {
      _state = LeaderboardUiState.error;
      _errorMessage = 'Lỗi nạp dữ liệu: ${e.toString()}';
    }
    notifyListeners();
  }
}
