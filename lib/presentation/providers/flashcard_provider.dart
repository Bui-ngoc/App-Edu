import 'package:flutter/foundation.dart';
import '../../domain/algorithms/sm2_algorithm.dart';
import '../../domain/entities/flashcard.dart';
import '../../domain/repositories/interfaces.dart';

enum FlashcardUiState { initial, loading, success, error, empty }

class FlashcardProvider extends ChangeNotifier {
  final IFlashcardRepository _repo;

  FlashcardProvider({required IFlashcardRepository repo}) : _repo = repo;

  FlashcardUiState _state = FlashcardUiState.initial;
  FlashcardUiState get state => _state;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  List<FlashcardDeck> _decks = [];
  List<FlashcardDeck> get decks => _decks;

  FlashcardDeck? _currentDeck;
  FlashcardDeck? get currentDeck => _currentDeck;

  List<FlashcardItem> _deckCards = [];
  List<FlashcardItem> get deckCards => _deckCards;

  List<FlashcardItem> _studyQueue = [];
  List<FlashcardItem> get studyQueue => _studyQueue;

  int _currentStudyIndex = 0;
  int get currentStudyIndex => _currentStudyIndex;

  bool _isCardFlipped = false;
  bool get isCardFlipped => _isCardFlipped;

  Map<String, int> _deckCardCounts = {};
  int getDeckCardCount(String deckId) => _deckCardCounts[deckId] ?? 0;

  Future<void> loadDecks({bool force = false}) async {
    if (!force && _decks.isNotEmpty && _state == FlashcardUiState.success) return;
    _state = FlashcardUiState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      _decks = await _repo.getDecks();
      _deckCardCounts = {};
      for (final d in _decks) {
        final cards = await _repo.getCardsInDeck(d.id);
        _deckCardCounts[d.id] = cards.length;
      }
      if (_decks.isEmpty) {
        _state = FlashcardUiState.empty;
      } else {
        _state = FlashcardUiState.success;
      }
    } catch (e) {
      _state = FlashcardUiState.error;
      _errorMessage = 'Lỗi nạp danh sách bộ thẻ: ${e.toString()}';
    }
    notifyListeners();
  }

  Future<void> selectDeck(FlashcardDeck deck, {bool dueOnly = false}) async {
    _currentDeck = deck;
    _state = FlashcardUiState.loading;
    _isCardFlipped = false;
    _currentStudyIndex = 0;
    notifyListeners();

    try {
      _deckCards = await _repo.getCardsInDeck(deck.id);
      if (dueOnly) {
        _studyQueue = _deckCards.where((c) => c.isDueToday).toList();
      } else {
        _studyQueue = List.from(_deckCards);
      }

      if (_studyQueue.isEmpty) {
        _state = FlashcardUiState.empty;
      } else {
        _state = FlashcardUiState.success;
      }
    } catch (e) {
      _state = FlashcardUiState.error;
      _errorMessage = 'Lỗi nạp thẻ: ${e.toString()}';
    }
    notifyListeners();
  }

  void flipCard() {
    _isCardFlipped = !_isCardFlipped;
    notifyListeners();
  }

  /// Rate recall quality (0 to 5) and compute next SM-2 interval
  Future<void> submitSM2Rating(int quality) async {
    if (_currentStudyIndex >= _studyQueue.length) return;

    final currentCard = _studyQueue[_currentStudyIndex];
    final nextState = SM2Algorithm.review(
      currentRepetition: currentCard.sm2.repetition,
      currentInterval: currentCard.sm2.interval,
      currentEaseFactor: currentCard.sm2.easeFactor,
      quality: quality,
    );

    final updatedCard = currentCard.copyWith(sm2: nextState);
    await _repo.updateCardSM2(currentCard.id, updatedCard);

    // Update in local lists
    final deckIdx = _deckCards.indexWhere((c) => c.id == currentCard.id);
    if (deckIdx >= 0) {
      _deckCards[deckIdx] = updatedCard;
    }

    _isCardFlipped = false;
    _currentStudyIndex++;
    notifyListeners();
  }

  Future<int> importCsv(String deckId, String csvContent) async {
    final count = await _repo.importCardsFromCsv(deckId, csvContent);
    await loadDecks(force: true);
    if (_currentDeck != null && _currentDeck!.id == deckId) {
      await selectDeck(_currentDeck!);
    }
    return count;
  }

  /// Thêm thẻ mới trực tiếp vào bộ thẻ và lưu kiên cố vào bộ nhớ máy
  Future<void> addCard({
    required String deckId,
    required String front,
    required String back,
    String? phonetic,
    String? example,
  }) async {
    final newCard = FlashcardItem(
      id: 'card_${DateTime.now().millisecondsSinceEpoch}',
      deckId: deckId,
      front: front.trim(),
      back: back.trim(),
      phonetic: (phonetic != null && phonetic.trim().isNotEmpty) ? phonetic.trim() : null,
      example: (example != null && example.trim().isNotEmpty) ? example.trim() : null,
      sm2: SM2State.initial(),
    );
    await _repo.saveCard(newCard);
    await loadDecks(force: true);
    if (_currentDeck != null && _currentDeck!.id == deckId) {
      await selectDeck(_currentDeck!);
    }
    notifyListeners();
  }

  /// Tạo bộ thẻ học tập mới
  Future<void> createDeck(String title, String description) async {
    final newDeck = FlashcardDeck(
      id: 'deck_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      description: description.trim().isEmpty ? 'Bộ thẻ tự tạo' : description.trim(),
      createdAt: DateTime.now(),
    );
    await _repo.saveDeck(newDeck);
    await loadDecks(force: true);
  }
}
