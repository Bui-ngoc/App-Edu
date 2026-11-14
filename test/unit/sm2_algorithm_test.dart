import 'package:flutter_test/flutter_test.dart';
import 'package:edumaster/domain/algorithms/sm2_algorithm.dart';

void main() {
  group('Thuật toán SuperMemo SM-2 (Pure Unit Tests - Topic #33)', () {
    test('1. Khởi tạo trạng thái mặc định SM2State', () {
      final state = SM2State.initial();
      expect(state.repetition, equals(0));
      expect(state.interval, equals(0));
      expect(state.easeFactor, equals(2.5));
    });

    test('2. Lần ôn tập thành công đầu tiên (Quality >= 3) đặt interval = 1 ngày, rep = 1', () {
      final now = DateTime(2026, 1, 1);
      final nextState = SM2Algorithm.review(
        currentRepetition: 0,
        currentInterval: 0,
        currentEaseFactor: 2.5,
        quality: 4,
        referenceDate: now,
      );

      expect(nextState.repetition, equals(1));
      expect(nextState.interval, equals(1));
      expect(nextState.nextReviewDate, equals(now.add(const Duration(days: 1))));
    });

    test('3. Lần ôn tập thành công thứ hai đặt interval = 6 ngày, rep = 2', () {
      final now = DateTime(2026, 1, 1);
      final nextState = SM2Algorithm.review(
        currentRepetition: 1,
        currentInterval: 1,
        currentEaseFactor: 2.5,
        quality: 5,
        referenceDate: now,
      );

      expect(nextState.repetition, equals(2));
      expect(nextState.interval, equals(6));
      expect(nextState.nextReviewDate, equals(now.add(const Duration(days: 6))));
    });

    test('4. Lần ôn tập thứ 3 trở đi nhân giãn cách theo hệ số Ease Factor', () {
      final nextState = SM2Algorithm.review(
        currentRepetition: 2,
        currentInterval: 6,
        currentEaseFactor: 2.5,
        quality: 5,
      );

      expect(nextState.repetition, equals(3));
      expect(nextState.interval, greaterThanOrEqualTo(15));
      expect(nextState.easeFactor, greaterThan(2.5)); // Quality 5 increases EF
    });

    test('5. Khi quên (Quality < 3), thuật toán reset repetition về 0 và interval về 1', () {
      final nextState = SM2Algorithm.review(
        currentRepetition: 4,
        currentInterval: 25,
        currentEaseFactor: 2.3,
        quality: 1, // Forgot
      );

      expect(nextState.repetition, equals(0));
      expect(nextState.interval, equals(1));
    });

    test('6. Hệ số Ease Factor không bao giờ giảm xuống dưới 1.3', () {
      var ef = 1.4;
      for (int i = 0; i < 5; i++) {
        final state = SM2Algorithm.review(
          currentRepetition: 1,
          currentInterval: 1,
          currentEaseFactor: ef,
          quality: 0, // Repeated severe failure
        );
        ef = state.easeFactor;
      }
      expect(ef, greaterThanOrEqualTo(1.3));
    });
  });
}
