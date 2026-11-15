import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/quiz_question.dart';
import '../../core/errors/app_exception.dart';
import 'local_ai_engine.dart';

/// EduMaster AI DataSource
///
/// Thứ tự ưu tiên xử lý:
///   1. DEMO MODE  — Dùng bộ não AI Ngoại tuyến thông minh LocalAiEngine (không cần mạng, không cần key)
///   2. PROXY MODE — Gửi câu hỏi lên Proxy server trung gian giữ khóa
///   3. DIRECT KEY — Gọi trực tiếp Google Gemini 1.5 Flash API
///   4. OFFLINE    — Tự động kích hoạt LocalAiEngine xử lý động mọi câu hỏi
class GeminiAiDataSource {
  // ── SharedPreferences keys ────────────────────────────────────────────────
  static const String _geminiKeyPref  = 'edumaster_gemini_api_key';
  static const String _proxyUrlPref   = 'edumaster_proxy_url';
  static const String _demoModePref   = 'edumaster_demo_mode';

  // ── Build-time constant (flutter run --dart-define=DEMO_MODE=true) ────────
  static const bool _buildDemoMode =
      bool.fromEnvironment('DEMO_MODE', defaultValue: false);

  final http.Client _client;

  GeminiAiDataSource({http.Client? client}) : _client = client ?? http.Client();

  // ── Getters / Setters ─────────────────────────────────────────────────────

  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_geminiKeyPref);
  }

  Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiKeyPref, key.trim());
  }

  Future<String> getProxyUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_proxyUrlPref) ?? '';
  }

  Future<void> saveProxyUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_proxyUrlPref, url.trim());
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

  /// Trả lời câu hỏi học viên — Ưu tiên Proxy/Direct Key, tự động fallback sang LocalAiEngine
  Future<String> askAi(String prompt) async {
    // 1) DEMO MODE
    if (await isDemoMode()) {
      return LocalAiEngine.processQuery(prompt);
    }

    // 2) PROXY MODE
    final proxyUrl = await getProxyUrl();
    if (proxyUrl.isNotEmpty) {
      try {
        return await _askViaProxy(proxyUrl, prompt);
      } on NetworkTimeoutException {
        rethrow;
      } catch (_) {
        // Proxy lỗi → chuyển sang bước tiếp theo
      }
    }

    // 3) DIRECT KEY (Google Gemini 1.5 Flash)
    final apiKey = await getApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        return await _askGeminiDirect(apiKey, prompt);
      } on NetworkTimeoutException {
        rethrow;
      } catch (_) {
        // Gọi Gemini lỗi / hết quota / mất mạng → dùng LocalAiEngine
        return LocalAiEngine.processQuery(prompt);
      }
    }

    // 4) OFFLINE / KHÔNG CÓ KEY: Dùng Bộ não AI ngoại tuyến thông minh
    return LocalAiEngine.processQuery(prompt);
  }

  // ── Proxy call ────────────────────────────────────────────────────────────

  Future<String> _askViaProxy(String proxyUrl, String prompt) async {
    final uri = Uri.parse(proxyUrl);
    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'prompt': 'Bạn là Trợ lý EduMaster AI Tutor (giáo dục, CNTT). '
                'Trả lời súc tích, có gạch đầu dòng: $prompt'
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data.containsKey('text')) {
        return data['text'].toString().trim();
      }
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates != null && candidates.isNotEmpty) {
        final parts = candidates[0]['content']['parts'] as List<dynamic>?;
        if (parts != null && parts.isNotEmpty) {
          return parts[0]['text'].toString().trim();
        }
      }
    }
    throw AppException('Proxy trả về lỗi HTTP ${response.statusCode}');
  }

  // ── Direct Gemini call ────────────────────────────────────────────────────

  Future<String> _askGeminiDirect(String apiKey, String prompt) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      'gemini-1.5-flash:generateContent?key=$apiKey',
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
                    'text': 'Bạn là một gia sư AI thân thiện (EduMaster AI Tutor) '
                        'dạy học sinh các môn Tin học, Toán học, Tiếng Anh. '
                        'Hãy trả lời súc tích, dễ hiểu, định dạng gạch đầu dòng rõ ràng: $prompt'
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
    return LocalAiEngine.processQuery(prompt);
  }

  // ── Explain wrong answer ──────────────────────────────────────────────────

  /// AI giải thích vì sao câu trả lời bị sai trong bài trắc nghiệm song ngữ
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
        ? 'Explain briefly why for the question "${question.questionEn}", '
            'the chosen answer "$selectedOpt" is incorrect, and the correct answer '
            'is "$correctOpt". Reference: ${question.explanationEn}'
        : 'Hãy giải thích ngắn gọn tại sao câu hỏi "${question.questionVi}", '
            'chọn đáp án "$selectedOpt" là chưa chính xác, và đáp án đúng phải '
            'là "$correctOpt". Tham khảo lời giải: ${question.explanationVi}';

    try {
      return await askAi(prompt);
    } catch (_) {
      return isEnglish
          ? '💡 **Explanation:**\n- Correct answer: **$correctOpt**\n'
              '- Why: ${question.explanationEn}\n'
              '- Tip: Double check keywords before selecting!'
          : '💡 **Giải thích chi tiết:**\n- Đáp án chính xác là: **$correctOpt**\n'
              '- Lý do: ${question.explanationVi}\n'
              '- Lời khuyên: Đọc kỹ từ khóa phân biệt giữa các lựa chọn để tránh nhầm lẫn.';
    }
  }

  void dispose() {
    _client.close();
  }
}
