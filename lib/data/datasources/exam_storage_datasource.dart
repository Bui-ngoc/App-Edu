import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/exam.dart';

class ExamStorageDataSource {
  static const String _roomsKey = 'edumaster_exam_rooms';
  static const String _resultsKeyPrefix = 'edumaster_exam_results_';
  static const String _historyKeyPrefix = 'edumaster_exam_history_';

  Future<List<ExamRoom>> getRooms() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_roomsKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
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
    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> list = json.decode(jsonStr);
      return list.map((e) => ExamSessionResult.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Student Exam History ──────────────────────────────────────────────────

  Future<void> addStudentHistory(String userId, StudentExamHistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_historyKeyPrefix${userId.replaceAll('@', '_').replaceAll('.', '_')}';
    final existing = prefs.getString(key);
    List<dynamic> list = [];
    if (existing != null && existing.isNotEmpty) {
      try {
        list = json.decode(existing) as List<dynamic>;
      } catch (_) {}
    }
    list.add(entry.toMap());
    await prefs.setString(key, json.encode(list));
  }

  Future<List<StudentExamHistoryEntry>> getStudentHistory(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_historyKeyPrefix${userId.replaceAll('@', '_').replaceAll('.', '_')}';
    final jsonStr = prefs.getString(key);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> list = json.decode(jsonStr);
      final entries = list
          .map((e) => StudentExamHistoryEntry.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      // Sort newest first
      entries.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return entries;
    } catch (_) {
      return [];
    }
  }

  // ── Realtime Live Student Monitoring ──────────────────────────────────────
  static const String _liveKeyPrefix = 'edumaster_live_sessions_';

  Future<void> saveLiveSession(LiveStudentSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_liveKeyPrefix${session.roomId.toUpperCase()}';
    final jsonStr = prefs.getString(key);
    List<LiveStudentSession> sessions = [];
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(jsonStr);
        sessions = list.map((e) => LiveStudentSession.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      } catch (_) {}
    }
    final idx = sessions.indexWhere((s) => s.studentName == session.studentName);
    if (idx >= 0) {
      sessions[idx] = session;
    } else {
      sessions.add(session);
    }
    await prefs.setString(key, json.encode(sessions.map((s) => s.toMap()).toList()));
  }

  Future<List<LiveStudentSession>> getLiveSessions(String roomId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_liveKeyPrefix${roomId.toUpperCase()}';
    final jsonStr = prefs.getString(key);
    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> list = json.decode(jsonStr);
      return list.map((e) => LiveStudentSession.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }
}
