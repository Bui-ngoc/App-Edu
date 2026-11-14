import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/repositories/interfaces.dart';

enum LeaderboardUiState { loading, success, error }

class LeaderboardProvider extends ChangeNotifier {
  final ILeaderboardRepository _repo;
  StreamSubscription<List<LeaderboardEntry>>? _sub;

  LeaderboardProvider({required ILeaderboardRepository repo}) : _repo = repo {
    _subscribeLeaderboard();
  }

  LeaderboardUiState _state = LeaderboardUiState.loading;
  LeaderboardUiState get state => _state;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  List<LeaderboardEntry> _entries = [];
  List<LeaderboardEntry> get entries => _entries;

  void _subscribeLeaderboard() {
    _state = LeaderboardUiState.loading;
    notifyListeners();

    _sub = _repo.getRealtimeLeaderboard().listen(
      (data) {
        _entries = data;
        _state = LeaderboardUiState.success;
        notifyListeners();
      },
      onError: (e) {
        _state = LeaderboardUiState.error;
        _errorMessage = 'Lỗi cập nhật bảng xếp hạng: ${e.toString()}';
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
