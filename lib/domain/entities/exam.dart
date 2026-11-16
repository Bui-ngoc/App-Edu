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

/// Personal exam history entry stored per student (userId).
class StudentExamHistoryEntry {
  final String roomId;
  final String roomTitle;
  final String teacherName;
  final int score;
  final int totalQuestions;
  final int durationMinutes; // duration of the exam room
  final int timeSpentSeconds; // actual time the student used
  final DateTime submittedAt;

  const StudentExamHistoryEntry({
    required this.roomId,
    required this.roomTitle,
    required this.teacherName,
    required this.score,
    required this.totalQuestions,
    required this.durationMinutes,
    required this.timeSpentSeconds,
    required this.submittedAt,
  });

  double get percentage => totalQuestions > 0 ? (score / totalQuestions) * 100 : 0.0;

  Map<String, dynamic> toMap() => {
        'roomId': roomId,
        'roomTitle': roomTitle,
        'teacherName': teacherName,
        'score': score,
        'totalQuestions': totalQuestions,
        'durationMinutes': durationMinutes,
        'timeSpentSeconds': timeSpentSeconds,
        'submittedAt': submittedAt.toIso8601String(),
      };

  factory StudentExamHistoryEntry.fromMap(Map<String, dynamic> map) {
    return StudentExamHistoryEntry(
      roomId: map['roomId']?.toString() ?? '',
      roomTitle: map['roomTitle']?.toString() ?? 'Kỳ thi trực tuyến',
      teacherName: map['teacherName']?.toString() ?? 'Giảng viên',
      score: (map['score'] as num?)?.toInt() ?? 0,
      totalQuestions: (map['totalQuestions'] as num?)?.toInt() ?? 0,
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 0,
      timeSpentSeconds: (map['timeSpentSeconds'] as num?)?.toInt() ?? 0,
      submittedAt: map['submittedAt'] != null
          ? DateTime.tryParse(map['submittedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Live real-time student monitoring session used by Teachers during exams.
class LiveStudentSession {
  final String roomId;
  final String studentId;
  final String studentName;
  final int currentIndex; // Current question index (0-based)
  final int answeredCount; // Number of questions answered so far
  final int totalQuestions;
  final int currentCorrect; // Number of questions answered correctly so far
  final int appSwitchViolations; // Number of times student exited/switched app
  final List<String> violationTimestamps;
  final bool isFinished; // Submitted or still active
  final DateTime lastActiveAt;

  const LiveStudentSession({
    required this.roomId,
    required this.studentId,
    required this.studentName,
    required this.currentIndex,
    required this.answeredCount,
    required this.totalQuestions,
    required this.currentCorrect,
    required this.appSwitchViolations,
    required this.violationTimestamps,
    required this.isFinished,
    required this.lastActiveAt,
  });

  double get progressPercentage =>
      totalQuestions > 0 ? (answeredCount / totalQuestions) * 100 : 0.0;

  Map<String, dynamic> toMap() => {
        'roomId': roomId,
        'studentId': studentId,
        'studentName': studentName,
        'currentIndex': currentIndex,
        'answeredCount': answeredCount,
        'totalQuestions': totalQuestions,
        'currentCorrect': currentCorrect,
        'appSwitchViolations': appSwitchViolations,
        'violationTimestamps': violationTimestamps,
        'isFinished': isFinished,
        'lastActiveAt': lastActiveAt.toIso8601String(),
      };

  factory LiveStudentSession.fromMap(Map<String, dynamic> map) {
    return LiveStudentSession(
      roomId: map['roomId']?.toString() ?? '',
      studentId: map['studentId']?.toString() ?? '',
      studentName: map['studentName']?.toString() ?? 'Sinh viên',
      currentIndex: (map['currentIndex'] as num?)?.toInt() ?? 0,
      answeredCount: (map['answeredCount'] as num?)?.toInt() ?? 0,
      totalQuestions: (map['totalQuestions'] as num?)?.toInt() ?? 0,
      currentCorrect: (map['currentCorrect'] as num?)?.toInt() ?? 0,
      appSwitchViolations: (map['appSwitchViolations'] as num?)?.toInt() ?? 0,
      violationTimestamps: (map['violationTimestamps'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isFinished: map['isFinished'] == true,
      lastActiveAt: map['lastActiveAt'] != null
          ? DateTime.tryParse(map['lastActiveAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
