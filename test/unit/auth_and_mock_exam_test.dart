import 'package:flutter_test/flutter_test.dart';
import 'package:edumaster/domain/entities/auth_user.dart';
import 'package:edumaster/domain/entities/quiz_question.dart';

void main() {
  group('Xác thực tài khoản Auth (Unit Tests - User Auth)', () {
    test('31. AuthUser toMap và fromMap bảo toàn toàn bộ dữ liệu', () {
      final now = DateTime(2026, 11, 16, 8, 30);
      final user = AuthUser(
        id: 'u_100',
        name: 'Nguyễn Văn A',
        email: 'test@edumaster.edu.vn',
        password: 'password123',
        group: 'Khối 12 - Ôn thi KTHP',
        createdAt: now,
      );

      final map = user.toMap();
      final reconstructed = AuthUser.fromMap(map);

      expect(reconstructed.id, equals('u_100'));
      expect(reconstructed.name, equals('Nguyễn Văn A'));
      expect(reconstructed.email, equals('test@edumaster.edu.vn'));
      expect(reconstructed.password, equals('password123'));
      expect(reconstructed.group, equals('Khối 12 - Ôn thi KTHP'));
    });

    test('32. AuthUser copyWith cập nhật chính xác các trường', () {
      final user = AuthUser(
        id: 'u_100',
        name: 'Nguyễn Văn A',
        email: 'test@edumaster.edu.vn',
        password: 'password123',
        group: 'Khối 12',
        createdAt: DateTime.now(),
      );

      final updated = user.copyWith(name: 'Trần Văn B', group: 'Sinh viên CNTT');
      expect(updated.name, equals('Trần Văn B'));
      expect(updated.group, equals('Sinh viên CNTT'));
      expect(updated.email, equals(user.email));
      expect(updated.password, equals(user.password));
    });
  });

  group('Bộ lọc Thi thử tính giờ 50 câu / 60 phút (Unit Tests - Mock Exam Filter)', () {
    test('33. Lọc danh sách câu hỏi theo Khối chính xác', () {
      final questions = List.generate(
        100,
        (i) => QuizQuestion(
          id: i + 1,
          grade: (i % 20) + 1, // Khối 1..20
          category: 'Khối ${(i % 20) + 1}',
          questionVi: 'Câu hỏi số ${i + 1}?',
          questionEn: 'Question number ${i + 1}?',
          optionsVi: ['A', 'B', 'C', 'D'],
          optionsEn: ['A', 'B', 'C', 'D'],
          correctIndex: i % 4,
          explanationVi: 'Giải thích ${i + 1}',
          explanationEn: 'Explanation ${i + 1}',
        ),
      );

      // Lọc theo Khối 1
      final grade1List = questions.where((q) => q.grade == 1).toList();
      expect(grade1List.length, equals(5));
      for (final q in grade1List) {
        expect(q.grade, equals(1));
      }

      // Lấy toàn bộ 50 câu từ danh sách
      final exam50 = (List<QuizQuestion>.from(questions)..shuffle()).take(50).toList();
      expect(exam50.length, equals(50));
    });

    test('34. Định dạng thời gian thi 60 phút (3600s) đúng chuẩn hh:mm:ss', () {
      String formatTimer(int seconds) {
        final h = seconds ~/ 3600;
        final m = (seconds % 3600) ~/ 60;
        final s = seconds % 60;
        if (h > 0) {
          return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
        }
        return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
      }

      expect(formatTimer(3600), equals('01:00:00')); // 60 phút chuẩn
      expect(formatTimer(3599), equals('59:59'));
      expect(formatTimer(2700), equals('45:00')); // 45 phút
      expect(formatTimer(1800), equals('30:00')); // 30 phút
      expect(formatTimer(120), equals('02:00'));
    });
  });
}
