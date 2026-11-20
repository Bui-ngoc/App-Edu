import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/quiz_question.dart';
import 'local_ai_engine.dart';

/// EduMaster AI DataSource
///
/// Thứ tự ưu tiên phản hồi:
///   1. OFFLINE / DEMO MODE: Người dùng chủ động bật chế độ Ngoại tuyến -> dùng ngay LocalAiEngine
///   2. ONLINE MODE: Thử gọi Google Gemini API (gemini-1.5-flash / gemini-2.0-flash)
///   3. THÔNG MINH TỰ ĐỘNG FALLBACK: Nếu không có API key, mạng gián đoạn, timeout hoặc lỗi từ máy chủ
///      -> Luôn luôn phản hồi mượt mà qua Bộ não AI LocalAiEngine mà KHÔNG BAO GIỜ báo lỗi hay từ chối!
class GeminiAiDataSource {
  static const String _geminiKeyPref = 'edumaster_gemini_api_key';
  static const String _demoModePref = 'edumaster_demo_mode';

  // Khóa API nạp từ môi trường nếu có (--dart-define=GEMINI_API_KEY=...)
  static const String _envApiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  // Khóa API mặc định
  static String get _defaultApiKey {
    if (_envApiKey.isNotEmpty) return _envApiKey;
    return '';
  }

  // Danh sách model Google Gemini theo thứ tự ưu tiên
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

  /// askAi: Phản hồi thông minh cho MỌI câu hỏi học viên.
  /// Luôn hoạt động ổn định và tức thì ngay cả khi không nhập bất kỳ khóa API nào!
  Future<String> askAi(String prompt) async {
    final cleanPrompt = prompt.trim();
    if (cleanPrompt.isEmpty) {
      return '👋 Xin chào bạn! Mình là Trợ lý AI Tutor của EduMaster. Bạn hãy nhập câu hỏi để mình giải đáp nhé!';
    }

    // 1) Nếu người dùng chủ động chọn chế độ Ngoại tuyến (Demo / Offline)
    if (await isDemoMode()) {
      return LocalAiEngine.processQuery(cleanPrompt);
    }

    // 2) Chế độ Trực tuyến — Thử kết nối Google Gemini API nếu có API key hợp lệ
    try {
      final apiKey = await getApiKey();
      if (apiKey.isNotEmpty && !apiKey.startsWith('AQ.')) {
        final onlineAnswer = await _callGeminiWithFallback(apiKey, cleanPrompt);
        if (onlineAnswer.trim().isNotEmpty) {
          return onlineAnswer;
        }
      }
    } catch (_) {
      // Khi gặp sự cố mạng, HTTP error, timeout hoặc key cá nhân chưa kích hoạt,
      // tự động chuyển tiếp ngay sang Bộ não tri thức AI cục bộ
    }

    // 3) Phản hồi thông minh: Dùng Bộ não AI LocalAiEngine
    // Tự động giải đáp ĐỘNG và TOÀN DIỆN cho MỌI câu hỏi (CNTT, Toán, đời sống, cách làm...)
    // Không bao giờ hiện thông báo lỗi hay từ chối!
    return LocalAiEngine.processQuery(cleanPrompt);
  }

  // ── Gọi Gemini API với cơ chế tự động chuyển model ─────────────────────────

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
                },
                body: body,
              )
              .timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            final candidates = data['candidates'] as List<dynamic>?;
            if (candidates != null && candidates.isNotEmpty) {
              final content = candidates[0]['content'] as Map<String, dynamic>?;
              final parts = content?['parts'] as List<dynamic>?;
              if (parts != null && parts.isNotEmpty) {
                final text = (parts[0]['text'] as String? ?? '').trim();
                if (text.isNotEmpty) {
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

    throw Exception('Gemini API không phản hồi: $lastError');
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
      final res = await askAi(prompt);
      if (res.isNotEmpty) return res;
    } catch (_) {}

    return isEnglish
        ? '💡 **Explanation:**\n- Correct answer: **$correctOpt**\n'
            '- Why: ${question.explanationEn}\n'
            '- Tip: Double check keywords before selecting!'
        : '💡 **Giải thích chi tiết:**\n- Đáp án chính xác là: **$correctOpt**\n'
            '- Lý do: ${question.explanationVi}\n'
            '- Lời khuyên: Đọc kỹ từ khóa phân biệt giữa các lựa chọn để tránh nhầm lẫn.';
  }

  void dispose() {
    _client.close();
  }
}
