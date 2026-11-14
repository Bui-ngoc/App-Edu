import '../../domain/entities/quiz_question.dart';
import '../../domain/repositories/interfaces.dart';
import '../datasources/quiz_local_datasource.dart';

class QuizRepositoryImpl implements IQuizRepository {
  final QuizLocalDataSource _dataSource;

  QuizRepositoryImpl({QuizLocalDataSource? dataSource})
      : _dataSource = dataSource ?? QuizLocalDataSource();

  @override
  Future<List<QuizQuestion>> getAllQuestions() {
    return _dataSource.loadAllQuestions();
  }

  @override
  Future<List<QuizQuestion>> getQuestionsByGrade(int grade) async {
    final all = await getAllQuestions();
    return all.where((q) => q.grade == grade).toList();
  }

  @override
  Future<List<QuizQuestion>> getWrongQuestions() async {
    final all = await getAllQuestions();
    final wrongIds = await _dataSource.getWrongQuestionIds();
    return all.where((q) => wrongIds.contains(q.id)).toList();
  }

  @override
  Future<void> saveWrongQuestionId(int id) {
    return _dataSource.saveWrongQuestionId(id);
  }

  @override
  Future<void> removeWrongQuestionId(int id) {
    return _dataSource.removeWrongQuestionId(id);
  }
}
