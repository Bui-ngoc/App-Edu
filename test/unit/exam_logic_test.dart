import 'package:flutter_test/flutter_test.dart';
import 'package:edumaster/domain/entities/exam.dart';

void main() {
  group('Phòng thi trực tuyến & Giám sát rời app (Unit Tests - Topic #34)', () {
    test('11. Tính toán điểm số thang 10 và phần trăm hoàn thành chính xác', () {
      final session = ExamSessionResult(
        roomId: 'EXAM100',
        studentName: 'Nguyễn Văn A',
        score: 8,
        totalQuestions: 10,
        timeSpentSeconds: 450,
        appSwitchViolations: 0,
        violationTimestamps: const [],
        submittedAt: DateTime.now(),
      );

      expect(session.percentage, equals(80.0));
      expect(session.scoreOnScale10, equals(8.0));
    });

    test('12. Ghi nhận vi phạm khi rời ứng dụng trong lúc thi', () {
      final session = ExamSessionResult(
        roomId: 'EXAM100',
        studentName: 'Trần Văn B',
        score: 7,
        totalQuestions: 10,
        timeSpentSeconds: 600,
        appSwitchViolations: 2,
        violationTimestamps: const [
          'Rời màn hình thi lúc 14:15:20 (Lần 1)',
          'Rời màn hình thi lúc 14:18:05 (Lần 2)'
        ],
        submittedAt: DateTime.now(),
      );

      expect(session.appSwitchViolations, equals(2));
      expect(session.violationTimestamps.length, equals(2));
      expect(session.violationTimestamps.first, contains('Lần 1'));
    });

    test('13. Serialization của ExamSessionResult bảo toàn dữ liệu nhật ký', () {
      final session = ExamSessionResult(
        roomId: 'EXAM200',
        studentName: 'Lê Thị C',
        score: 10,
        totalQuestions: 10,
        timeSpentSeconds: 300,
        appSwitchViolations: 0,
        violationTimestamps: const [],
        submittedAt: DateTime(2026, 6, 1, 10, 30),
      );

      final map = session.toMap();
      final restored = ExamSessionResult.fromMap(map);

      expect(restored.roomId, equals(session.roomId));
      expect(restored.score, equals(session.score));
      expect(restored.scoreOnScale10, equals(10.0));
    });

    test('14. Khởi tạo ExamRoom với danh sách câu hỏi và thời gian quy định', () {
      final room = ExamRoom(
        id: 'EXAM888',
        title: 'Kiểm tra 15 phút IT',
        creatorName: 'Giảng viên',
        durationMinutes: 15,
        questions: const [],
        createdAt: DateTime.now(),
      );

      expect(room.id, equals('EXAM888'));
      expect(room.durationMinutes, equals(15));
      expect(room.questions, isEmpty);
    });
  });
}
