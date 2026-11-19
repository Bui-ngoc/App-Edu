import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/algorithms/sm2_algorithm.dart';
import '../../domain/entities/flashcard.dart';

class Sm2StorageDataSource {
  // Keys có userId suffix để phân biệt dữ liệu giữa các user
  static const String _decksKeyPrefix = 'edumaster_flashcard_decks_u_';
  static const String _cardsKeyPrefix = 'edumaster_flashcards_deck_';

  String _userId = 'default';

  String get _decksKey => '$_decksKeyPrefix$_userId';
  String _cardKey(String deckId) => '$_cardsKeyPrefix${_userId}_$deckId';

  SharedPreferences? _prefs;
  List<FlashcardDeck>? _cachedDecks;
  final Map<String, List<FlashcardItem>> _cachedCards = {};

  /// Gọi khi user đăng nhập/đăng xuất để load đúng data của user đó.
  void switchUser(String userId) {
    final newId = userId.trim().isEmpty ? 'default' : userId.trim();
    if (_userId != newId) {
      _userId = newId;
      _cachedDecks = null;
      _cachedCards.clear();
    }
  }

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<List<FlashcardDeck>> getDecks() async {
    if (_cachedDecks != null) return _cachedDecks!;

    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_decksKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      // Seed default deck cho user này
      final defaultDeck = FlashcardDeck(
        id: 'deck_it_core',
        title: 'Thuật ngữ Lập trình & CNTT Thiết yếu',
        description: 'Bộ thẻ ôn luyện kiến thức nền tảng SM-2',
        createdAt: DateTime.now(),
      );
      _cachedDecks = [defaultDeck];
      await prefs.setString(_decksKey, json.encode([defaultDeck.toMap()]));
      await _seedDefaultCards(defaultDeck.id);
      return _cachedDecks!;
    }

    try {
      final List<dynamic> list = json.decode(jsonStr);
      _cachedDecks = list.map((e) => FlashcardDeck.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      return _cachedDecks!;
    } catch (_) {
      _cachedDecks = [];
      return [];
    }
  }

  Future<void> saveDeck(FlashcardDeck deck) async {
    final decks = await getDecks();
    final index = decks.indexWhere((d) => d.id == deck.id);
    if (index >= 0) {
      decks[index] = deck;
    } else {
      decks.add(deck);
    }
    _cachedDecks = decks;

    final prefs = await _getPrefs();
    await prefs.setString(_decksKey, json.encode(decks.map((d) => d.toMap()).toList()));
  }

  Future<List<FlashcardItem>> getCardsInDeck(String deckId, {bool force = false}) async {
    if (!force && _cachedCards.containsKey(deckId) && _cachedCards[deckId]!.isNotEmpty) {
      return _cachedCards[deckId]!;
    }

    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_cardKey(deckId));
    if (jsonStr == null || jsonStr.isEmpty) {
      if (deckId == 'deck_it_core') {
        final defaults = _getDefaultCoreCards(deckId);
        await saveCardsInDeck(deckId, defaults);
        return defaults;
      }
      _cachedCards[deckId] = [];
      return [];
    }
    try {
      final List<dynamic> list = json.decode(jsonStr);
      final cards = list.map((e) => FlashcardItem.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      _cachedCards[deckId] = cards;
      return cards;
    } catch (_) {
      _cachedCards[deckId] = [];
      return [];
    }
  }

  Future<void> saveCardsInDeck(String deckId, List<FlashcardItem> cards) async {
    _cachedCards[deckId] = List<FlashcardItem>.from(cards);
    final prefs = await _getPrefs();
    await prefs.setString(
      _cardKey(deckId),
      json.encode(cards.map((c) => c.toMap()).toList()),
    );
  }

  Future<void> saveCard(FlashcardItem card) async {
    final cards = List<FlashcardItem>.from(await getCardsInDeck(card.deckId, force: true));
    final idx = cards.indexWhere((c) => c.id == card.id);
    if (idx >= 0) {
      cards[idx] = card;
    } else {
      cards.add(card);
    }
    await saveCardsInDeck(card.deckId, cards);
  }

  Future<void> updateCardSM2(String cardId, FlashcardItem updatedCard) async {
    await saveCard(updatedCard);
  }

  /// Import flashcards from CSV format (front,back,phonetic,example)
  Future<int> importFromCsv(String deckId, String csvContent) async {
    final lines = csvContent.split(RegExp(r'\r?\n'));
    final List<FlashcardItem> newCards = [];
    int count = 0;

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      // Split by comma or semicolon
      final parts = line.contains(';') ? line.split(';') : line.split(',');
      if (parts.length >= 2) {
        final front = parts[0].trim().replaceAll('"', '');
        final back = parts[1].trim().replaceAll('"', '');
        final phonetic = parts.length > 2 ? parts[2].trim().replaceAll('"', '') : null;
        final example = parts.length > 3 ? parts[3].trim().replaceAll('"', '') : null;

        if (front.isNotEmpty && back.isNotEmpty) {
          count++;
          newCards.add(
            FlashcardItem(
              id: 'card_${DateTime.now().millisecondsSinceEpoch}_$count',
              deckId: deckId,
              front: front,
              back: back,
              phonetic: phonetic,
              example: example,
              sm2: SM2State.initial(),
            ),
          );
        }
      }
    }

    if (newCards.isNotEmpty) {
      final existing = List<FlashcardItem>.from(await getCardsInDeck(deckId, force: true));
      existing.addAll(newCards);
      await saveCardsInDeck(deckId, existing);
    }

    return count;
  }

  List<FlashcardItem> _getDefaultCoreCards(String deckId) {
    return [
      FlashcardItem(
        id: 'c1',
        deckId: deckId,
        front: 'Algorithm',
        back: 'Thuật toán: Quy trình từng bước có hệ thống để giải quyết một bài toán cụ thể.',
        phonetic: '/ˈæl.ɡə.rɪ.ðəm/',
        example: 'Binary search algorithm runs in O(log n).',
        sm2: SM2State.initial(),
      ),
      FlashcardItem(
        id: 'c2',
        deckId: deckId,
        front: 'Encapsulation',
        back: 'Tính đóng gói: Nguyên lý OOP bảo vệ dữ liệu bên trong lớp và chỉ cho phép tương tác qua phương thức công khai.',
        phonetic: '/ɪnˌkæp.sjəˈleɪ.ʃən/',
        example: 'Dart uses underscore prefix to encapsulate private fields.',
        sm2: SM2State.initial(),
      ),
      FlashcardItem(
        id: 'c3',
        deckId: deckId,
        front: 'Polymorphism',
        back: 'Tính đa hình: Cho phép một interface đại diện cho nhiều kiểu đối tượng khác nhau.',
        phonetic: '/ˌpɒl.iˈmɔː.fɪ.zəm/',
        example: 'Method overriding in subclasses exemplifies runtime polymorphism.',
        sm2: SM2State.initial(),
      ),
      FlashcardItem(
        id: 'c4',
        deckId: deckId,
        front: 'SuperMemo SM-2',
        back: 'Thuật toán lặp lại ngắt quãng dựa trên hệ số độ dễ (Ease Factor) và khoảng thời gian (Interval) tối ưu ghi nhớ.',
        phonetic: '/ˌsuː.pəˈmem.oʊ/',
        example: 'SM-2 schedules reviews just before memories decay.',
        sm2: SM2State.initial(),
      ),
    ];
  }

  Future<void> _seedDefaultCards(String deckId) async {
    final defaults = _getDefaultCoreCards(deckId);
    await saveCardsInDeck(deckId, defaults);
  }
}
