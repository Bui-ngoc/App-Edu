import '../../domain/entities/dictionary_word.dart';
import '../../domain/repositories/interfaces.dart';
import '../datasources/dictionary_sqlite_datasource.dart';

class DictionaryRepositoryImpl implements IDictionaryRepository {
  final DictionarySqliteDataSource _dataSource;

  DictionaryRepositoryImpl({DictionarySqliteDataSource? dataSource})
      : _dataSource = dataSource ?? DictionarySqliteDataSource();

  @override
  Future<void> initDatabase() async {
    await _dataSource.database;
  }

  @override
  Future<List<DictionaryWord>> searchWords(String query) {
    return _dataSource.search(query);
  }

  @override
  Future<void> toggleBookmark(int id, bool isBookmarked) {
    return _dataSource.setBookmark(id, isBookmarked);
  }

  @override
  Future<List<DictionaryWord>> getBookmarkedWords() {
    return _dataSource.getBookmarkedWords();
  }

  @override
  Future<DictionaryWord?> getWordOfTheDay() {
    return _dataSource.getWordOfTheDay();
  }
}
