class QuizQuestion {
  final int id;
  final int grade; // 8, 11, 12
  final String category;
  final String questionVi;
  final String questionEn;
  final List<String> optionsVi;
  final List<String> optionsEn;
  final int correctIndex;
  final String explanationVi;
  final String explanationEn;

  const QuizQuestion({
    required this.id,
    required this.grade,
    required this.category,
    required this.questionVi,
    required this.questionEn,
    required this.optionsVi,
    required this.optionsEn,
    required this.correctIndex,
    required this.explanationVi,
    required this.explanationEn,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    int parseId(dynamic val) {
      if (val is num) return val.toInt();
      return int.tryParse(val?.toString() ?? '') ?? 0;
    }

    int parseGrade(dynamic val) {
      if (val is num) return val.toInt();
      return int.tryParse(val?.toString() ?? '') ?? 12;
    }

    int parseCorrect(dynamic val) {
      if (val is num) return val.toInt();
      return int.tryParse(val?.toString() ?? '') ?? 0;
    }

    return QuizQuestion(
      id: parseId(map['id']),
      grade: parseGrade(map['grade']),
      category: map['category']?.toString() ?? 'Chung',
      questionVi: map['question_vi']?.toString() ?? '',
      questionEn: map['question_en']?.toString() ?? '',
      optionsVi: (map['options_vi'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      optionsEn: (map['options_en'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      correctIndex: parseCorrect(map['correct_index']),
      explanationVi: map['explanation_vi']?.toString() ?? '',
      explanationEn: map['explanation_en']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'grade': grade,
      'category': category,
      'question_vi': questionVi,
      'question_en': questionEn,
      'options_vi': optionsVi,
      'options_en': optionsEn,
      'correct_index': correctIndex,
      'explanation_vi': explanationVi,
      'explanation_en': explanationEn,
    };
  }
}
