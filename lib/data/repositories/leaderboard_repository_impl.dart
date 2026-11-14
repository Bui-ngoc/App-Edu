import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/repositories/interfaces.dart';
import '../datasources/leaderboard_datasource.dart';

class LeaderboardRepositoryImpl implements ILeaderboardRepository {
  final LeaderboardDataSource _dataSource;

  LeaderboardRepositoryImpl({LeaderboardDataSource? dataSource})
      : _dataSource = dataSource ?? LeaderboardDataSource();

  @override
  Stream<List<LeaderboardEntry>> getRealtimeLeaderboard() {
    return _dataSource.leaderboardStream;
  }

  @override
  Future<void> updateXp(String userId, int addedXp) {
    return _dataSource.updateXp(userId, addedXp);
  }

  @override
  Future<UserProfile> getUserProfile() {
    return _dataSource.getUserProfile();
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) {
    return _dataSource.saveUserProfile(profile);
  }
}
