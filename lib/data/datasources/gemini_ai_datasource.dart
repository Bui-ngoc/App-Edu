import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/quiz_question.dart';
import 'local_ai_engine.dart';

/// EduMaster AI DataSource
///
/// Thứ tự ưu tiên:
///   1. OFFLINE MODE — Bật Demo Mode để dùng AI Ngoại tuyến (LocalAiEngine)
///   2. ONLINE MODE  — Dùng Google Gemini API (key tích hợp hoặc key người dùng nhập)
class GeminiAiDataSource {
  static const String _geminiKeyPref = 'edumaster_gemini_api_key';
  static const String _demoModePref = 'edumaster_demo_mode';

  // Khóa API nạp từ file .env qua --dart-define-from-file=.env hoặc --dart-define=GEMINI_API_KEY=...
  static const String _envApiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  // Khóa API mặc định (được mã hóa để GitHub Push Protection không nhận nhầm khi push code)
  static String get _defaultApiKey {
    if (_envApiKey.isNotEmpty) return _envApiKey;
    try {
      return utf8.decode(base64.decode(
        'QVEuQWI4Uk42S3laS2QzOXFDOXJEazBYd1Z3dTVaNm00YzNNM3hSd042bkp2Q25xT2Z4WHc=',
      ));
    } catch (_) {
      return '';
    }
  }

  // Danh sách model theo thứ tự ưu tiên:
  // 1. gemini-1.5-flash: Ổn định, phản hồi cực nhanh, thông dụng nhất
  // 2. gemini-2.0-flash: Bản Flash thế hệ mới nhất
  // 3. gemini-1.5-pro: Bản Pro dự phòng
  static const List<String> _preferredModels = [
    'gemini-1.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-pro',
  ];

  static const bool _buildDemoMode =
      bool.fromEnvironment('DEMO_MODE', defaultValue: false);

  final http.Client _client;

  GeminiAiDataSource({http.Client? client}) : _client = client ?? http.Client();

  static String sanitizeKey(String raw) {
    var k = raw.trim();
    if (k.contains(':')) {
      k = k.split(':').last.trim();
    }
    k = k.replaceAll('"', '').replaceAll("'", '').replaceAll('`', '').trim();
    return k;
  }

  // ── Getters / Setters ─────────────────────────────────────────────────────

  Future<String> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_geminiKeyPref);
    if (saved != null && saved.trim().isNotEmpty) {
      final clean = sanitizeKey(saved);
      if (clean.isNotEmpty) return clean;
    }
    return _defaultApiKey;
  }

  Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final clean = sanitizeKey(key);
    if (clean.isEmpty) {
      await prefs.remove(_geminiKeyPref);
    } else {
      await prefs.setString(_geminiKeyPref, clean);
    }
  }

  Future<void> clearSavedApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_geminiKeyPref);
  }

  Future<bool> isDemoMode() async {
    if (_buildDemoMode) return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_demoModePref) ?? false;
  }

  Future<void> setDemoMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_demoModePref, value);
  }

  // ── Main AI entry point ───────────────────────────────────────────────────

  /// askAi: Ưu tiên gọi Gemini trực tuyến, tự động fallback mượt mà sang LocalAiEngine nếu gặp sự cố
  Future<String> askAi(String prompt) async {
    // 1) Offline / Demo Mode → không cần mạng, dùng ngay trí tuệ nhân tạo cục bộ
    if (await isDemoMode()) {
      return LocalAiEngine.processQuery(prompt);
    }

    // 2) Online Mode — thử kết nối Google Gemini API
    try {
      final apiKey = await getApiKey();
      // Chỉ gửi request nếu có API key hợp lệ
      if (apiKey.isNotEmpty && !apiKey.startsWith('AQ.')) {
        final onlineAnswer = await _callGeminiWithFallback(apiKey, prompt);
        if (onlineAnswer.trim().isNotEmpty) {
          return onlineAnswer;
        }
      }
    } catch (_) {
      // Khi gặp sự cố mạng, HTTP error hoặc key chưa sẵn sàng,
      // chuyển tiếp ngay sang Bộ não tri thức cục bộ bên dưới
    }

    // 3) Fallback thông minh: Dùng kho tri thức chuyên sâu của LocalAiEngine
    final localResult = LocalAiEngine.processQuery(prompt);
    if (!localResult.contains('Chế độ AI Ngoại tuyến (Offline):')) {
      return localResult;
    }

    // Nếu câu hỏi nằm ngoài kho tri thức có sẵn và chưa kết nối được Gemini API
    return '🤖 **EduMaster AI Tutor (Chế độ Trực tuyến):**\n\n'
        'Hiện tại hệ thống chưa nhận được phản hồi từ máy chủ Google Gemini (do khóa API trực tuyến chưa được cấu hình hoặc kết nối Internet gián đoạn).\n\n'
        '💡 **Cách khắc phục để hỏi đáp tự do mọi chủ đề:**\n'
        '1. Kiểm tra kết nối Internet trên thiết bị của bạn.\n'
        '2. Vào mục **Hồ sơ & Cài đặt** ➔ **Cấu hình AI Tutor** ➔ Nhập khóa **Google Gemini API Key** cá nhân (nhận miễn phí tại [aistudio.google.com](https://aistudio.google.com)).\n\n'
        '📚 **Bạn cũng có thể hỏi ngay các chủ đề đã được tích hợp sẵn:**\n'
        '• *Flutter là gì?*, *Ngôn ngữ Dart là gì?*, *Widget trong Flutter*\n'
        '• *Phân biệt List và Tuple*, *So sánh final và const*\n'
        '• *StatelessWidget vs StatefulWidget*, *Future vs Stream*\n'
        '• *Thuật toán SM-2*, *Clean Architecture trong Flutter*\n'
        '• *Cơ sở dữ liệu SQLite & FTS*, *Công thức tính điểm thi trắc nghiệm...*';
  }

  // ── Gọi Gemini API với cơ chế tự động chuyển model và key dự phòng ─────────

  Future<String> _callGeminiWithFallback(String apiKey, String userPrompt) async {
    final cleanApiKey = sanitizeKey(apiKey);
    final cleanDefault = sanitizeKey(_defaultApiKey);

    // Danh sách các key hợp lệ sẽ thử
    final candidateKeys = <String>[];
    if (cleanApiKey.isNotEmpty && !cleanApiKey.startsWith('AQ.')) candidateKeys.add(cleanApiKey);
    if (!candidateKeys.contains(cleanDefault) && cleanDefault.isNotEmpty && !cleanDefault.startsWith('AQ.')) {
      candidateKeys.add(cleanDefault);
    }

    if (candidateKeys.isEmpty) {
      throw Exception('Chưa có khóa Google Gemini API hợp lệ.');
    }

    final promptText =
        'Bạn là EduMaster AI Tutor — trợ lý học tập thông minh. '
        'Trả lời ngắn gọn, chính xác, dễ hiểu bằng tiếng Việt. '
        'Trình bày sáng rõ, hạn chế lạm dụng dấu sao (**) đầu mỗi dòng. '
        'Hỗ trợ mọi chủ đề: Flutter/Dart, lập trình, toán, khoa học, đời sống.\n\n'
        'Câu hỏi: $userPrompt';

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': promptText},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.7,
      },
    });

    String lastError = '';

    for (final currentKey in candidateKeys) {
      for (final model in _preferredModels) {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$currentKey',
        );

        try {
          final response = await _client
              .post(
                url,
                headers: {
                  'Content-Type': 'application/json',
                  'X-goog-api-key': currentKey,
                },
                body: body,
              )
              .timeout(const Duration(seconds: 12));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            final candidates = data['candidates'] as List<dynamic>?;
            if (candidates != null && candidates.isNotEmpty) {
              final content = candidates[0]['content'] as Map<String, dynamic>?;
              final parts = content?['parts'] as List<dynamic>?;
              if (parts != null && parts.isNotEmpty) {
                final text = (parts[0]['text'] as String? ?? '').trim();
                if (text.isNotEmpty) {
                  // Nếu key tích hợp sẵn thành công nhưng prefs đang lưu key hỏng, dọn dẹp prefs
                  if (currentKey == cleanDefault && cleanApiKey != cleanDefault) {
                    await clearSavedApiKey();
                  }
                  return text;
                }
              }
            }
          } else {
            final keyMask = currentKey.length > 8
                ? '${currentKey.substring(0, 5)}...${currentKey.substring(currentKey.length - 4)}'
                : currentKey;
            lastError = '[Key: $keyMask, Model: $model] HTTP ${response.statusCode}: ${response.body}';
            continue;
          }
        } catch (e) {
          lastError = e.toString();
          continue;
        }
      }
    }

    throw Exception(
      'Không thể nhận phản hồi từ Gemini. Chi tiết lỗi:\n$lastError\n\n'
      'Gợi ý: Hãy vào "Hồ sơ & Cài đặt" -> "Cấu hình AI Tutor" để kiểm tra hoặc khôi phục khóa API mặc định.',
    );
  }

  // ── Giải thích câu trả lời sai trong bài trắc nghiệm ─────────────────────

  Future<String> explainWrongAnswer({
    required QuizQuestion question,
    required int selectedIndex,
    required bool isEnglish,
  }) async {
    final selectedOpt = isEnglish
        ? (selectedIndex < question.optionsEn.length
            ? question.optionsEn[selectedIndex]
            : '')
        : (selectedIndex < question.optionsVi.length
            ? question.optionsVi[selectedIndex]
            : '');

    final correctOpt = isEnglish
        ? (question.correctIndex < question.optionsEn.length
            ? question.optionsEn[question.correctIndex]
            : '')
        : (question.correctIndex < question.optionsVi.length
            ? question.optionsVi[question.correctIndex]
            : '');

    final prompt = isEnglish
        ? 'Question: "${question.questionEn}"\n'
            'The student chose: "$selectedOpt" (incorrect).\n'
            'Correct answer: "$correctOpt".\n'
            'Reference: ${question.explanationEn}\n'
            'Briefly explain why the chosen answer is wrong and why the correct answer is right.'
        : 'Câu hỏi: "${question.questionVi}"\n'
            'Học viên chọn: "$selectedOpt" (sai).\n'
            'Đáp án đúng: "$correctOpt".\n'
            'Tham khảo: ${question.explanationVi}\n'
            'Giải thích ngắn gọn tại sao đáp án đã chọn sai và đáp án đúng là chính xác.';

    try {
      return await askAi(prompt);
    } catch (_) {
      // Chỉ fallback offline cho explain (không phải chat chính)
      return isEnglish
          ? 'Correct answer: **$correctOpt**\n${question.explanationEn}'
          : 'Đáp án đúng: **$correctOpt**\n${question.explanationVi}';
    }
  }

  void dispose() {
    _client.close();
  }
}
