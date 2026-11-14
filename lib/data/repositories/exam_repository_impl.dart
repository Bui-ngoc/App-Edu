import '../../domain/entities/exam.dart';
import '../../domain/repositories/interfaces.dart';
import '../datasources/exam_storage_datasource.dart';

class ExamRepositoryImpl implements IExamRepository {
  final ExamStorageDataSource _dataSource;

  ExamRepositoryImpl({ExamStorageDataSource? dataSource})
      : _dataSource = dataSource ?? ExamStorageDataSource();

  @override
  Future<List<ExamRoom>> getAvailableRooms() {
    return _dataSource.getRooms();
  }

  @override
  Future<ExamRoom?> getRoomById(String roomId) {
    return _dataSource.getRoomById(roomId);
  }

  @override
  Future<void> createRoom(ExamRoom room) {
    return _dataSource.saveRoom(room);
  }

  @override
  Future<void> submitResult(ExamSessionResult result) {
    return _dataSource.submitResult(result);
  }

  @override
  Future<List<ExamSessionResult>> getResultsForRoom(String roomId) {
    return _dataSource.getResultsForRoom(roomId);
  }
}
