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
  Future<UserProfile> getUserProfile({String? email}) {
    return _dataSource.getUserProfile(email: email);
  }

  @override
  Future<({UserProfile profile, bool isNewStreak})> checkAndRecordDailyStreak({String? email}) {
    return _dataSource.checkAndRecordDailyStreak(email: email);
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) {
    return _dataSource.saveUserProfile(profile);
  }

  @override
  Future<void> updateUserLeaderboard({
    required String userId,
    String? userName,
    String? groupName,
    int? xp,
  }) {
    return _dataSource.updateUserLeaderboard(
      userId: userId,
      userName: userName,
      groupName: groupName,
      xp: xp,
    );
  }

  @override
  Future<List<String>> getGroups() {
    return _dataSource.getGroups();
  }

  @override
  Future<void> createGroup(String groupName) {
    return _dataSource.createGroup(groupName);
  }

  @override
  Future<void> deleteGroup(String groupName) {
    return _dataSource.deleteGroup(groupName);
  }

  @override
  Future<void> renameGroup(String oldName, String newName) {
    return _dataSource.renameGroup(oldName, newName);
  }

  @override
  Future<void> moveStudentToGroup(String studentId, String newGroupName) {
    return _dataSource.moveStudentToGroup(studentId, newGroupName);
  }

  @override
  Future<void> addStudentToGroup({
    required String name,
    required String groupName,
    int initialXp = 0,
  }) {
    return _dataSource.addStudentToGroup(
      name: name,
      groupName: groupName,
      initialXp: initialXp,
    );
  }
}
