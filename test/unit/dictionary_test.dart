import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:edumaster/domain/entities/dictionary_word.dart';

void main() {
  group('Từ điển thuật ngữ IT Offline (Unit Tests - Topic #35)', () {
    test('15. Chuyển đổi SQLite Map sang DictionaryWord chính xác', () {
      final map = {
        'id': 1,
        'word': 'Algorithm',
        'phonetic': '/ˈæl.ɡə.rɪ.ðəm/',
        'vietnamese': 'Thuật toán',
        'definition': 'Quy trình giải quyết vấn đề',
        'example': 'Binary search is an algorithm',
        'is_bookmarked': 1,
      };

      final word = DictionaryWord.fromMap(map);
      expect(word.id, equals(1));
      expect(word.word, equals('Algorithm'));
      expect(word.isBookmarked, isTrue);
    });

    test('16. toggleBookmark cập nhật trạng thái bookmark thông qua copyWith', () {
      const original = DictionaryWord(
        id: 2,
        word: 'API',
        phonetic: '/eɪ.piː.aɪ/',
        vietnamese: 'Giao diện lập trình ứng dụng',
        definition: 'Application Programming Interface',
        example: 'REST API',
        isBookmarked: false,
      );

      final bookmarked = original.copyWith(isBookmarked: true);
      expect(bookmarked.isBookmarked, isTrue);
      expect(bookmarked.word, equals(original.word));

      final unbookmarked = bookmarked.copyWith(isBookmarked: false);
      expect(unbookmarked.isBookmarked, isFalse);
    });

    test('17. DictionaryWord toMap tạo đúng kiểu số nguyên 0/1 cho SQLite', () {
      const word = DictionaryWord(
        id: 3,
        word: 'Cache',
        phonetic: '/kæʃ/',
        vietnamese: 'Bộ nhớ đệm',
        definition: 'Memory cache',
        example: 'Redis cache',
        isBookmarked: true,
      );

      final map = word.toMap();
      expect(map['is_bookmarked'], equals(1));
      expect(map['word'], equals('Cache'));
    });

    test('18. DictionaryWord fromMap hỗ trợ linh hoạt cả vi/vietnamese và def/definition', () {
      final jsonItem = {
        'word': 'Compiler',
        'phonetic': '/kəmˈpaɪ.lər/',
        'vi': 'Trình biên dịch',
        'def': 'A program translating source code into machine code.',
        'example': 'Flutter compiles Dart code.',
      };

      final word = DictionaryWord.fromMap(jsonItem);
      expect(word.word, equals('Compiler'));
      expect(word.vietnamese, equals('Trình biên dịch'));
      expect(word.definition, equals('A program translating source code into machine code.'));
      expect(word.isBookmarked, isFalse);
    });

    test('19. File it_dictionary.json có cấu trúc danh sách hợp lệ, không bị lồng mảng', () async {
      final file = File('assets/data/it_dictionary.json');
      expect(file.existsSync(), isTrue);

      final content = await file.readAsString();
      final decoded = json.decode(content);
      expect(decoded, isA<List>());

      final list = decoded as List;
      expect(list.length, greaterThanOrEqualTo(40));

      final seenWords = <String>{};
      for (final item in list) {
        expect(item, isA<Map>());
        final map = item as Map;
        expect(map['word'], isNotNull);
        expect((map['word'] as String).isNotEmpty, isTrue);
        expect(map['vi'], isNotNull);
        expect(map['def'], isNotNull);

        final word = (map['word'] as String).trim().toLowerCase();
        expect(seenWords.contains(word), isFalse, reason: 'Duplicate word found: $word');
        seenWords.add(word);
      }
    });
  });
}
