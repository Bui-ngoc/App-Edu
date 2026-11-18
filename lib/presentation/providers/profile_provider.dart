import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/repositories/interfaces.dart';
import '../../data/datasources/gemini_ai_datasource.dart';

class ProfileProvider extends ChangeNotifier {
  final ILeaderboardRepository _repo;
  final GeminiAiDataSource _aiDataSource;
  final ImagePicker _picker = ImagePicker();

  UserProfile _profile = const UserProfile(
    uid: 'user_current',
    name: 'Sinh viên CNTT',
    email: 'student@edumaster.edu.vn',
  );
  UserProfile get profile => _profile;

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  String _apiKey = '';
  String get apiKey => _apiKey;

  bool _isDemoMode = false;
  bool get isDemoMode => _isDemoMode;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ProfileProvider({
    required ILeaderboardRepository repo,
    required GeminiAiDataSource aiDataSource,
  })  : _repo = repo,
        _aiDataSource = aiDataSource {
    loadProfile();
  }

  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      _profile   = await _repo.getUserProfile();
      _apiKey    = await _aiDataSource.getApiKey();
      _isDemoMode = await _aiDataSource.isDemoMode();
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  /// Pick avatar directly from Camera or Gallery
  Future<bool> updateAvatar(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (photo != null) {
        _profile = _profile.copyWith(localAvatarPath: photo.path);
        await _repo.saveUserProfile(_profile);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> updateNameAndGroup(String name, String group) async {
    _profile = _profile.copyWith(name: name.trim(), currentGroup: group.trim());
    await _repo.saveUserProfile(_profile);
    notifyListeners();
  }

  Future<void> saveApiKey(String key) async {
    _apiKey = key.trim();
    await _aiDataSource.saveApiKey(_apiKey);
    notifyListeners();
  }

  Future<void> resetApiKeyToDefault() async {
    await _aiDataSource.clearSavedApiKey();
    _apiKey = await _aiDataSource.getApiKey();
    notifyListeners();
  }

  Future<void> setDemoMode(bool value) async {
    _isDemoMode = value;
    await _aiDataSource.setDemoMode(value);
    notifyListeners();
  }
}
