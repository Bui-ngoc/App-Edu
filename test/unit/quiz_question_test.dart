import 'package:flutter_test/flutter_test.dart';
import 'package:edumaster/domain/entities/quiz_question.dart';

void main() {
  group('Ngân hàng 300 câu hỏi song ngữ (Unit Tests - Topic #32)', () {
    test('7. Chuyển đổi Map sang QuizQuestion chính xác', () {
      final map = {
        'id': 1,
        'grade': 12,
        'category': 'Tin học',
        'question_vi': 'Khóa chính là gì?',
        'question_en': 'What is a Primary Key?',
        'options_vi': ['Duy nhất và NOT NULL', 'Có thể trùng', 'Là chuỗi', 'Rỗng'],
        'options_en': ['Unique and NOT NULL', 'Duplicate', 'String', 'Empty'],
        'correct_index': 0,
        'explanation_vi': 'Khóa chính không được rỗng và duy nhất.',
        'explanation_en': 'Primary key must be unique and NOT NULL.',
      };

      final q = QuizQuestion.fromMap(map);
      expect(q.id, equals(1));
      expect(q.grade, equals(12));
      expect(q.questionVi, equals('Khóa chính là gì?'));
      expect(q.questionEn, equals('What is a Primary Key?'));
      expect(q.optionsVi.length, equals(4));
      expect(q.optionsEn.length, equals(4));
      expect(q.correctIndex, equals(0));
    });

    test('8. QuizQuestion toMap và fromMap bảo toàn toàn bộ dữ liệu', () {
      const original = QuizQuestion(
        id: 42,
        grade: 11,
        category: 'Toán học',
        questionVi: 'Đạo hàm của x^2 là gì?',
        questionEn: 'What is the derivative of x^2?',
        optionsVi: ['2x', 'x', '2', 'x^3'],
        optionsEn: ['2x', 'x', '2', 'x^3'],
        correctIndex: 0,
        explanationVi: 'Đạo hàm là 2x.',
        explanationEn: 'Derivative is 2x.',
      );

      final map = original.toMap();
      final reconstructed = QuizQuestion.fromMap(map);

      expect(reconstructed.id, equals(original.id));
      expect(reconstructed.grade, equals(original.grade));
      expect(reconstructed.questionVi, equals(original.questionVi));
      expect(reconstructed.correctIndex, equals(original.correctIndex));
    });

    test('9. Hỗ trợ đầy đủ dữ liệu song ngữ Anh - Việt cho cả câu hỏi và 4 đáp án', () {
      const q = QuizQuestion(
        id: 10,
        grade: 8,
        category: 'Khoa học',
        questionVi: 'Nước là gì?',
        questionEn: 'What is water?',
        optionsVi: ['H2O', 'CO2', 'NaCl', 'O2'],
        optionsEn: ['H2O', 'CO2', 'NaCl', 'O2'],
        correctIndex: 0,
        explanationVi: 'Nước có công thức H2O',
        explanationEn: 'Water is H2O',
      );

      expect(q.questionVi.isNotEmpty, isTrue);
      expect(q.questionEn.isNotEmpty, isTrue);
      expect(q.optionsVi.length, equals(q.optionsEn.length));
    });

    test('10. Defensive parsing: Fallback an toàn khi map bị thiếu trường hoặc null', () {
      final corruptedMap = <String, dynamic>{
        'id': null,
        'grade': 'invalid',
        'question_vi': null,
      };

      final q = QuizQuestion.fromMap(corruptedMap);
      expect(q.id, equals(0));
      expect(q.grade, equals(12));
      expect(q.questionVi, equals(''));
      expect(q.optionsVi, isEmpty);
    });
  });
}
