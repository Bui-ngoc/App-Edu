import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/quiz_question.dart';
import '../../core/errors/app_exception.dart';

/// EduMaster AI DataSource
///
/// Priority order for AI calls:
///   1. DEMO MODE  — returns pre-canned bilingual responses (no network, no key)
///   2. PROXY MODE — POST to a proxy server that holds the real Gemini key
///   3. DIRECT KEY — calls Gemini API directly with user-entered key
///   4. OFFLINE    — smart local fallback responses (always works)
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

  /// Ask AI Tutor — tries proxy → direct key → offline fallback.
  Future<String> askAi(String prompt) async {
    // 1) DEMO MODE
    if (await isDemoMode()) {
      return _getDemoResponse(prompt);
    }

    // 2) PROXY MODE
    final proxyUrl = await getProxyUrl();
    if (proxyUrl.isNotEmpty) {
      try {
        return await _askViaProxy(proxyUrl, prompt);
      } on NetworkTimeoutException {
        rethrow;
      } catch (_) {
        // proxy failed → fall through to direct key
      }
    }

    // 3) DIRECT KEY
    final apiKey = await getApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        return await _askGeminiDirect(apiKey, prompt);
      } on NetworkTimeoutException {
        rethrow;
      } catch (_) {
        return _getSmartLocalTutorResponse(prompt);
      }
    }

    // 4) OFFLINE FALLBACK
    return _getSmartLocalTutorResponse(prompt);
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
      // Accept either {"text": "..."} or Gemini-format {"candidates":[...]}
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
    return _getSmartLocalTutorResponse(prompt);
  }

  // ── Explain wrong answer (uses askAi internally) ──────────────────────────

  /// AI Explains why an answer was wrong in bilingual quiz
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
          ? '💡 Explanation:\n- Correct answer: $correctOpt\n'
              '- Why: ${question.explanationEn}\n'
              '- Tip: Double check definitions before choosing!'
          : '💡 Giải thích:\n- Đáp án đúng: $correctOpt\n'
              '- Lý do: ${question.explanationVi}\n'
              '- Lưu ý: Đọc kỹ từ khóa phân biệt giữa các lựa chọn.';
    }
  }

  // ── Demo responses ────────────────────────────────────────────────────────

  String _getDemoResponse(String prompt) {
    final p = prompt.toLowerCase();
    if (p.contains('sm-2') || p.contains('flashcard') || p.contains('spaced')) {
      return '🧠 **[DEMO] SuperMemo SM-2 Algorithm:**\n'
          '- Quality rating: 0–5 (≥3 = remembered)\n'
          '- EF starts at 2.5; updates after each review\n'
          '- Interval grows: 1 → 6 → EF×previous days\n'
          '- Quality < 3 resets the card to day 1\n\n'
          '_[Demo mode — no API key needed. Configure in Settings ⚙️]_';
    }
    if (p.contains('flutter') || p.contains('dart') || p.contains('widget')) {
      return '📱 **[DEMO] Flutter Quick Reference:**\n'
          '- Widget tree = UI description (immutable)\n'
          '- State management: Provider → ChangeNotifier → notifyListeners()\n'
          '- Build is called whenever the widget rebuilds\n'
          '- Dispose controllers in dispose() to avoid leaks\n\n'
          '_[Demo mode — no API key needed. Configure in Settings ⚙️]_';
    }
    if (p.contains('firebase') || p.contains('firestore')) {
      return '🔥 **[DEMO] Firebase / Firestore:**\n'
          '- NoSQL document database, real-time sync\n'
          '- Collection → Document → Fields hierarchy\n'
          '- StreamBuilder listens to live updates\n'
          '- Security rules protect read/write access\n\n'
          '_[Demo mode — no API key needed. Configure in Settings ⚙️]_';
    }
    return '🤖 **[DEMO] EduMaster AI Tutor:**\n'
        '- Chế độ Demo đang bật — phản hồi từ bộ dữ liệu có sẵn.\n'
        '- Hỏi về: SM-2, Flutter, Firebase, SQLite, MVC...\n'
        '- Để dùng Gemini thực, tắt Demo Mode trong Cài đặt ⚙️\n\n'
        '_Demo mode is ON — responses are pre-cached, no network needed._';
  }

  // ── Smart offline fallback ────────────────────────────────────────────────

  String _getSmartLocalTutorResponse(String prompt) {
    final pLower = prompt.toLowerCase();
    if (pLower.contains('sm-2') ||
        pLower.contains('flashcard') ||
        pLower.contains('lặp lại')) {
      return '🧠 **Thuật toán SuperMemo SM-2:**\n'
          '- Dựa trên 2 biến số chính: **Ease Factor (EF ≥ 1.3)** và **Khoảng ôn tập (Interval tính bằng ngày)**.\n'
          '- Đánh giá chất lượng nhớ từ 0 - 5. Nếu điểm < 3, thẻ bị coi là quên và reset về ngày thứ 1.\n'
          '- Điểm ≥ 3 sẽ nhân giãn cách theo hệ số EF.';
    }
    if (pLower.contains('mvc') || pLower.contains('kiến trúc')) {
      return '🏛️ **Kiến trúc MVC (Model - View - Controller):**\n'
          '- **Model:** Quản lý dữ liệu, logic nghiệp vụ, giao tiếp cơ sở dữ liệu.\n'
          '- **View:** Giao diện hiển thị cho người dùng (Widgets trong Flutter).\n'
          '- **Controller / Provider:** Điều phối dữ liệu giữa Model và View.';
    }
    if (pLower.contains('sqlite') ||
        pLower.contains('cơ sở dữ liệu') ||
        pLower.contains('fts')) {
      return '💾 **Cơ sở dữ liệu SQLite & FTS:**\n'
          '- SQLite là CSDL quan hệ nhúng cục bộ, không cần cài đặt server riêng.\n'
          '- **FTS (Full-Text Search):** Bảng ảo hỗ trợ tìm kiếm toàn văn siêu tốc O(log N) '
          'thay vì quét toàn bộ bảng LIKE %query%.';
    }
    return '🤖 **Trợ lý EduMaster AI Tutor:**\n'
        '- Bạn đang học tập rất tốt! Để ghi nhớ lâu hơn, hãy kết hợp làm trắc nghiệm song ngữ '
        'và ôn tập thẻ ghi nhớ SM-2 mỗi ngày.\n'
        '- *Gợi ý:* Hãy đặt câu hỏi cụ thể về thuật ngữ CNTT, toán học hoặc ngữ pháp tiếng Anh '
        'để mình giải đáp nhé!';
  }

  void dispose() {
    _client.close();
  }
}
