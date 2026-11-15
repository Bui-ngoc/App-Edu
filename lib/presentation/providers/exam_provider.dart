import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/exam.dart';
import '../../domain/entities/quiz_question.dart';
import '../../domain/repositories/interfaces.dart';

enum ExamUiState { initial, loading, inRoom, finished, error }

class ExamProvider extends ChangeNotifier with WidgetsBindingObserver {
  final IExamRepository _examRepo;
  final ILeaderboardRepository _leaderboardRepo;

  ExamProvider({
    required IExamRepository examRepo,
    required ILeaderboardRepository leaderboardRepo,
  })  : _examRepo = examRepo,
        _leaderboardRepo = leaderboardRepo {
    WidgetsBinding.instance.addObserver(this);
  }

  ExamUiState _state = ExamUiState.initial;
  ExamUiState get state => _state;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  List<ExamRoom> _availableRooms = [];
  List<ExamRoom> get availableRooms => _availableRooms;

  ExamRoom? _activeRoom;
  ExamRoom? get activeRoom => _activeRoom;

  List<QuizQuestion> _shuffledQuestions = [];
  List<QuizQuestion> get shuffledQuestions => _shuffledQuestions;

  // Student answers mapping: questionIndex -> chosen option index
  final Map<int, int> _answers = {};
  Map<int, int> get answers => _answers;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  // Timer
  Timer? _timer;
  int _secondsLeft = 0;
  int get secondsLeft => _secondsLeft;

  // Anti-cheat tracking
  int _appSwitchCount = 0;
  int get appSwitchCount => _appSwitchCount;
  final List<String> _violationTimestamps = [];
  List<String> get violationTimestamps => _violationTimestamps;
  bool _cheatWarningShown = false;
  bool get cheatWarningShown => _cheatWarningShown;

  ExamSessionResult? _lastResult;
  ExamSessionResult? get lastResult => _lastResult;

  Future<void> loadRooms() async {
    _state = ExamUiState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      _availableRooms = await _examRepo.getAvailableRooms();
      _state = ExamUiState.initial;
    } catch (e) {
      _state = ExamUiState.error;
      _errorMessage = 'Lỗi nạp danh sách phòng thi: ${e.toString()}';
    }
    notifyListeners();
  }

  Future<List<ExamSessionResult>> getRoomResults(String roomId) async {
    return _examRepo.getResultsForRoom(roomId);
  }

  Future<bool> joinRoom(String roomId) async {
    _state = ExamUiState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final room = await _examRepo.getRoomById(roomId);
      if (room == null) {
        _state = ExamUiState.error;
        _errorMessage = 'Không tìm thấy phòng thi với mã PIN "$roomId". Vui lòng kiểm tra lại!';
        notifyListeners();
        return false;
      }

      _activeRoom = room;
      _appSwitchCount = 0;
      _violationTimestamps.clear();
      _cheatWarningShown = false;
      _answers.clear();
      _currentIndex = 0;

      // Shuffle questions & options for each individual student (Topic #34 Extension)
      _shuffledQuestions = List.from(room.questions)..shuffle();
      for (int i = 0; i < _shuffledQuestions.length; i++) {
        final q = _shuffledQuestions[i];
        final indices = [0, 1, 2, 3]..shuffle();
        final newOptsVi = indices.map((idx) => q.optionsVi[idx]).toList();
        final newOptsEn = indices.map((idx) => q.optionsEn[idx]).toList();
        final newCorrect = indices.indexOf(q.correctIndex);

        _shuffledQuestions[i] = QuizQuestion(
          id: q.id,
          grade: q.grade,
          category: q.category,
          questionVi: q.questionVi,
          questionEn: q.questionEn,
          optionsVi: newOptsVi,
          optionsEn: newOptsEn,
          correctIndex: newCorrect,
          explanationVi: q.explanationVi,
          explanationEn: q.explanationEn,
        );
      }

      _secondsLeft = room.durationMinutes * 60;
      _startExamTimer();
      _state = ExamUiState.inRoom;
      notifyListeners();
      return true;
    } catch (e) {
      _state = ExamUiState.error;
      _errorMessage = 'Lỗi vào phòng thi: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  void _startExamTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        _secondsLeft--;
        notifyListeners();
      } else {
        timer.cancel();
        submitExam();
      }
    });
  }

  void selectAnswer(int optionIndex) {
    if (_state != ExamUiState.inRoom) return;
    _answers[_currentIndex] = optionIndex;
    notifyListeners();
  }

  void goToQuestion(int index) {
    if (index >= 0 && index < _shuffledQuestions.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void dismissCheatWarning() {
    _cheatWarningShown = false;
    notifyListeners();
  }

  /// Auto-grading and submission
  Future<void> submitExam() async {
    _timer?.cancel();
    if (_activeRoom == null) return;

    int correct = 0;
    for (int i = 0; i < _shuffledQuestions.length; i++) {
      if (_answers[i] == _shuffledQuestions[i].correctIndex) {
        correct++;
      }
    }

    final profile = await _leaderboardRepo.getUserProfile();
    final timeSpent = (_activeRoom!.durationMinutes * 60) - _secondsLeft;

    _lastResult = ExamSessionResult(
      roomId: _activeRoom!.id,
      studentName: profile.name,
      score: correct,
      totalQuestions: _shuffledQuestions.length,
      timeSpentSeconds: timeSpent > 0 ? timeSpent : 0,
      appSwitchViolations: _appSwitchCount,
      violationTimestamps: List.from(_violationTimestamps),
      submittedAt: DateTime.now(),
    );

    await _examRepo.submitResult(_lastResult!);
    // Award XP
    final earnedXp = (correct * 20) + 50;
    await _leaderboardRepo.updateXp(profile.uid, earnedXp);

    _state = ExamUiState.finished;
    notifyListeners();
  }

  Future<void> createNewRoom({
    required String roomId,
    required String title,
    required String teacherName,
    required int durationMinutes,
    required List<QuizQuestion> questions,
  }) async {
    final room = ExamRoom(
      id: roomId.trim().toUpperCase(),
      title: title.trim(),
      creatorName: teacherName.trim(),
      durationMinutes: durationMinutes,
      questions: questions,
      createdAt: DateTime.now(),
    );
    await _examRepo.createRoom(room);
    await loadRooms();
  }

  // Anti-cheat lifecycle detection: student minimizes or switches away from app
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_state == ExamUiState.inRoom) {
      if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
        _appSwitchCount++;
        final now = DateTime.now();
        final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
        _violationTimestamps.add('Rời màn hình thi lúc $timeStr (Lần $_appSwitchCount)');
        _cheatWarningShown = true;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }
}
