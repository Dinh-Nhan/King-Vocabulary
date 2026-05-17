import 'package:cloud_firestore/cloud_firestore.dart';

class FlashcardDeck {
  final String deckId;
  final String ownerUserId;
  final String title;
  final String description;
  final int totalFlashcardCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FlashcardDeck({
    required this.deckId,
    required this.ownerUserId,
    required this.title,
    this.description = '',
    this.totalFlashcardCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FlashcardDeck.fromMap(Map<String, dynamic> map, String id) {
    return FlashcardDeck(
      deckId: id,
      ownerUserId: map['ownerUserId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      totalFlashcardCount: map['totalFlashcardCount'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerUserId': ownerUserId,
      'title': title,
      'description': description,
      'totalFlashcardCount': totalFlashcardCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  FlashcardDeck copyWith({
    String? title,
    String? description,
    int? totalFlashcardCount,
    DateTime? updatedAt,
  }) {
    return FlashcardDeck(
      deckId: deckId,
      ownerUserId: ownerUserId,
      title: title ?? this.title,
      description: description ?? this.description,
      totalFlashcardCount: totalFlashcardCount ?? this.totalFlashcardCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
