
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/quiz_question.dart';
import 'local_ai_engine.dart';

class GeminiAiDataSource {
  static const String _demoModePref = 'edumaster_demo_mode';

  // Model Gemini được hỗ trợ qua Firebase AI Logic.
  static const String _modelName = 'gemini-3.8-flash';

  // Firebase AI Logic tự xử lý kết nối và xác thực.
  final GenerativeModel _model;

  GeminiAiDataSource()
      : _model = FirebaseAI.googleAI().generativeModel(
    model: _modelName,
  );

  // ============================================================
  // DEMO MODE
  // ============================================================

  Future<bool> isDemoMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_demoModePref) ?? false;
  }

  Future<void> setDemoMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_demoModePref, value);
  }

  // ============================================================
  // LEGACY API KEY METHODS
  // Giữ tạm để tương thích với ProfileProvider cũ.
  // Firebase AI Logic không sử dụng API key do người dùng nhập.
  // ============================================================

  @Deprecated('Firebase AI Logic không cần API key thủ công.')
  Future<String> getApiKey() async {
    return '';
  }

  @Deprecated('Firebase AI Logic không cần lưu API key.')
  Future<void> saveApiKey(String key) async {
    // Không lưu API key nữa.
  }

  @Deprecated('Firebase AI Logic không cần xóa API key.')
  Future<void> clearSavedApiKey() async {
    // Không còn API key được lưu bởi datasource này.
  }

  // ============================================================
  // MAIN AI ENTRY POINT
  // ============================================================

  Future<String> askAi(String prompt) async {
    final cleanPrompt = prompt.trim();

    if (cleanPrompt.isEmpty) {
      throw Exception('Vui lòng nhập nội dung câu hỏi.');
    }

    // Chế độ Demo: sử dụng AI xử lý nội bộ.
    if (await isDemoMode()) {
      return LocalAiEngine.processQuery(cleanPrompt);
    }

    return _callFirebaseAI(cleanPrompt);
  }

  // ============================================================
  // FIREBASE AI LOGIC
  // ============================================================



  Future<String> _callFirebaseAI(String userPrompt) async {
    final fullPrompt = '''
Bạn là EduMaster AI Tutor, trợ lý học tập thông minh của ứng dụng EduMaster.

Nhiệm vụ:
- Giải thích kiến thức chính xác, dễ hiểu.
- Ưu tiên trả lời bằng tiếng Việt.
- Trình bày rõ ràng, có ví dụ khi cần thiết.
- Nếu câu hỏi liên quan đến lập trình, hãy giải thích từng bước.
- Nếu chưa đủ thông tin, hãy hỏi lại thay vì tự suy đoán.
- Trả lời đúng trọng tâm.

Câu hỏi của người học:
$userPrompt
''';

    final stopwatch = Stopwatch()..start();

    debugPrint('[AI Tutor] Bắt đầu gọi Firebase AI Logic');
    debugPrint('[AI Tutor] Model: $_modelName');

    try {
      final response = await _model
          .generateContent([Content.text(fullPrompt)])
          .timeout(const Duration(seconds: 60));

      stopwatch.stop();

      final answer = response.text;

      debugPrint(
        '[AI Tutor] Nhận phản hồi sau ${stopwatch.elapsedMilliseconds} ms',
      );

      if (answer == null || answer.trim().isEmpty) {
        throw Exception('Gemini không trả về nội dung.');
      }

      debugPrint('[AI Tutor] Trả lời thành công');

      return answer;
    } on TimeoutException catch (e, stackTrace) {
      debugPrint(
        '[AI Tutor] TIMEOUT sau ${stopwatch.elapsedMilliseconds} ms',
      );
      debugPrint('[AI Tutor] Chi tiết: $e');
      debugPrint('$stackTrace');

      rethrow;
    } catch (e, stackTrace) {
      debugPrint('[AI Tutor] LỖI: $e');
      debugPrint('$stackTrace');

      rethrow;
    }
  }

  // ============================================================
  // EXPLAIN WRONG ANSWER
  // ============================================================

  Future<String> explainWrongAnswer({
    required QuizQuestion question,
    required int selectedIndex,
    required bool isEnglish,
  }) async {
    final selectedOpt = isEnglish
        ? (selectedIndex >= 0 &&
        selectedIndex < question.optionsEn.length
        ? question.optionsEn[selectedIndex]
        : '')
        : (selectedIndex >= 0 &&
        selectedIndex < question.optionsVi.length
        ? question.optionsVi[selectedIndex]
        : '');

    final correctOpt = isEnglish
        ? (question.correctIndex >= 0 &&
        question.correctIndex < question.optionsEn.length
        ? question.optionsEn[question.correctIndex]
        : '')
        : (question.correctIndex >= 0 &&
        question.correctIndex < question.optionsVi.length
        ? question.optionsVi[question.correctIndex]
        : '');

    final prompt = isEnglish
        ? '''
Question: "${question.questionEn}"

The student's selected answer: "$selectedOpt" (incorrect).

Correct answer: "$correctOpt".

Reference explanation:
${question.explanationEn}

Please:
1. Explain why the selected answer is incorrect.
2. Explain why the correct answer is right.
3. Give a simple example if helpful.
Keep the explanation concise and easy to understand.
'''
        : '''
Câu hỏi: "${question.questionVi}"

Học viên đã chọn: "$selectedOpt" (sai).

Đáp án đúng: "$correctOpt".

Giải thích tham khảo:
${question.explanationVi}

Hãy:
1. Giải thích tại sao đáp án học viên chọn là sai.
2. Giải thích tại sao đáp án đúng là chính xác.
3. Đưa ra ví dụ đơn giản nếu cần.
Trình bày ngắn gọn, dễ hiểu và phù hợp với sinh viên.
''';

    try {
      return await askAi(prompt);
    } catch (e) {
      // Nếu AI không kết nối được, vẫn hiển thị lời giải có sẵn.
      return isEnglish
          ? 'Correct answer: **$correctOpt**\n'
          '${question.explanationEn}'
          : 'Đáp án đúng: **$correctOpt**\n'
          '${question.explanationVi}';
    }
  }

  // Không còn HTTP Client cần đóng.
  void dispose() {}
}
