
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/quiz_question.dart';
import 'local_ai_engine.dart';

/// ============================================================
/// GEMINI AI DATA SOURCE - EDUMASTER AI TUTOR
/// Kết nối Google Gemini API thật bằng API Key.
/// ============================================================

class GeminiAiDataSource {
  // SharedPreferences keys
  static const String _geminiKeyPref = 'edumaster_gemini_api_key';
  static const String _demoModePref = 'edumaster_demo_mode';

  // Model Gemini
  static const String _model = 'gemini-3.8-flash';

  // Gemini REST API
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/';

  final http.Client _client;

  GeminiAiDataSource({http.Client? client})
      : _client = client ?? http.Client();

  /// ============================================================
  /// 1. SANITIZE API KEY
  /// ============================================================

  static String sanitizeKey(String raw) {
    var key = raw.trim();

    // Loại bỏ tiền tố API Key nếu người dùng dán cả nhãn.
    key = key.replaceFirst(
      RegExp(
        r'^(?:gemini[\s_-]*api[\s_-]*key|api[\s_-]*key)\s*[:=]\s*',
        caseSensitive: false,
      ),
      '',
    );

    // Loại bỏ Bearer nếu người dùng dán kèm.
    key = key.replaceFirst(
      RegExp(r'^Bearer\s+', caseSensitive: false),
      '',
    );

    key = key.trim();

    // Loại bỏ dấu ngoặc kép bao quanh key.
    if (key.length >= 2) {
      final first = key[0];
      final last = key[key.length - 1];

      if ((first == '"' && last == '"') ||
          (first == "'" && last == "'") ||
          (first == '`' && last == '`')) {
        key = key.substring(1, key.length - 1);
      }
    }

    return key.trim();
  }

  /// ============================================================
  /// 2. GET API KEY
  /// ============================================================

  Future<String> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getString(_geminiKeyPref);

    if (saved != null && saved.trim().isNotEmpty) {
      return sanitizeKey(saved);
    }

    // Không sử dụng API Key mặc định trong source code.
    return '';
  }

  /// ============================================================
  /// 3. SAVE API KEY
  /// ============================================================

  Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();

    final cleanKey = sanitizeKey(key);

    if (cleanKey.isEmpty) {
      await prefs.remove(_geminiKeyPref);
      return;
    }

    await prefs.setString(_geminiKeyPref, cleanKey);
  }

  /// ============================================================
  /// 4. CLEAR API KEY
  /// ============================================================

  Future<void> clearSavedApiKey() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_geminiKeyPref);
  }

  /// ============================================================
  /// 5. CHECK DEMO MODE
  /// ============================================================

  Future<bool> isDemoMode() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_demoModePref) ?? false;
  }

  /// ============================================================
  /// 6. SET DEMO MODE
  /// ============================================================

  Future<void> setDemoMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_demoModePref, value);
  }

  /// ============================================================
  /// 7. MAIN AI FUNCTION
  /// ============================================================

  Future<String> askAi(String prompt) async {
    final cleanPrompt = prompt.trim();

    if (cleanPrompt.isEmpty) {
      throw Exception('Vui lòng nhập nội dung câu hỏi.');
    }

    // Demo Mode: sử dụng AI Local.
    if (await isDemoMode()) {
      return LocalAiEngine.processQuery(cleanPrompt);
    }

    // Real AI Mode: sử dụng Gemini API.
    final apiKey = await getApiKey();

    if (apiKey.isEmpty) {
      throw Exception(
        'Chưa có Gemini API Key.\n'
            'Vui lòng nhập và lưu API Key trong phần cài đặt AI.',
      );
    }

    return _callRealGeminiApi(apiKey, cleanPrompt);
  }

  /// ============================================================
  /// 8. CALL REAL GEMINI API
  /// ============================================================

  Future<String> _callRealGeminiApi(
      String apiKey,
      String userPrompt,
      ) async {
    final cleanKey = sanitizeKey(apiKey);

    if (cleanKey.isEmpty) {
      throw Exception('Gemini API Key không hợp lệ.');
    }

    final Uri url = Uri.parse(
      '$_baseUrl$_model:generateContent',
    );

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'x-goog-api-key': cleanKey,
    };

    // System Instruction dành riêng cho EduMaster AI Tutor.
    final Map<String, dynamic> requestBody = {
      'systemInstruction': {
        'parts': [
          {
            'text': '''
Bạn là EduMaster AI Tutor - một gia sư AI thông minh
được tích hợp trong ứng dụng học tập EduMaster.

VAI TRÒ:
- Trợ lý học tập cá nhân của học viên.
- Giải đáp các câu hỏi thuộc nhiều lĩnh vực.
- Hỗ trợ học lập trình, toán học, tiếng Anh và công nghệ thông tin.
- Hướng dẫn giải bài tập và phân tích lỗi sai.
- Giúp học viên hiểu bản chất kiến thức thay vì chỉ ghi nhớ đáp án.

NGUYÊN TẮC TRẢ LỜI:

1. Ngôn ngữ:
- Ưu tiên tiếng Việt.
- Có thể sử dụng tiếng Anh khi học viên yêu cầu.
- Giải thích thuật ngữ chuyên ngành bằng ngôn ngữ dễ hiểu.

2. Giải thích kiến thức:
- Trình bày rõ ràng, chính xác.
- Chia thành các phần khi nội dung dài.
- Đưa ra ví dụ minh họa phù hợp.
- Không trả lời chung chung khi có thể giải thích cụ thể.

3. Giải bài tập:
- Phân tích đề bài.
- Xác định dữ kiện.
- Trình bày phương pháp giải.
- Giải thích từng bước.
- Đưa ra kết quả cuối cùng.

4. Hỗ trợ lập trình:
- Đưa ra code khi cần thiết.
- Giải thích từng đoạn code.
- Phân tích lỗi và nguyên nhân.
- Đề xuất cách sửa.
- Ưu tiên code dễ hiểu, phù hợp với người mới học.

5. Vai trò gia sư:
- Thân thiện, kiên nhẫn.
- Không đánh giá tiêu cực người học.
- Khuyến khích tư duy độc lập.
- Nếu câu hỏi thiếu dữ kiện, hãy hỏi lại.
- Không tự bịa thông tin hoặc đáp án.

6. Định dạng:
- Sử dụng tiêu đề khi cần.
- Dùng danh sách để trình bày các ý.
- Dùng Markdown cho công thức và code.
- Tránh câu trả lời quá dài nếu không cần thiết.

Mục tiêu:
Giúp người học tiếp thu kiến thức hiệu quả
và có trải nghiệm như đang học cùng một gia sư AI thực thụ.
'''
          }
        ]
      },

      'contents': [
        {
          'role': 'user',
          'parts': [
            {
              'text': userPrompt,
            }
          ]
        }
      ],

      'generationConfig': {
        'temperature': 0.7,
        'topP': 0.9,
        'maxOutputTokens': 4096,
      }
    };

    try {
      // Dùng late để khai báo response trước vòng lặp retry.
      late http.Response response;

      // Thử tối đa 2 lần.
      for (int attempt = 0; attempt < 2; attempt++) {
        try {
          response = await _client
              .post(
            url,
            headers: headers,
            body: jsonEncode(requestBody),
          )
              .timeout(const Duration(seconds: 60));

          // Retry khi máy chủ gặp lỗi tạm thời.
          if (response.statusCode == 429 ||
              response.statusCode == 500 ||
              response.statusCode == 502 ||
              response.statusCode == 503) {
            if (attempt == 0) {
              await Future.delayed(
                const Duration(seconds: 3),
              );
              continue;
            }
          }

          break;
        } on TimeoutException {
          if (attempt == 0) {
            await Future.delayed(
              const Duration(seconds: 3),
            );
            continue;
          }

          rethrow;
        }
      }

      // ========================================================
      // PARSE RESPONSE JSON
      // ========================================================

      Map<String, dynamic> data;

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is! Map<String, dynamic>) {
          throw Exception(
            'Gemini trả về dữ liệu không hợp lệ.',
          );
        }

        data = decoded;
      } on FormatException {
        throw Exception(
          'Không thể đọc phản hồi JSON từ Gemini API.',
        );
      }

      // ========================================================
      // CHECK HTTP STATUS
      // ========================================================

      if (response.statusCode != 200) {
        final error = data['error'];

        final message = error is Map
            ? error['message']?.toString() ??
            'Không rõ nguyên nhân'
            : 'Không rõ nguyên nhân';

        final status = error is Map
            ? error['status']?.toString() ?? ''
            : '';

        switch (response.statusCode) {
          case 400:
            throw Exception(
              'HTTP 400 - Yêu cầu không hợp lệ.\n$message',
            );

          case 401:
            throw Exception(
              'HTTP 401 - API Key không hợp lệ hoặc không được '
                  'Google chấp nhận.\n$message',
            );

          case 403:
            throw Exception(
              'HTTP 403 - API Key không có quyền truy cập '
                  'Gemini API hoặc bị giới hạn.\n$message',
            );

          case 404:
            throw Exception(
              'HTTP 404 - Không tìm thấy model hoặc endpoint.\n'
                  'Model hiện tại: $_model\n$message',
            );

          case 429:
            throw Exception(
              'HTTP 429 - Đã vượt giới hạn sử dụng API.\n$message',
            );

          case 500:
          case 502:
          case 503:
            throw Exception(
              'Lỗi máy chủ Google Gemini. Vui lòng thử lại sau.\n'
                  '$message',
            );

          default:
            throw Exception(
              'Gemini API HTTP ${response.statusCode}'
                  '${status.isNotEmpty ? ' ($status)' : ''}:\n$message',
            );
        }
      }

      // ========================================================
      // GET CANDIDATES
      // ========================================================

      final candidates = data['candidates'];

      if (candidates is! List || candidates.isEmpty) {
        final feedback = data['promptFeedback'];

        final blockReason = feedback is Map
            ? feedback['blockReason']?.toString()
            : null;

        if (blockReason != null && blockReason.isNotEmpty) {
          throw Exception(
            'Gemini không thể xử lý câu hỏi: $blockReason',
          );
        }

        throw Exception(
          'Gemini API không trả về câu trả lời.',
        );
      }

      final candidate = candidates.first;

      if (candidate is! Map) {
        throw Exception(
          'Cấu trúc Candidate không hợp lệ.',
        );
      }

      // ========================================================
      // GET RESPONSE CONTENT
      // ========================================================

      final content = candidate['content'];

      if (content is! Map) {
        final finishReason =
            candidate['finishReason']?.toString() ?? '';

        throw Exception(
          'Gemini không tạo được nội dung trả lời.\n'
              'Finish reason: $finishReason',
        );
      }

      final parts = content['parts'];

      if (parts is! List || parts.isEmpty) {
        throw Exception(
          'Gemini trả về nội dung rỗng.',
        );
      }

      // Ghép tất cả phần text.
      final String answer = parts
          .whereType<Map>()
          .map((part) => part['text'])
          .whereType<String>()
          .join('\n')
          .trim();

      if (answer.isEmpty) {
        throw Exception(
          'Gemini không trả về nội dung văn bản.',
        );
      }

      return answer;
    } on TimeoutException {
      throw Exception(
        'Kết nối Gemini quá thời gian chờ. '
            'Vui lòng kiểm tra Internet và thử lại.',
      );
    } on SocketException {
      throw Exception(
        'Không có kết nối Internet. '
            'Vui lòng kiểm tra mạng của bạn.',
      );
    } on http.ClientException catch (e) {
      throw Exception(
        'Lỗi HTTP Client khi kết nối Gemini: ${e.message}',
      );
    }
  }

  /// ============================================================
  /// 9. TEST GEMINI CONNECTION
  /// ============================================================

  Future<String> testConnection() async {
    final apiKey = await getApiKey();

    if (apiKey.isEmpty) {
      throw Exception(
        'Chưa có API Key. Hãy nhập và lưu API Key trước.',
      );
    }

    // Kiểm tra Gemini thật, không phụ thuộc Demo Mode.
    return _callRealGeminiApi(
      apiKey,
      'Hãy trả lời đúng một câu: '
          'EduMaster AI Tutor đã kết nối thành công.',
    );
  }

  /// ============================================================
  /// 10. EXPLAIN WRONG ANSWER
  /// ============================================================

  Future<String> explainWrongAnswer({
    required QuizQuestion question,
    required int selectedIndex,
    required bool isEnglish,
  }) async {
    final selectedOptions = isEnglish
        ? question.optionsEn
        : question.optionsVi;

    final correctOptions = isEnglish
        ? question.optionsEn
        : question.optionsVi;

    // Kiểm tra selectedIndex.
    if (selectedIndex < 0 ||
        selectedIndex >= selectedOptions.length) {
      throw Exception(
        'Đáp án học viên chọn không hợp lệ.',
      );
    }

    // Kiểm tra correctIndex.
    if (question.correctIndex < 0 ||
        question.correctIndex >= correctOptions.length) {
      throw Exception(
        'Đáp án đúng của câu hỏi không hợp lệ.',
      );
    }

    final selectedOpt = selectedOptions[selectedIndex];

    final correctOpt = correctOptions[question.correctIndex];

    final String prompt;

    if (isEnglish) {
      prompt = '''
You are an English learning tutor.

Question:
"${question.questionEn}"

Student's selected answer:
"$selectedOpt"

Correct answer:
"$correctOpt"

Reference explanation:
${question.explanationEn}

Please explain:

1. Why is the student's selected answer incorrect?
2. Why is the correct answer right?
3. What knowledge should the student remember?

Use simple and clear English.
Give examples if necessary.
''';
    } else {
      prompt = '''
Bạn là gia sư AI của EduMaster.

CÂU HỎI:
"${question.questionVi}"

ĐÁP ÁN HỌC VIÊN ĐÃ CHỌN:
"$selectedOpt"

ĐÁP ÁN CHÍNH XÁC:
"$correctOpt"

GIẢI THÍCH THAM KHẢO:
${question.explanationVi}

YÊU CẦU:

1. Giải thích tại sao đáp án học viên chọn chưa đúng.
2. Giải thích tại sao đáp án chính xác là đúng.
3. Phân tích kiến thức liên quan.
4. Nêu điều học viên cần ghi nhớ.

Hãy giải thích ngắn gọn, dễ hiểu và có tính sư phạm.
Đóng vai trò như một gia sư đang hướng dẫn học viên.
''';
    }

    // Gọi AI thật hoặc Local AI tùy Demo Mode.
    // Không tự động trả về đáp án tĩnh khi API lỗi.
    return askAi(prompt);
  }

  /// ============================================================
  /// 11. DISPOSE HTTP CLIENT
  /// ============================================================

  void dispose() {
    _client.close();
  }
}
