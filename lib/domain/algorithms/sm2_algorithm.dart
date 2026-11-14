class SM2State {
  final int repetition;
  final int interval; // in days
  final double easeFactor;
  final DateTime nextReviewDate;

  const SM2State({
    required this.repetition,
    required this.interval,
    required this.easeFactor,
    required this.nextReviewDate,
  });

  factory SM2State.initial() {
    return SM2State(
      repetition: 0,
      interval: 0,
      easeFactor: 2.5,
      nextReviewDate: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'repetition': repetition,
      'interval': interval,
      'easeFactor': easeFactor,
      'nextReviewDate': nextReviewDate.toIso8601String(),
    };
  }

  factory SM2State.fromMap(Map<String, dynamic> map) {
    return SM2State(
      repetition: (map['repetition'] as num?)?.toInt() ?? 0,
      interval: (map['interval'] as num?)?.toInt() ?? 0,
      easeFactor: (map['easeFactor'] as num?)?.toDouble() ?? 2.5,
      nextReviewDate: map['nextReviewDate'] != null
          ? DateTime.tryParse(map['nextReviewDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Pure implementation of SuperMemo SM-2 Spaced Repetition Algorithm
class SM2Algorithm {
  /// Calculate next SM2 schedule based on current state and user recall rating (0 to 5)
  /// Quality scale:
  /// 5: Perfect recall
  /// 4: Correct response after a hesitation
  /// 3: Correct response recalled with serious difficulty
  /// 2: Incorrect response; where the correct one seemed easy to recall
  /// 1: Incorrect response; the correct one remembered
  /// 0: Complete blackout
  static SM2State review({
    required int currentRepetition,
    required int currentInterval,
    required double currentEaseFactor,
    required int quality,
    DateTime? referenceDate,
  }) {
    assert(quality >= 0 && quality <= 5, 'Quality must be between 0 and 5');
    final baseDate = referenceDate ?? DateTime.now();

    int nextRepetition;
    int nextInterval;

    if (quality >= 3) {
      if (currentRepetition == 0) {
        nextInterval = 1;
      } else if (currentRepetition == 1) {
        nextInterval = 6;
      } else {
        nextInterval = (currentInterval * currentEaseFactor).round();
        if (nextInterval <= currentInterval) {
          nextInterval = currentInterval + 1;
        }
      }
      nextRepetition = currentRepetition + 1;
    } else {
      nextRepetition = 0;
      nextInterval = 1;
    }

    // Ease Factor calculation: EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
    final qDiff = 5 - quality;
    double nextEaseFactor = currentEaseFactor + (0.1 - qDiff * (0.08 + qDiff * 0.02));
    if (nextEaseFactor < 1.3) {
      nextEaseFactor = 1.3;
    }

    final nextReviewDate = baseDate.add(Duration(days: nextInterval));

    return SM2State(
      repetition: nextRepetition,
      interval: nextInterval,
      easeFactor: double.parse(nextEaseFactor.toStringAsFixed(3)),
      nextReviewDate: nextReviewDate,
    );
  }
}
