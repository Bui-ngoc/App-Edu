import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/exam.dart';
import '../../domain/entities/quiz_question.dart';

class ExamStorageDataSource {
  static const String _roomsKey = 'edumaster_exam_rooms';
  static const String _resultsKeyPrefix = 'edumaster_exam_results_';

  Future<List<ExamRoom>> getRooms() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_roomsKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      final defaultRoom = ExamRoom(
        id: 'EXAM100',
        title: 'Kỳ thi Thử nghiệm Kỹ năng Số & Lập trình 2026',
        creatorName: 'TS. Nguyễn Văn Hướng (Bộ môn CNTT)',
        durationMinutes: 10,
        createdAt: DateTime.now(),
        questions: [
          const QuizQuestion(
            id: 101,
            grade: 12,
            category: 'Tin học (Computer Science)',
            questionVi: 'Đặc điểm nào bắt buộc của Khóa chính (Primary Key) trong cơ sở dữ liệu quan hệ?',
            questionEn: 'What is a mandatory requirement for a Primary Key in RDBMS?',
            optionsVi: ['Duy nhất và NOT NULL', 'Có thể trùng lặp', 'Có thể nhận NULL', 'Kiểu dữ liệu chỉ là chuỗi'],
            optionsEn: ['Unique and NOT NULL', 'Can be duplicate', 'Can be NULL', 'String type only'],
            correctIndex: 0,
            explanationVi: 'Khóa chính bắt buộc phải duy nhất và không được phép mang giá trị NULL.',
            explanationEn: 'Primary key must be unique and cannot be NULL.',
          ),
          const QuizQuestion(
            id: 102,
            grade: 12,
            category: 'Tin học (Computer Science)',
            questionVi: 'Trong Flutter, phương thức nào được gọi khi một State object bị hủy giải phóng tài nguyên?',
            questionEn: 'In Flutter, which method is called when a State object is permanently removed to free resources?',
            optionsVi: ['dispose()', 'initState()', 'build()', 'setState()'],
            optionsEn: ['dispose()', 'initState()', 'build()', 'setState()'],
            correctIndex: 0,
            explanationVi: 'dispose() được dùng để giải phóng các AnimationController, ScrollController, StreamSubscription.',
            explanationEn: 'dispose() is called to release controllers and cancel streams to prevent memory leaks.',
          ),
          const QuizQuestion(
            id: 103,
            grade: 11,
            category: 'Tin học (Computer Science)',
            questionVi: 'Thuật toán SuperMemo SM-2 sử dụng hệ số nào để điều chỉnh độ giãn cách thời gian ôn tập?',
            questionEn: 'Which factor does the SuperMemo SM-2 algorithm use to adjust review intervals?',
            optionsVi: ['Ease Factor (EF)', 'Hash Factor (HF)', 'Random Weight', 'Constant Factor (CF)'],
            optionsEn: ['Ease Factor (EF)', 'Hash Factor (HF)', 'Random Weight', 'Constant Factor (CF)'],
            correctIndex: 0,
            explanationVi: 'Ease Factor (EF) khởi điểm 2.5 và nhỏ nhất là 1.3.',
            explanationEn: 'Ease Factor (EF) starts at 2.5 and has a minimum threshold of 1.3.',
          ),
          const QuizQuestion(
            id: 104,
            grade: 12,
            category: 'Khoa học (Science)',
            questionVi: 'Giao thức bảo mật mạng HTTPS sử dụng chứng chỉ số nào để mã hóa đường truyền?',
            questionEn: 'Which digital certificate does the HTTPS protocol use for encrypted transport?',
            optionsVi: ['SSL / TLS', 'FTP Certificate', 'DNS Key', 'ARP Token'],
            optionsEn: ['SSL / TLS', 'FTP Certificate', 'DNS Key', 'ARP Token'],
            correctIndex: 0,
            explanationVi: 'HTTPS mã hóa qua chứng chỉ SSL/TLS nhằm bảo vệ dữ liệu truyền qua cổng 443.',
            explanationEn: 'HTTPS encrypts communication over port 443 using SSL/TLS.',
          ),
        ],
      );
      await prefs.setString(_roomsKey, json.encode([defaultRoom.toMap()]));
      return [defaultRoom];
    }

    try {
      final List<dynamic> list = json.decode(jsonStr);
      return list.map((e) => ExamRoom.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRoom(ExamRoom room) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_roomsKey);
    List<ExamRoom> rooms = [];
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(jsonStr);
        rooms = list.map((e) => ExamRoom.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      } catch (_) {}
    }
    final idx = rooms.indexWhere((r) => r.id.toUpperCase() == room.id.toUpperCase());
    if (idx >= 0) {
      rooms[idx] = room;
    } else {
      rooms.add(room);
    }
    await prefs.setString(_roomsKey, json.encode(rooms.map((r) => r.toMap()).toList()));
  }

  Future<ExamRoom?> getRoomById(String id) async {
    final rooms = await getRooms();
    try {
      return rooms.firstWhere((r) => r.id.toUpperCase() == id.trim().toUpperCase());
    } catch (_) {
      return null;
    }
  }

  Future<void> submitResult(ExamSessionResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_resultsKeyPrefix${result.roomId.toUpperCase()}';
    final existingJson = prefs.getString(key);
    List<dynamic> list = [];
    if (existingJson != null && existingJson.isNotEmpty) {
      try {
        list = json.decode(existingJson) as List<dynamic>;
      } catch (_) {}
    }
    list.add(result.toMap());
    await prefs.setString(key, json.encode(list));
  }

  Future<List<ExamSessionResult>> getResultsForRoom(String roomId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_resultsKeyPrefix${roomId.toUpperCase()}';
    final jsonStr = prefs.getString(key);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> list = json.decode(jsonStr);
      return list.map((e) => ExamSessionResult.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }
}
