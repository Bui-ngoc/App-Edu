import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/quiz_question.dart';
import '../../core/errors/app_exception.dart';

class GeminiAiDataSource {
  static const String _geminiKeyPref = 'edumaster_gemini_api_key';
  final http.Client _client;

  GeminiAiDataSource({http.Client? client}) : _client = client ?? http.Client();

  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_geminiKeyPref);
  }

  Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiKeyPref, key.trim());
  }

  /// Ask AI Tutor with strict timeout & graceful offline/intelligent fallback
  Future<String> askAi(String prompt) async {
    final apiKey = await getApiKey();

    if (apiKey == null || apiKey.isEmpty) {
      return _getSmartLocalTutorResponse(prompt);
    }

    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
      );

      final response = await _client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'contents': [
                {
                  'parts': [
                    {
                      'text':
                          'Bạn là một gia sư AI thân thiện (EduMaster AI Tutor) dạy học sinh các môn Tin học, Toán học, Tiếng Anh. Hãy trả lời súc tích, dễ hiểu, định dạng gạch đầu dòng rõ ràng: $prompt'
                    }
                  ]
                }
              ]
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final candidates = data['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List<dynamic>?;
          if (parts != null && parts.isNotEmpty) {
            return parts[0]['text'].toString().trim();
          }
        }
      }
      return _getSmartLocalTutorResponse(prompt);
    } on TimeoutException {
      throw NetworkTimeoutException('Kết nối đến máy chủ AI quá thời gian chờ (10s). Đang hiển thị phản hồi từ bộ đệm.');
    } catch (_) {
      return _getSmartLocalTutorResponse(prompt);
    }
  }

  /// AI Explains why an answer was wrong in bilingual quiz
  Future<String> explainWrongAnswer({
    required QuizQuestion question,
    required int selectedIndex,
    required bool isEnglish,
  }) async {
    final selectedOpt = isEnglish
        ? (selectedIndex < question.optionsEn.length ? question.optionsEn[selectedIndex] : '')
        : (selectedIndex < question.optionsVi.length ? question.optionsVi[selectedIndex] : '');
    final correctOpt = isEnglish
        ? (question.correctIndex < question.optionsEn.length ? question.optionsEn[question.correctIndex] : '')
        : (question.correctIndex < question.optionsVi.length ? question.optionsVi[question.correctIndex] : '');

    final prompt = isEnglish
        ? 'Explain briefly why for the question "${question.questionEn}", the chosen answer "$selectedOpt" is incorrect, and the correct answer is "$correctOpt". Reference: ${question.explanationEn}'
        : 'Hãy giải thích ngắn gọn tại sao câu hỏi "${question.questionVi}", chọn đáp án "$selectedOpt" là chưa chính xác, và đáp án đúng phải là "$correctOpt". Tham khảo lời giải: ${question.explanationVi}';

    try {
      final res = await askAi(prompt);
      return res;
    } catch (_) {
      return isEnglish
          ? '💡 Explanation:\n- Correct answer: $correctOpt\n- Why: ${question.explanationEn}\n- Tip: Double check definitions before choosing!'
          : '💡 Giải thích chi tiết từ Trợ lý AI:\n- Đáp án chính xác là: $correctOpt\n- Lý do: ${question.explanationVi}\n- Lưu ý: Hãy đọc kỹ từ khóa phân biệt giữa các lựa chọn để tránh nhầm lẫn.';
    }
  }

  String _getSmartLocalTutorResponse(String prompt) {
    final pLower = prompt.toLowerCase();
    if (pLower.contains('sm-2') || pLower.contains('flashcard') || pLower.contains('lặp lại')) {
      return '🧠 **Thuật toán SuperMemo SM-2:**\n- Dựa trên 2 biến số chính: **Ease Factor (EF >= 1.3)** và **Khoảng ôn tập (Interval tính bằng ngày)**.\n- Đánh giá chất lượng nhớ từ 0 - 5. Nếu điểm < 3, thẻ bị coi là quên và reset về ngày thứ 1.\n- Điểm >= 3 sẽ nhân giãn cách theo hệ số EF.';
    }
    if (pLower.contains('mvc') || pLower.contains('kiến trúc')) {
      return '🏛️ **Kiến trúc MVC (Model - View - Controller):**\n- **Model:** Quản lý dữ liệu, logic nghiệp vụ, giao tiếp cơ sở dữ liệu.\n- **View:** Giao diện hiển thị cho người dùng (Widgets trong Flutter).\n- **Controller / Provider:** Điều phối dữ liệu giữa Model và View.';
    }
    if (pLower.contains('sqlite') || pLower.contains('cơ sở dữ liệu') || pLower.contains('fts')) {
      return '💾 **Cơ sở dữ liệu SQLite & FTS:**\n- SQLite là CSDL quan hệ nhúng cục bộ, không cần cài đặt server riêng.\n- **FTS (Full-Text Search):** Bảng ảo hỗ trợ tìm kiếm toàn văn siêu tốc O(log N) thay vì quét toàn bộ bảng LIKE %query%.';
    }
    return '🤖 **Trợ lý EduMaster AI Tutor:**\n- Bạn đang học tập rất tốt! Để ghi nhớ lâu hơn, hãy kết hợp làm trắc nghiệm song ngữ và ôn tập thẻ ghi nhớ SM-2 mỗi ngày.\n- *Gợi ý:* Hãy đặt câu hỏi cụ thể về thuật ngữ CNTT, toán học hoặc ngữ pháp tiếng Anh để mình giải đáp nhé!';
  }

  void dispose() {
    _client.close();
  }
}
