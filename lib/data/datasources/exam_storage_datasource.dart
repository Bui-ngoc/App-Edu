import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/exam.dart';

class ExamStorageDataSource {
  static const String _globalRoomsKey = 'edumaster_global_exam_rooms_v7';
  static const String _resultsKeyPrefix = 'edumaster_exam_results_';
  static const String _historyKeyPrefix = 'edumaster_exam_history_';
  static const String _liveKeyPrefix = 'edumaster_live_sessions_';

  String _userId = 'default';

  SharedPreferences? _prefs;

  // In-memory caches to eliminate disk I/O lag during frequent reads/polling
  List<ExamRoom>? _cachedGlobalRooms;
  final Map<String, List<ExamSessionResult>> _cachedResults = {};
  final Map<String, List<StudentExamHistoryEntry>> _cachedHistory = {};
  final Map<String, List<LiveStudentSession>> _cachedLiveSessions = {};

  void switchUser(String userId) {
    final cleanId = userId.trim().toLowerCase();
    final newId = cleanId.isEmpty ? 'default' : cleanId;
    if (_userId != newId) {
      _userId = newId;
      _cachedGlobalRooms = null;
      _cachedResults.clear();
      _cachedHistory.clear();
      _cachedLiveSessions.clear();
    }
  }

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Get ALL created exam rooms in global registry
  Future<List<ExamRoom>> getGlobalRooms() async {
    if (_cachedGlobalRooms != null) return _cachedGlobalRooms!;

    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_globalRoomsKey);
    List<ExamRoom> rooms = [];

    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(jsonStr);
        rooms = list.map((e) => ExamRoom.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      } catch (_) {}
    }

    _cachedGlobalRooms = rooms;
    return rooms;
  }

  /// Get created exam rooms for a specific teacher ID or current user
  Future<List<ExamRoom>> getRooms() async {
    final allRooms = await getGlobalRooms();
    final cleanUser = _userId.trim().toLowerCase();

    return allRooms.where((r) =>
      r.creatorId.trim().toLowerCase() == cleanUser ||
      r.creatorName.trim().toLowerCase() == cleanUser ||
      r.id.toLowerCase().contains(cleanUser)
    ).toList();
  }

  Future<void> saveRoom(ExamRoom room) async {
    final rooms = await getGlobalRooms();
    final idx = rooms.indexWhere((r) => r.id.toUpperCase() == room.id.toUpperCase());
    if (idx >= 0) {
      rooms[idx] = room;
    } else {
      rooms.add(room);
    }
    _cachedGlobalRooms = rooms;

    final prefs = await _getPrefs();
    await prefs.setString(_globalRoomsKey, json.encode(rooms.map((r) => r.toMap()).toList()));
  }

  Future<ExamRoom?> getRoomById(String id) async {
    final rooms = await getGlobalRooms();
    try {
      return rooms.firstWhere((r) => r.id.toUpperCase() == id.trim().toUpperCase());
    } catch (_) {
      return null;
    }
  }

  Future<void> submitResult(ExamSessionResult result) async {
    final roomKey = result.roomId.toUpperCase();
    final results = await getResultsForRoom(roomKey);
    results.add(result);
    _cachedResults[roomKey] = results;

    final prefs = await _getPrefs();
    final key = '$_resultsKeyPrefix$roomKey';
    await prefs.setString(key, json.encode(results.map((e) => e.toMap()).toList()));
  }

  Future<List<ExamSessionResult>> getResultsForRoom(String roomId) async {
    final roomKey = roomId.toUpperCase();
    if (_cachedResults.containsKey(roomKey)) {
      return _cachedResults[roomKey]!;
    }

    final prefs = await _getPrefs();
    final key = '$_resultsKeyPrefix$roomKey';
    final jsonStr = prefs.getString(key);
    if (jsonStr == null || jsonStr.isEmpty) {
      _cachedResults[roomKey] = [];
      return [];
    }
    try {
      final List<dynamic> list = json.decode(jsonStr);
      final resList = list.map((e) => ExamSessionResult.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      _cachedResults[roomKey] = resList;
      return resList;
    } catch (_) {
      _cachedResults[roomKey] = [];
      return [];
    }
  }

  // ── Student Exam History ──────────────────────────────────────────────────

  Future<void> addStudentHistory(String userId, StudentExamHistoryEntry entry) async {
    final userKey = userId.replaceAll('@', '_').replaceAll('.', '_').toLowerCase();
    final history = await getStudentHistory(userId);
    history.insert(0, entry);
    _cachedHistory[userKey] = history;

    final prefs = await _getPrefs();
    final key = '$_historyKeyPrefix$userKey';
    await prefs.setString(key, json.encode(history.map((e) => e.toMap()).toList()));
  }

  Future<List<StudentExamHistoryEntry>> getStudentHistory(String userId) async {
    final userKey = userId.replaceAll('@', '_').replaceAll('.', '_').toLowerCase();
    if (_cachedHistory.containsKey(userKey)) {
      return _cachedHistory[userKey]!;
    }

    final prefs = await _getPrefs();
    final key = '$_historyKeyPrefix$userKey';
    final jsonStr = prefs.getString(key);
    if (jsonStr == null || jsonStr.isEmpty) {
      _cachedHistory[userKey] = [];
      return [];
    }
    try {
      final List<dynamic> list = json.decode(jsonStr);
      final entries = list
          .map((e) => StudentExamHistoryEntry.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      entries.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      _cachedHistory[userKey] = entries;
      return entries;
    } catch (_) {
      _cachedHistory[userKey] = [];
      return [];
    }
  }

  // ── Realtime Live Student Monitoring ──────────────────────────────────────

  Future<void> saveLiveSession(LiveStudentSession session) async {
    final roomKey = session.roomId.toUpperCase();
    final sessions = await getLiveSessions(roomKey);

    final idx = sessions.indexWhere((s) => s.studentName == session.studentName);
    if (idx >= 0) {
      sessions[idx] = session;
    } else {
      sessions.add(session);
    }
    _cachedLiveSessions[roomKey] = sessions;

    final prefs = await _getPrefs();
    final key = '$_liveKeyPrefix$roomKey';
    await prefs.setString(key, json.encode(sessions.map((s) => s.toMap()).toList()));
  }

  Future<List<LiveStudentSession>> getLiveSessions(String roomId) async {
    final roomKey = roomId.toUpperCase();
    if (_cachedLiveSessions.containsKey(roomKey)) {
      return _cachedLiveSessions[roomKey]!;
    }

    final prefs = await _getPrefs();
    final key = '$_liveKeyPrefix$roomKey';
    final jsonStr = prefs.getString(key);
    if (jsonStr == null || jsonStr.isEmpty) {
      _cachedLiveSessions[roomKey] = [];
      return [];
    }
    try {
      final List<dynamic> list = json.decode(jsonStr);
      final listRes = list.map((e) => LiveStudentSession.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      _cachedLiveSessions[roomKey] = listRes;
      return listRes;
    } catch (_) {
      _cachedLiveSessions[roomKey] = [];
      return [];
    }
  }
}
