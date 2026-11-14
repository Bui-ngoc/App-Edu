import '../algorithms/sm2_algorithm.dart';

class FlashcardDeck {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;

  const FlashcardDeck({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FlashcardDeck.fromMap(Map<String, dynamic> map) {
    return FlashcardDeck(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Chưa đặt tên',
      description: map['description']?.toString() ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class FlashcardItem {
  final String id;
  final String deckId;
  final String front;
  final String back;
  final String? phonetic;
  final String? example;
  final SM2State sm2;

  const FlashcardItem({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    this.phonetic,
    this.example,
    required this.sm2,
  });

  bool get isDueToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final review = DateTime(sm2.nextReviewDate.year, sm2.nextReviewDate.month, sm2.nextReviewDate.day);
    return review.isBefore(today) || review.isAtSameMomentAs(today);
  }

  FlashcardItem copyWith({
    String? front,
    String? back,
    String? phonetic,
    String? example,
    SM2State? sm2,
  }) {
    return FlashcardItem(
      id: id,
      deckId: deckId,
      front: front ?? this.front,
      back: back ?? this.back,
      phonetic: phonetic ?? this.phonetic,
      example: example ?? this.example,
      sm2: sm2 ?? this.sm2,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deckId': deckId,
      'front': front,
      'back': back,
      'phonetic': phonetic,
      'example': example,
      'sm2': sm2.toMap(),
    };
  }

  factory FlashcardItem.fromMap(Map<String, dynamic> map) {
    return FlashcardItem(
      id: map['id']?.toString() ?? '',
      deckId: map['deckId']?.toString() ?? '',
      front: map['front']?.toString() ?? '',
      back: map['back']?.toString() ?? '',
      phonetic: map['phonetic']?.toString(),
      example: map['example']?.toString(),
      sm2: map['sm2'] != null ? SM2State.fromMap(Map<String, dynamic>.from(map['sm2'] as Map)) : SM2State.initial(),
    );
  }
}
