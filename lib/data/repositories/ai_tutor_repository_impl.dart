import '../../domain/entities/quiz_question.dart';
import '../../domain/repositories/interfaces.dart';
import '../datasources/gemini_ai_datasource.dart';

class AiTutorRepositoryImpl implements IAiTutorRepository {
  final GeminiAiDataSource _dataSource;

  AiTutorRepositoryImpl({GeminiAiDataSource? dataSource})
      : _dataSource = dataSource ?? GeminiAiDataSource();

  @override
  Future<String> askAi(String prompt) {
    return _dataSource.askAi(prompt);
  }

  @override
  Future<String> explainWrongAnswer({
    required QuizQuestion question,
    required int selectedIndex,
    required bool isEnglish,
  }) {
    return _dataSource.explainWrongAnswer(
      question: question,
      selectedIndex: selectedIndex,
      isEnglish: isEnglish,
    );
  }
}
