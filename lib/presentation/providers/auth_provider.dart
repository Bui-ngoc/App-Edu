import 'package:flutter/material.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/interfaces.dart';
import '../../data/datasources/quiz_local_datasource.dart';
import '../../data/datasources/sm2_storage_datasource.dart';
import '../../data/datasources/exam_storage_datasource.dart';

class AuthProvider extends ChangeNotifier {
  final IAuthRepository _authRepo;
  final QuizLocalDataSource _quizDataSource;
  final Sm2StorageDataSource _sm2DataSource;
  final ExamStorageDataSource _examDataSource;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  AuthUser? _currentUser;
  AuthUser? get currentUser => _currentUser;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isPerformingAction = false;
  bool get isPerformingAction => _isPerformingAction;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  AuthProvider({
    required IAuthRepository authRepo,
    required QuizLocalDataSource quizDataSource,
    required Sm2StorageDataSource sm2DataSource,
    required ExamStorageDataSource examDataSource,
  })  : _authRepo = authRepo,
        _quizDataSource = quizDataSource,
        _sm2DataSource = sm2DataSource,
        _examDataSource = examDataSource {
    checkAuthStatus();
  }

  /// Thông báo đúng userId cho datasources để tách biệt dữ liệu giữa các user
  void _notifyDatasourcesUserChanged(String userId) {
    _quizDataSource.switchUser(userId);
    _sm2DataSource.switchUser(userId);
    _examDataSource.switchUser(userId);
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _isLoggedIn = await _authRepo.isLoggedIn();
      if (_isLoggedIn) {
        _currentUser = await _authRepo.getCurrentUser();
        if (_currentUser == null) {
          _isLoggedIn = false;
        } else {
          _notifyDatasourcesUserChanged(_currentUser!.id);
        }
      }
    } catch (e) {
      _isLoggedIn = false;
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isPerformingAction = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final user = await _authRepo.login(email: email, password: password);
      _currentUser = user;
      _isLoggedIn = true;
      _notifyDatasourcesUserChanged(user.id);
      _isPerformingAction = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isPerformingAction = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String role = 'student',
  }) async {
    _isPerformingAction = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final user = await _authRepo.register(
        name: name,
        email: email,
        password: password,
        role: role,
      );
      _currentUser = user;
      _isLoggedIn = true;
      _notifyDatasourcesUserChanged(user.id);
      _isPerformingAction = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isPerformingAction = false;
      notifyListeners();
      return false;
    }
  }





  Future<void> logout() async {
    _isPerformingAction = true;
    notifyListeners();

    try {
      await _authRepo.logout();
      _isLoggedIn = false;
      _currentUser = null;
      _errorMessage = '';
      _notifyDatasourcesUserChanged('default'); // reset data isolation
    } catch (_) {}

    _isPerformingAction = false;
    notifyListeners();
  }
}
