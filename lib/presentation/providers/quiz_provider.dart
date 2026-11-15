import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/quiz_question.dart';
import '../../domain/repositories/interfaces.dart';

enum QuizMode { practice, exam, wrongReview }
enum QuizUiState { initial, loading, success, error, empty }

class QuizProvider extends ChangeNotifier {
  final IQuizRepository _quizRepo;
  final IAiTutorRepository _aiRepo;

  QuizProvider({
    required IQuizRepository quizRepo,
    required IAiTutorRepository aiRepo,
  })  : _quizRepo = quizRepo,
        _aiRepo = aiRepo;

  QuizUiState _state = QuizUiState.initial;
  QuizUiState get state => _state;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  List<QuizQuestion> _allQuestions = [];
  List<QuizQuestion> get allQuestions => _allQuestions;
  List<QuizQuestion> _activeQuestions = [];
  List<QuizQuestion> get activeQuestions => _activeQuestions;

  int _selectedGrade = 0; // 0: All, 1..20
  int get selectedGrade => _selectedGrade;

  String _selectedDifficulty = 'all'; // 'all', 'easy', 'medium', 'hard'
  String get selectedDifficulty => _selectedDifficulty;

  int _examDurationMinutes = 60; // Standard 60 mins
  int get examDurationMinutes => _examDurationMinutes;

  int _examQuestionCount = 50; // Standard 50 questions
  int get examQuestionCount => _examQuestionCount;

  QuizMode _currentMode = QuizMode.practice;
  QuizMode get currentMode => _currentMode;

  bool _isEnglish = false; // Bilingual toggle (Topic #32 Extension)
  bool get isEnglish => _isEnglish;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  final Map<int, int> _userAnswers = {}; // questionIndex -> chosen option index
  Map<int, int> get userAnswers => _userAnswers;

  int _score = 0;
  int get score => _score;

  int _timeSpentSeconds = 0;
  int get timeSpentSeconds => _timeSpentSeconds;

  // Countdown timer for Exam mode (Topic #32 Extension)
  Timer? _countdownTimer;
  int _secondsRemaining = 0;
  int get secondsRemaining => _secondsRemaining;
  bool _isTimeUp = false;
  bool get isTimeUp => _isTimeUp;

  // AI explanation state
  bool _isExplaining = false;
  bool get isExplaining => _isExplaining;
  String _aiExplanation = '';
  String get aiExplanation => _aiExplanation;

  /// Standard Practice / Wrong Review load
  Future<void> loadQuestions({int grade = 0, QuizMode mode = QuizMode.practice}) async {
    _state = QuizUiState.loading;
    _errorMessage = '';
    _selectedGrade = grade;
    _currentMode = mode;
    _currentIndex = 0;
    _userAnswers.clear();
    _score = 0;
    _isTimeUp = false;
    _aiExplanation = '';
    _timeSpentSeconds = 0;
    notifyListeners();

    try {
      if (mode == QuizMode.wrongReview) {
        _activeQuestions = await _quizRepo.getWrongQuestions();
      } else if (grade > 0) {
        _activeQuestions = await _quizRepo.getQuestionsByGrade(grade);
      } else {
        _allQuestions = await _quizRepo.getAllQuestions();
        _activeQuestions = List.from(_allQuestions);
      }

      if (_activeQuestions.isEmpty) {
        _state = QuizUiState.empty;
      } else {
        if (mode == QuizMode.exam) {
          await startTimedExam(
            grade: grade,
            difficulty: 'all',
            questionCount: 50,
            durationMinutes: 60,
          );
          return;
        }
        _state = QuizUiState.success;
      }
    } catch (e) {
      _state = QuizUiState.error;
      _errorMessage = 'Không thể nạp danh sách câu hỏi: ${e.toString()}';
    }
    notifyListeners();
  }

  /// Full-featured Timed Exam with filters for Grade, Difficulty, Count and Duration
  Future<void> startTimedExam({
    int grade = 0,
    String difficulty = 'all',
    int questionCount = 50,
    int durationMinutes = 60,
  }) async {
    _state = QuizUiState.loading;
    _errorMessage = '';
    _selectedGrade = grade;
    _selectedDifficulty = difficulty;
    _examQuestionCount = questionCount;
    _examDurationMinutes = durationMinutes;
    _currentMode = QuizMode.exam;
    _currentIndex = 0;
    _userAnswers.clear();
    _score = 0;
    _isTimeUp = false;
    _aiExplanation = '';
    _timeSpentSeconds = 0;
    notifyListeners();

    try {
      _allQuestions = await _quizRepo.getAllQuestions();
      List<QuizQuestion> pool = List.from(_allQuestions);

      // 1. Filter by Grade if specified
      if (grade > 0) {
        pool = pool.where((q) => q.grade == grade).toList();
      }

      // 2. Filter by Difficulty if specified
      if (difficulty == 'easy') {
        pool = pool.where(_isEasyQuestion).toList();
      } else if (difficulty == 'medium') {
        pool = pool.where(_isMediumQuestion).toList();
      } else if (difficulty == 'hard') {
        pool = pool.where(_isHardQuestion).toList();
      }

      if (pool.isEmpty) {
        // Fallback to all questions if specific filter is too restrictive
        pool = List.from(_allQuestions);
      }

      // 3. Shuffle pool
      pool.shuffle();

      // 4. Limit to questionCount
      final actualCount = pool.length < questionCount ? pool.length : questionCount;
      _activeQuestions = pool.sublist(0, actualCount);

      if (_activeQuestions.isEmpty) {
        _state = QuizUiState.empty;
      } else {
        _startTimer(durationMinutes * 60);
        _state = QuizUiState.success;
      }
    } catch (e) {
      _state = QuizUiState.error;
      _errorMessage = 'Lỗi tạo đề thi thử: ${e.toString()}';
    }
    notifyListeners();
  }

  bool _isEasyQuestion(QuizQuestion q) {
    if (q.grade <= 5) return true;
    final text = q.questionVi.toLowerCase();
    return text.contains('là gì') ||
        text.contains('khái niệm') ||
        text.contains('đặc điểm') ||
        text.contains('cú pháp') ||
        text.contains('kiểu dữ liệu');
  }

  bool _isMediumQuestion(QuizQuestion q) {
    if (q.grade >= 6 && q.grade <= 12) return true;
    final text = q.questionVi.toLowerCase();
    return text.contains('sử dụng') ||
        text.contains('hoạt ảnh') ||
        text.contains('điều hướng') ||
        text.contains('trạng thái') ||
        text.contains('form');
  }

  bool _isHardQuestion(QuizQuestion q) {
    if (q.grade >= 13) return true;
    final text = q.questionVi.toLowerCase();
    return text.contains('kiến trúc') ||
        text.contains('clean') ||
        text.contains('hiệu năng') ||
        text.contains('tối ưu') ||
        text.contains('kiểm thử') ||
        text.contains('thuật toán') ||
        text.contains('sqlite') ||
        text.contains('stream') ||
        text.contains('ai');
  }

  void _startTimer(int totalSeconds) {
    _countdownTimer?.cancel();
    _secondsRemaining = totalSeconds;
    _isTimeUp = false;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        notifyListeners();
      } else {
        _isTimeUp = true;
        timer.cancel();
        calculateScore();
        notifyListeners();
      }
    });
  }

  void toggleLanguage() {
    _isEnglish = !_isEnglish;
    notifyListeners();
  }

  void selectAnswer(int optionIndex) {
    if (_isTimeUp) return;
    _userAnswers[_currentIndex] = optionIndex;
    _aiExplanation = '';

    // In practice mode, evaluate immediately
    if (_currentMode != QuizMode.exam) {
      final question = _activeQuestions[_currentIndex];
      if (optionIndex == question.correctIndex) {
        _quizRepo.removeWrongQuestionId(question.id);
      } else {
        _quizRepo.saveWrongQuestionId(question.id);
      }
    }
    notifyListeners();
  }

  void jumpToQuestion(int index) {
    if (index >= 0 && index < _activeQuestions.length) {
      _currentIndex = index;
      _aiExplanation = '';
      notifyListeners();
    }
  }

  void nextQuestion() {
    if (_currentIndex < _activeQuestions.length - 1) {
      _currentIndex++;
      _aiExplanation = '';
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _aiExplanation = '';
      notifyListeners();
    }
  }

  void calculateScore() {
    _countdownTimer?.cancel();
    int count = 0;
    for (int i = 0; i < _activeQuestions.length; i++) {
      final question = _activeQuestions[i];
      if (_userAnswers[i] == question.correctIndex) {
        count++;
        _quizRepo.removeWrongQuestionId(question.id);
      } else {
        _quizRepo.saveWrongQuestionId(question.id);
      }
    }
    _score = count;
    _timeSpentSeconds = (_examDurationMinutes * 60) - _secondsRemaining;
    if (_timeSpentSeconds < 0) _timeSpentSeconds = 0;
    notifyListeners();
  }

  Future<void> requestAiExplanation() async {
    final chosen = _userAnswers[_currentIndex];
    if (chosen == null) return;

    _isExplaining = true;
    _aiExplanation = '';
    notifyListeners();

    try {
      final res = await _aiRepo.explainWrongAnswer(
        question: _activeQuestions[_currentIndex],
        selectedIndex: chosen,
        isEnglish: _isEnglish,
      );
      _aiExplanation = res;
    } catch (e) {
      _aiExplanation = '💡 Lời giải tham khảo: ${_activeQuestions[_currentIndex].explanationVi}';
    } finally {
      _isExplaining = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
