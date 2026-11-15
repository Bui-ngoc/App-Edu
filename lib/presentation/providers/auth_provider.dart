import 'package:flutter/material.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/interfaces.dart';

class AuthProvider extends ChangeNotifier {
  final IAuthRepository _authRepo;

  AuthProvider({required IAuthRepository authRepo}) : _authRepo = authRepo {
    checkAuthStatus();
  }

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  AuthUser? _currentUser;
  AuthUser? get currentUser => _currentUser;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

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
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final user = await _authRepo.login(email: email, password: password);
      _currentUser = user;
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String group,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final user = await _authRepo.register(
        name: name,
        email: email,
        password: password,
        group: group,
      );
      _currentUser = user;
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> quickDemoLogin() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final user = await _authRepo.quickDemoLogin();
      _currentUser = user;
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authRepo.logout();
      _isLoggedIn = false;
      _currentUser = null;
      _errorMessage = '';
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }
}
