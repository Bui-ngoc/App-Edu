class DictionaryWord {
  final int? id;
  final String word;
  final String phonetic;
  final String vietnamese;
  final String definition;
  final String example;
  final bool isBookmarked;

  const DictionaryWord({
    this.id,
    required this.word,
    required this.phonetic,
    required this.vietnamese,
    required this.definition,
    required this.example,
    this.isBookmarked = false,
  });

  DictionaryWord copyWith({
    int? id,
    String? word,
    String? phonetic,
    String? vietnamese,
    String? definition,
    String? example,
    bool? isBookmarked,
  }) {
    return DictionaryWord(
      id: id ?? this.id,
      word: word ?? this.word,
      phonetic: phonetic ?? this.phonetic,
      vietnamese: vietnamese ?? this.vietnamese,
      definition: definition ?? this.definition,
      example: example ?? this.example,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'word': word,
      'phonetic': phonetic,
      'vietnamese': vietnamese,
      'definition': definition,
      'example': example,
      'is_bookmarked': isBookmarked ? 1 : 0,
    };
  }

  factory DictionaryWord.fromMap(Map<String, dynamic> map) {
    return DictionaryWord(
      id: (map['id'] as num?)?.toInt(),
      word: map['word']?.toString() ?? '',
      phonetic: map['phonetic']?.toString() ?? '',
      vietnamese: map['vietnamese']?.toString() ?? '',
      definition: map['definition']?.toString() ?? '',
      example: map['example']?.toString() ?? '',
      isBookmarked: (map['is_bookmarked'] as num?)?.toInt() == 1,
    );
  }
}
