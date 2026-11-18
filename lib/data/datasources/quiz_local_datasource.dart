import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/quiz_question.dart';
import '../../core/errors/app_exception.dart';

class QuizLocalDataSource {
  static const String _wrongQuestionsKeyPrefix = 'edumaster_wrong_question_ids_u_';
  List<QuizQuestion>? _cachedQuestions;

  String _userId = 'default';
  String get _wrongQuestionsKey => '$_wrongQuestionsKeyPrefix$_userId';

  /// Gọi khi user đăng nhập/đăng xuất để load đúng wrong-questions của user đó.
  void switchUser(String userId) {
    _userId = userId.trim().isEmpty ? 'default' : userId.trim();
  }

  Future<List<QuizQuestion>> loadAllQuestions() async {
    if (_cachedQuestions != null && _cachedQuestions!.isNotEmpty) {
      return _cachedQuestions!;
    }
    try {
      final jsonString = await rootBundle.loadString('assets/data/questions_300.json');
      final dynamic decoded = json.decode(jsonString);
      if (decoded is List) {
        _cachedQuestions = decoded
            .map((item) => QuizQuestion.fromMap(Map<String, dynamic>.from(item as Map)))
            .toList();
        return _cachedQuestions!;
      } else {
        throw CorruptedDataException('Dữ liệu bộ câu hỏi 300 câu không đúng cấu trúc danh sách.');
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw CorruptedDataException('Không thể nạp tệp questions_300.json: ${e.toString()}');
    }
  }

  Future<Set<int>> getWrongQuestionIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_wrongQuestionsKey) ?? [];
    return list.map((e) => int.tryParse(e) ?? 0).where((id) => id > 0).toSet();
  }

  Future<void> saveWrongQuestionId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final set = await getWrongQuestionIds();
    set.add(id);
    await prefs.setStringList(_wrongQuestionsKey, set.map((e) => e.toString()).toList());
  }

  Future<void> removeWrongQuestionId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final set = await getWrongQuestionIds();
    set.remove(id);
    await prefs.setStringList(_wrongQuestionsKey, set.map((e) => e.toString()).toList());
  }
}
