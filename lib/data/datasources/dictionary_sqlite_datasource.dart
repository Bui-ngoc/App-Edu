import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../../domain/entities/dictionary_word.dart';

class DictionarySqliteDataSource {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'edumaster_it_dictionary.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE words (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            word TEXT NOT NULL UNIQUE,
            phonetic TEXT,
            vietnamese TEXT NOT NULL,
            definition TEXT,
            example TEXT,
            is_bookmarked INTEGER DEFAULT 0
          )
        ''');

        await db.execute('CREATE INDEX idx_word ON words(word)');
        await db.execute('CREATE INDEX idx_vi ON words(vietnamese)');

        // Populate initial IT terms from assets
        await _seedInitialData(db);
      },
    );
  }

  Future<void> _seedInitialData(Database db) async {
    try {
      final jsonStr = await rootBundle.loadString('assets/data/it_dictionary.json');
      final List<dynamic> list = json.decode(jsonStr);
      final batch = db.batch();
      for (final item in list) {
        batch.insert(
          'words',
          {
            'word': item['word'] ?? '',
            'phonetic': item['phonetic'] ?? '',
            'vietnamese': item['vi'] ?? '',
            'definition': item['def'] ?? '',
            'example': item['example'] ?? '',
            'is_bookmarked': 0,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
    } catch (_) {
      // Fallback silent: app continues normally even if json missing
    }
  }

  Future<List<DictionaryWord>> search(String query) async {
    final db = await database;
    final clean = query.trim();
    if (clean.isEmpty) {
      final results = await db.query('words', orderBy: 'word ASC', limit: 50);
      return results.map((e) => DictionaryWord.fromMap(e)).toList();
    }
    final results = await db.rawQuery('''
      SELECT * FROM words 
      WHERE word LIKE ? OR vietnamese LIKE ? OR definition LIKE ?
      ORDER BY 
        CASE 
          WHEN word LIKE ? THEN 1
          WHEN word LIKE ? THEN 2
          ELSE 3
        END,
        word ASC
      LIMIT 50
    ''', ['%$clean%', '%$clean%', '%$clean%', '$clean%', '%$clean%']);

    return results.map((e) => DictionaryWord.fromMap(e)).toList();
  }

  Future<void> setBookmark(int id, bool isBookmarked) async {
    final db = await database;
    await db.update(
      'words',
      {'is_bookmarked': isBookmarked ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<DictionaryWord>> getBookmarkedWords() async {
    final db = await database;
    final results = await db.query(
      'words',
      where: 'is_bookmarked = 1',
      orderBy: 'word ASC',
    );
    return results.map((e) => DictionaryWord.fromMap(e)).toList();
  }

  Future<DictionaryWord?> getWordOfTheDay() async {
    final db = await database;
    final now = DateTime.now();
    // Deterministic index for the day
    final daySeed = now.year * 1000 + now.month * 100 + now.day;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM words')) ?? 1;
    final offset = daySeed % (count > 0 ? count : 1);

    final results = await db.query('words', limit: 1, offset: offset);
    if (results.isNotEmpty) {
      return DictionaryWord.fromMap(results.first);
    }
    return null;
  }
}
