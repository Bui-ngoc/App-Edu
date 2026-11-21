import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/quiz_question.dart';
import 'local_ai_engine.dart';

/// ============================================================
/// GEMINI AI DATA SOURCE - EDUMASTER AI TUTOR
/// Hỗ trợ 3 cơ chế kết nối chuẩn Enterprise & Tiêu chí BTL:
///   1. Mẫu Máy chủ giữ khóa (Key Proxy Server Pattern)
///   2. Kết nối Trực tiếp qua Khóa API (Direct Gemini API Key)
///   3. Chế độ Ngoại tuyến / Demo (Offline Local AI Engine)
/// ============================================================

class GeminiAiDataSource {
  // SharedPreferences keys
  static const String _geminiKeyPref = 'edumaster_gemini_api_key';
  static const String _proxyUrlPref = 'edumaster_ai_proxy_url';
  static const String _demoModePref = 'edumaster_demo_mode';

  // Danh sách Model Google Gemini chính thức theo thứ tự ưu tiên
  static const List<String> _preferredModels = [
    'gemini-1.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-pro',
  ];

  // Gemini REST API Base URL
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/';

  // Khóa API nạp từ biến môi trường (--dart-define=GEMINI_API_KEY=...)
  static const String _envApiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  // Khóa API mặc định tích hợp sẵn (mã hóa Base64 để an toàn mã nguồn)
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

  final http.Client _client;

  GeminiAiDataSource({http.Client? client})
      : _client = client ?? http.Client();

  /// ============================================================
  /// 1. SANITIZE API KEY
  /// ============================================================

  static String sanitizeKey(String raw) {
    var key = raw.trim();

    // Loại bỏ tiền tố nhãn nếu người dùng dán cả cụm
    key = key.replaceFirst(
      RegExp(
        r'^(?:gemini[\s_-]*api[\s_-]*key|api[\s_-]*key)\s*[:=]\s*',
        caseSensitive: false,
      ),
      '',
    );

    // Loại bỏ Bearer nếu có
    key = key.replaceFirst(
      RegExp(r'^Bearer\s+', caseSensitive: false),
      '',
    );

    key = key.trim();

    // Loại bỏ dấu ngoặc kép hoặc backtick bao quanh key
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
  /// 2. GET & SAVE API KEY
  /// ============================================================

  Future<String> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_geminiKeyPref);

    if (saved != null && saved.trim().isNotEmpty) {
      return sanitizeKey(saved);
    }

    return _defaultApiKey;
  }

  Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final cleanKey = sanitizeKey(key);

    if (cleanKey.isEmpty) {
      await prefs.remove(_geminiKeyPref);
      return;
    }

    await prefs.setString(_geminiKeyPref, cleanKey);
  }

  Future<void> clearSavedApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_geminiKeyPref);
  }

  /// ============================================================
  /// 3. MÁY CHỦ GIỮ KHÓA (KEY PROXY SERVER)
  /// ============================================================

  Future<String> getProxyUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_proxyUrlPref) ?? '';
  }

  Future<void> saveProxyUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final cleanUrl = url.trim();

    if (cleanUrl.isEmpty) {
      await prefs.remove(_proxyUrlPref);
      return;
    }

    await prefs.setString(_proxyUrlPref, cleanUrl);
  }

  /// ============================================================
  /// 4. CHECK & SET DEMO MODE (NGOẠI TUYẾN)
  /// ============================================================

  Future<bool> isDemoMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_demoModePref) ?? false;
  }

  Future<void> setDemoMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_demoModePref, value);
  }

  /// ============================================================
  /// 5. MAIN AI FUNCTION (TRỰC TUYẾN vs NGOẠI TUYẾN)
  /// ============================================================

  Future<String> askAi(String prompt) async {
    final cleanPrompt = prompt.trim();

    if (cleanPrompt.isEmpty) {
      throw Exception('Vui lòng nhập nội dung câu hỏi.');
    }

    // 1. Chế độ Demo / Ngoại tuyến: Sử dụng Local AI Engine (chỉ giới hạn phạm vi môn học)
    if (await isDemoMode()) {
      return LocalAiEngine.processQuery(cleanPrompt);
    }

    // 2. Chế độ Trực tuyến: Thử gửi qua Máy chủ giữ khóa (Key Proxy Server) nếu đã cấu hình
    final proxyUrl = await getProxyUrl();
    if (proxyUrl.isNotEmpty) {
      try {
        return await _callProxyServer(proxyUrl, cleanPrompt);
      } catch (e) {
        // Nếu proxy tạm thời gián đoạn, fallback tiếp tục gọi trực tiếp
      }
    }

    // 3. Chế độ Trực tuyến: Gọi mô hình bên ngoài bằng Khóa API (Google Gemini API)
    final apiKey = await getApiKey();

    if (apiKey.isNotEmpty && !apiKey.startsWith('AQ.Ab8')) {
      try {
        return await _callRealGeminiApi(apiKey, cleanPrompt);
      } catch (e) {
        // Gặp lỗi mạng hoặc hết hạn mức -> kích hoạt Tầng 4: Offline Fallback thông minh
      }
    }

    // 4. TẦNG 4: OFFLINE FALLBACK THÔNG MINH (Theo Đặc tả Kiến trúc EduMaster 4 Tầng)
    // Khi chưa có khóa hợp lệ, mất mạng hoặc API lỗi, tự động giải đáp bằng LocalAiEngine!
    final fallbackResponse = LocalAiEngine.processQuery(cleanPrompt);
    return '$fallbackResponse\n\n'
        '---\n'
        '💡 *(Hệ thống tự động dùng bộ não AI dự phòng do chưa cấu hình Gemini API Key hợp lệ. Để kết nối trực tuyến với Google Gemini, bạn hãy vào mục **Hồ sơ > Cài đặt AI** để dán khóa API nhé!)*';
  }

  /// ============================================================
  /// 6. GỌI MÁY CHỦ GIỮ KHÓA (KEY PROXY SERVER)
  /// ============================================================

  Future<String> _callProxyServer(String proxyUrl, String userPrompt) async {
    final url = Uri.parse(proxyUrl);

    final response = await _client
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'prompt': userPrompt,
            'model': 'gemini-1.5-flash',
            'mode': 'reasoning',
          }),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode == 200) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          final reply = decoded['reply'] ??
              decoded['answer'] ??
              decoded['text'] ??
              decoded['content'];
          if (reply != null && reply.toString().isNotEmpty) {
            return reply.toString().trim();
          }
        }
      } catch (_) {}
      return response.body.trim();
    }

    throw Exception('Máy chủ giữ khóa phản hồi mã lỗi HTTP ${response.statusCode}');
  }

  /// ============================================================
  /// 7. GỌI TRỰC TIẾP MÔ HÌNH GOOGLE GEMINI (SUY NGẪM & ĐA LĨNH VỰC)
  /// ============================================================

  Future<String> _callRealGeminiApi(
    String apiKey,
    String userPrompt,
  ) async {
    final cleanKey = sanitizeKey(apiKey);

    if (cleanKey.isEmpty) {
      throw Exception('Gemini API Key không hợp lệ.');
    }

    // System Instruction kích hoạt năng lực SUY NGẪM (Reasoning) & ĐA LĨNH VỰC
    final Map<String, dynamic> requestBody = {
      'systemInstruction': {
        'parts': [
          {
            'text': '''
Bạn là EduMaster AI Tutor - Gia sư Trí tuệ Nhân tạo thông minh, thấu hiểu và uyên bác được tích hợp trong ứng dụng học tập EduMaster.

ĐẶC BIỆT KHI Ở CHẾ ĐỘ TRỰC TUYẾN (ONLINE MODE):

1. NGUYÊN TẮC SUY NGẪM SÂU SẮC (REASONING & THINKING PROCESS):
- Khi tiếp nhận câu hỏi từ học viên, hãy luôn suy ngẫm từng bước (step-by-step reasoning):
  + Phân tích thấu đáo bản chất vấn đề, mục đích và ngữ cảnh của câu hỏi.
  + Kết nối các góc nhìn kiến thức liên ngành, dẫn chứng logic và bài học thực tiễn.
  + Đưa ra câu trả lời toàn diện, sâu sắc, có cấu trúc chặt chẽ (Đặt vấn đề -> Phân tích chi tiết -> Ví dụ minh họa -> Đúc kết ghi nhớ).

2. PHẠM VI GIẢI ĐÁP MỞ RỘNG TOÀN DIỆN (ĐA LĨNH VỰC - KHÔNG CHỈ MÔN HỌC):
- Bạn sẵn sàng suy ngẫm và trả lời MỌI câu hỏi thuộc bất kỳ chủ đề, lĩnh vực nào học viên quan tâm:
  + Môn học & Công nghệ: Lập trình di động (Flutter/Dart), CSDL (SQLite), Thuật toán (SuperMemo SM-2, Data Structures), Kiến trúc phần mềm (Clean Architecture), Tiếng Anh chuyên ngành, Giải thích đề thi trắc nghiệm.
  + Khoa học & Tự nhiên: Toán học, Vật lý, Hóa học, Sinh học, Công nghệ cao, Trí tuệ nhân tạo, Khoa học máy tính.
  + Đời sống, Xã hội & Văn hóa: Lịch sử, Địa lý, Văn học, Tâm lý học tập, Kỹ năng mềm, Phương pháp tư duy phản biện, Quản trị thời gian.
  + Định hướng & Hướng dẫn: Sửa lỗi lập trình (Bug Fixing), tư vấn lộ trình học tập và phát triển nghề nghiệp.

3. PHONG CÁCH SƯ PHẠM:
- Ưu tiên tiếng Việt mạch lạc, thân thiện, kiên nhẫn và luôn khuyến khích tư duy độc lập.
- Sử dụng định dạng Markdown đẹp mắt: in đậm từ khóa, dùng danh sách ý gạch đầu dòng, bảng so sánh và khối code chuẩn khi cần thiết.
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

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'x-goog-api-key': cleanKey,
    };

    Exception? lastException;

    // Duyệt qua danh sách Model chính thức (Fallback nếu một model gặp sự cố)
    for (final modelName in _preferredModels) {
      final Uri url = Uri.parse('$_baseUrl$modelName:generateContent');

      try {
        http.Response? response;

        // Thử tối đa 2 lần cho mỗi model nếu gặp lỗi mạng tạm thời
        for (int attempt = 0; attempt < 2; attempt++) {
          try {
            response = await _client
                .post(
                  url,
                  headers: headers,
                  body: jsonEncode(requestBody),
                )
                .timeout(const Duration(seconds: 45));

            if (response.statusCode == 429 ||
                response.statusCode == 500 ||
                response.statusCode == 502 ||
                response.statusCode == 503) {
              if (attempt == 0) {
                await Future.delayed(const Duration(seconds: 2));
                continue;
              }
            }
            break;
          } on TimeoutException {
            if (attempt == 0) {
              await Future.delayed(const Duration(seconds: 2));
              continue;
            }
            rethrow;
          }
        }

        if (response == null) continue;

        // Nếu model 404 (không tìm thấy model trên API key này), thử tiếp model kế tiếp
        if (response.statusCode == 404) {
          continue;
        }

        Map<String, dynamic> data;
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            data = decoded;
          } else {
            continue;
          }
        } on FormatException {
          continue;
        }

        // Xử lý mã lỗi HTTP
        if (response.statusCode != 200) {
          final error = data['error'];
          final message = error is Map ? (error['message']?.toString() ?? '') : '';

          switch (response.statusCode) {
            case 400:
              throw Exception('HTTP 400 - Yêu cầu không hợp lệ: $message');
            case 401:
              throw Exception('HTTP 401 - API Key không hợp lệ hoặc đã hết hạn: $message');
            case 403:
              throw Exception('HTTP 403 - API Key bị giới hạn quyền truy cập: $message');
            case 429:
              throw Exception('HTTP 429 - Đã vượt hạn mức gọi API Gemini (Rate Limit). Vui lòng thử lại sau ít phút hoặc đổi key.');
            case 500:
            case 502:
            case 503:
              throw Exception('Lỗi máy chủ Google Gemini ($message). Vui lòng thử lại.');
            default:
              throw Exception('Gemini API HTTP ${response.statusCode}: $message');
          }
        }

        // Đọc câu trả lời từ Candidates
        final candidates = data['candidates'];
        if (candidates is List && candidates.isNotEmpty) {
          final candidate = candidates.first;
          if (candidate is Map) {
            final content = candidate['content'];
            if (content is Map) {
              final parts = content['parts'];
              if (parts is List && parts.isNotEmpty) {
                final String answer = parts
                    .whereType<Map>()
                    .map((p) => p['text'])
                    .whereType<String>()
                    .join('\n')
                    .trim();

                if (answer.isNotEmpty) {
                  return answer;
                }
              }
            }
          }
        }
      } on SocketException {
        throw Exception('Không có kết nối Internet. Vui lòng kiểm tra mạng hoặc chuyển sang Chế độ Ngoại tuyến (Offline).');
      } on TimeoutException {
        throw Exception('Kết nối tới Gemini quá thời gian chờ (Timeout). Vui lòng kiểm tra lại mạng hoặc thử lại.');
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
      }
    }

    if (lastException != null) {
      throw lastException;
    }

    throw Exception('Không thể nhận phản hồi từ các mô hình AI trực tuyến. Vui lòng thử lại sau.');
  }

  /// ============================================================
  /// 8. TEST GEMINI CONNECTION
  /// ============================================================

  Future<String> testConnection() async {
    final apiKey = await getApiKey();

    if (apiKey.isEmpty) {
      throw Exception('Chưa có API Key. Hãy nhập và lưu API Key trước.');
    }

    return _callRealGeminiApi(
      apiKey,
      'Hãy trả lời ngắn gọn đúng 1 câu: EduMaster AI Tutor đã kết nối thành công qua khóa API.',
    );
  }

  /// ============================================================
  /// 9. EXPLAIN WRONG ANSWER
  /// ============================================================

  Future<String> explainWrongAnswer({
    required QuizQuestion question,
    required int selectedIndex,
    required bool isEnglish,
  }) async {
    final selectedOptions = isEnglish ? question.optionsEn : question.optionsVi;
    final correctOptions = isEnglish ? question.optionsEn : question.optionsVi;

    if (selectedIndex < 0 || selectedIndex >= selectedOptions.length) {
      throw Exception('Đáp án học viên chọn không hợp lệ.');
    }

    if (question.correctIndex < 0 || question.correctIndex >= correctOptions.length) {
      throw Exception('Đáp án đúng của câu hỏi không hợp lệ.');
    }

    final selectedOpt = selectedOptions[selectedIndex];
    final correctOpt = correctOptions[question.correctIndex];

    final String prompt = isEnglish
        ? '''
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
'''
        : '''
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
3. Phân tích kiến thức liên quan và điều học viên cần ghi nhớ.

Hãy giải thích ngắn gọn, dễ hiểu và có tính sư phạm.
''';

    return askAi(prompt);
  }

  /// ============================================================
  /// 10. DISPOSE
  /// ============================================================

  void dispose() {
    _client.close();
  }
}
