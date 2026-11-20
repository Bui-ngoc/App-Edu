import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/exam.dart';

/// Database Inspector Singleton Manager
/// Khởi tạo tập trung các bảng Cơ sở dữ liệu SQLite trong Android Studio Database Inspector
class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  static Database? _db;

  AppDatabase._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'edumaster_app.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _createTables(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    // 1. Bảng Users (Tài khoản người dùng)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        group_name TEXT DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');

    // 2. Bảng User Profiles (Hồ sơ cá nhân & EXP)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_profiles (
        uid TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        local_avatar_path TEXT,
        total_xp INTEGER DEFAULT 0,
        streak_days INTEGER DEFAULT 0,
        badges_json TEXT DEFAULT '[]',
        current_group TEXT DEFAULT ''
      )
    ''');

    // 3. Bảng Exam Rooms (Phòng thi trực tuyến)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS exam_rooms (
        id TEXT PRIMARY KEY,
        room_code TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL,
        creator_id TEXT NOT NULL,
        creator_name TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        questions_json TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 4. Bảng Study Groups (Bảng Quản lý Nhóm học tập cho Giáo viên)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS study_groups (
        group_name TEXT PRIMARY KEY,
        creator_id TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 5. Bảng Exam Results (Báo cáo điểm số sinh viên)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS exam_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        room_id TEXT NOT NULL,
        student_name TEXT NOT NULL,
        score INTEGER NOT NULL,
        total_questions INTEGER NOT NULL,
        time_spent_seconds INTEGER NOT NULL,
        violations_count INTEGER DEFAULT 0,
        timestamps_json TEXT DEFAULT '[]',
        submitted_at TEXT NOT NULL
      )
    ''');

    // 6. Bảng Student Exam History (Lịch sử làm bài thi)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS student_exam_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        room_id TEXT NOT NULL,
        room_title TEXT NOT NULL,
        teacher_name TEXT NOT NULL,
        score INTEGER NOT NULL,
        total_questions INTEGER NOT NULL,
        duration_minutes INTEGER NOT NULL,
        time_spent_seconds INTEGER NOT NULL,
        submitted_at TEXT NOT NULL
      )
    ''');

    // 7. Bảng Wrong Questions (Lịch sử câu sai)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS wrong_questions (
        user_id TEXT NOT NULL,
        question_id INTEGER NOT NULL,
        PRIMARY KEY (user_id, question_id)
      )
    ''');

    // 8. Bảng Live Student Sessions (Giám sát thời gian thực)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS live_student_sessions (
        id TEXT PRIMARY KEY,
        room_id TEXT NOT NULL,
        student_id TEXT NOT NULL,
        student_name TEXT NOT NULL,
        current_index INTEGER DEFAULT 0,
        answered_count INTEGER DEFAULT 0,
        total_questions INTEGER DEFAULT 0,
        current_correct INTEGER DEFAULT 0,
        app_switch_violations INTEGER DEFAULT 0,
        timestamps_json TEXT DEFAULT '[]',
        is_finished INTEGER DEFAULT 0,
        last_active_at TEXT NOT NULL
      )
    ''');
  }

  /// Clear ALL SQLite tables for 100% brand new fresh state
  Future<void> clearAllTables() async {
    final db = await database;
    final batch = db.batch();
    batch.delete('users');
    batch.delete('user_profiles');
    batch.delete('exam_rooms');
    batch.delete('study_groups');
    batch.delete('exam_results');
    batch.delete('student_exam_history');
    batch.delete('wrong_questions');
    batch.delete('live_student_sessions');
    await batch.commit(noResult: true);
  }

  // ── Helper Insert/Update Methods for Database Inspector Visibility ──────

  Future<void> insertUser(AuthUser user) async {
    final db = await database;
    await db.insert(
      'users',
      {
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'password': user.password,
        'role': user.role,
        'group_name': user.group,
        'created_at': user.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertUserProfile(UserProfile profile) async {
    final db = await database;
    await db.insert(
      'user_profiles',
      {
        'uid': profile.uid,
        'name': profile.name,
        'email': profile.email,
        'local_avatar_path': profile.localAvatarPath,
        'total_xp': profile.totalXp,
        'streak_days': profile.streakDays,
        'badges_json': json.encode(profile.badges),
        'current_group': profile.currentGroup,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertExamRoom(ExamRoom room) async {
    final db = await database;
    await db.insert(
      'exam_rooms',
      {
        'id': room.id,
        'room_code': room.id.toUpperCase(),
        'title': room.title,
        'creator_id': room.creatorId,
        'creator_name': room.creatorName,
        'duration_minutes': room.durationMinutes,
        'questions_json': json.encode(room.questions.map((q) => q.toMap()).toList()),
        'created_at': room.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertStudyGroup(String groupName, String creatorId) async {
    final db = await database;
    await db.insert(
      'study_groups',
      {
        'group_name': groupName.trim(),
        'creator_id': creatorId.trim(),
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertExamResult(ExamSessionResult result) async {
    final db = await database;
    await db.insert(
      'exam_results',
      {
        'room_id': result.roomId,
        'student_name': result.studentName,
        'score': result.score,
        'total_questions': result.totalQuestions,
        'time_spent_seconds': result.timeSpentSeconds,
        'violations_count': result.appSwitchViolations,
        'timestamps_json': json.encode(result.violationTimestamps),
        'submitted_at': result.submittedAt.toIso8601String(),
      },
    );
  }

  Future<void> insertExamHistory({
    required String userId,
    required String userName,
    required String roomCode,
    required String examTitle,
    required int score,
    required int correctAnswers,
    required int totalQuestions,
  }) async {
    final db = await database;
    await db.insert(
      'student_exam_history',
      {
        'user_id': userId,
        'room_id': roomCode,
        'room_title': examTitle,
        'teacher_name': userName,
        'score': score,
        'total_questions': totalQuestions,
        'duration_minutes': 15,
        'time_spent_seconds': 300,
        'submitted_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> insertWrongQuestion(String userId, int questionId) async {
    final db = await database;
    await db.insert(
      'wrong_questions',
      {
        'user_id': userId,
        'question_id': questionId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertLiveSession(LiveStudentSession session) async {
    final db = await database;
    await db.insert(
      'live_student_sessions',
      {
        'id': '${session.roomId}_${session.studentId}',
        'room_id': session.roomId,
        'student_id': session.studentId,
        'student_name': session.studentName,
        'current_index': session.currentIndex,
        'answered_count': session.answeredCount,
        'total_questions': session.totalQuestions,
        'current_correct': session.currentCorrect,
        'app_switch_violations': session.appSwitchViolations,
        'timestamps_json': json.encode(session.violationTimestamps),
        'is_finished': session.isFinished ? 1 : 0,
        'last_active_at': session.lastActiveAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
