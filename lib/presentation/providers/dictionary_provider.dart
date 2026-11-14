import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../domain/entities/dictionary_word.dart';
import '../../domain/repositories/interfaces.dart';

enum DictUiState { initial, loading, success, error, empty }

class DictionaryProvider extends ChangeNotifier {
  final IDictionaryRepository _repo;
  final FlutterTts _tts = FlutterTts();

  DictionaryProvider({required IDictionaryRepository repo}) : _repo = repo {
    _initTts();
  }

  DictUiState _state = DictUiState.initial;
  DictUiState get state => _state;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  List<DictionaryWord> _words = [];
  List<DictionaryWord> get words => _words;

  DictionaryWord? _wordOfTheDay;
  DictionaryWord? get wordOfTheDay => _wordOfTheDay;

  String _currentQuery = '';
  String get currentQuery => _currentQuery;

  bool _showOnlyBookmarks = false;
  bool get showOnlyBookmarks => _showOnlyBookmarks;

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (_) {}
  }

  Future<void> init() async {
    _state = DictUiState.loading;
    notifyListeners();

    try {
      await _repo.initDatabase();
      _wordOfTheDay = await _repo.getWordOfTheDay();
      await search('');
    } catch (e) {
      _state = DictUiState.error;
      _errorMessage = 'Lỗi khởi tạo CSDL từ điển: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> search(String query) async {
    _currentQuery = query;
    _state = DictUiState.loading;
    notifyListeners();

    try {
      if (_showOnlyBookmarks) {
        final bookmarks = await _repo.getBookmarkedWords();
        if (query.trim().isEmpty) {
          _words = bookmarks;
        } else {
          final clean = query.trim().toLowerCase();
          _words = bookmarks.where((w) =>
              w.word.toLowerCase().contains(clean) ||
              w.vietnamese.toLowerCase().contains(clean)).toList();
        }
      } else {
        _words = await _repo.searchWords(query);
      }

      if (_words.isEmpty) {
        _state = DictUiState.empty;
      } else {
        _state = DictUiState.success;
      }
    } catch (e) {
      _state = DictUiState.error;
      _errorMessage = 'Lỗi tìm kiếm: ${e.toString()}';
    }
    notifyListeners();
  }

  void toggleBookmarksFilter() {
    _showOnlyBookmarks = !_showOnlyBookmarks;
    search(_currentQuery);
  }

  Future<void> toggleBookmark(DictionaryWord word) async {
    if (word.id == null) return;
    final nextVal = !word.isBookmarked;
    await _repo.toggleBookmark(word.id!, nextVal);

    final idx = _words.indexWhere((w) => w.id == word.id);
    if (idx >= 0) {
      _words[idx] = word.copyWith(isBookmarked: nextVal);
      if (_showOnlyBookmarks && !nextVal) {
        _words.removeAt(idx);
      }
    }
    if (_wordOfTheDay?.id == word.id) {
      _wordOfTheDay = _wordOfTheDay?.copyWith(isBookmarked: nextVal);
    }
    notifyListeners();
  }

  Future<void> speakWord(String word) async {
    try {
      await _tts.stop();
      await _tts.speak(word);
    } catch (_) {}
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}
