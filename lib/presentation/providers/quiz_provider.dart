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
  List<QuizQuestion> _activeQuestions = [];
  List<QuizQuestion> get activeQuestions => _activeQuestions;

  int _selectedGrade = 0; // 0: All, 8: Grade 8, 11: Grade 11, 12: Grade 12
  int get selectedGrade => _selectedGrade;

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
          // Shuffle and limit to 20 questions for mock exam
          _activeQuestions.shuffle();
          if (_activeQuestions.length > 20) {
            _activeQuestions = _activeQuestions.sublist(0, 20);
          }
          _startTimer(20 * 60); // 20 minutes
        }
        _state = QuizUiState.success;
      }
    } catch (e) {
      _state = QuizUiState.error;
      _errorMessage = 'Không thể nạp danh sách câu hỏi: ${e.toString()}';
    }
    notifyListeners();
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

    final question = _activeQuestions[_currentIndex];
    if (optionIndex == question.correctIndex) {
      // Correct: remove from wrong set if it was in wrong list
      _quizRepo.removeWrongQuestionId(question.id);
    } else {
      // Wrong: remember ID for "Làm lại câu sai"
      _quizRepo.saveWrongQuestionId(question.id);
    }
    notifyListeners();
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
      if (_userAnswers[i] == _activeQuestions[i].correctIndex) {
        count++;
      }
    }
    _score = count;
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
