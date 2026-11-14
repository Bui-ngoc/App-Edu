import 'quiz_question.dart';

class ExamRoom {
  final String id; // Exam PIN / Room ID (e.g. "EXAM892")
  final String title;
  final String creatorName; // Teacher
  final int durationMinutes;
  final List<QuizQuestion> questions;
  final DateTime createdAt;

  const ExamRoom({
    required this.id,
    required this.title,
    required this.creatorName,
    required this.durationMinutes,
    required this.questions,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'creatorName': creatorName,
      'durationMinutes': durationMinutes,
      'questions': questions.map((q) => q.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ExamRoom.fromMap(Map<String, dynamic> map) {
    return ExamRoom(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Phòng thi trực tuyến',
      creatorName: map['creatorName']?.toString() ?? 'Giảng viên',
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 15,
      questions: (map['questions'] as List<dynamic>?)
              ?.map((e) => QuizQuestion.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ExamSessionResult {
  final String roomId;
  final String studentName;
  final int score;
  final int totalQuestions;
  final int timeSpentSeconds;
  final int appSwitchViolations; // Number of times student left app during exam
  final List<String> violationTimestamps;
  final DateTime submittedAt;

  const ExamSessionResult({
    required this.roomId,
    required this.studentName,
    required this.score,
    required this.totalQuestions,
    required this.timeSpentSeconds,
    required this.appSwitchViolations,
    required this.violationTimestamps,
    required this.submittedAt,
  });

  double get percentage => totalQuestions > 0 ? (score / totalQuestions) * 100 : 0.0;
  double get scoreOnScale10 => totalQuestions > 0 ? (score / totalQuestions) * 10.0 : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'studentName': studentName,
      'score': score,
      'totalQuestions': totalQuestions,
      'timeSpentSeconds': timeSpentSeconds,
      'appSwitchViolations': appSwitchViolations,
      'violationTimestamps': violationTimestamps,
      'submittedAt': submittedAt.toIso8601String(),
    };
  }

  factory ExamSessionResult.fromMap(Map<String, dynamic> map) {
    return ExamSessionResult(
      roomId: map['roomId']?.toString() ?? '',
      studentName: map['studentName']?.toString() ?? 'Sinh viên',
      score: (map['score'] as num?)?.toInt() ?? 0,
      totalQuestions: (map['totalQuestions'] as num?)?.toInt() ?? 0,
      timeSpentSeconds: (map['timeSpentSeconds'] as num?)?.toInt() ?? 0,
      appSwitchViolations: (map['appSwitchViolations'] as num?)?.toInt() ?? 0,
      violationTimestamps: (map['violationTimestamps'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      submittedAt: map['submittedAt'] != null
          ? DateTime.tryParse(map['submittedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
