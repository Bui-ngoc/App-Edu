import '../../domain/entities/flashcard.dart';
import '../../domain/repositories/interfaces.dart';
import '../datasources/sm2_storage_datasource.dart';

class FlashcardRepositoryImpl implements IFlashcardRepository {
  final Sm2StorageDataSource _dataSource;

  FlashcardRepositoryImpl({Sm2StorageDataSource? dataSource})
      : _dataSource = dataSource ?? Sm2StorageDataSource();

  @override
  Future<List<FlashcardDeck>> getDecks() {
    return _dataSource.getDecks();
  }

  @override
  Future<void> saveDeck(FlashcardDeck deck) {
    return _dataSource.saveDeck(deck);
  }

  @override
  Future<List<FlashcardItem>> getCardsInDeck(String deckId) {
    return _dataSource.getCardsInDeck(deckId);
  }

  @override
  Future<void> saveCard(FlashcardItem card) {
    return _dataSource.saveCard(card);
  }

  @override
  Future<void> updateCardSM2(String cardId, FlashcardItem updatedCard) {
    return _dataSource.updateCardSM2(cardId, updatedCard);
  }

  @override
  Future<int> importCardsFromCsv(String deckId, String csvContent) {
    return _dataSource.importFromCsv(deckId, csvContent);
  }
}
