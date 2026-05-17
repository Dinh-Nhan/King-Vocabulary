import 'package:cloud_firestore/cloud_firestore.dart';

class Flashcard {
  final String flashcardId;
  final String deckId;
  final String ownerUserId;
  final String frontContent; // từ tiếng Anh
  final String backContent; // nghĩa tiếng Việt
  final int reviewCount;
  final DateTime? lastReviewedAt;
  final DateTime? nextReviewAt;
  final int displayOrder;
  final double easeFactor; // SM-2: hệ số dễ nhớ (mặc định 2.5)
  final int reviewIntervalDays; // SM-2: khoảng cách ôn tập (ngày)
  final int repetitionCount; // SM-2: số lần ôn liên tiếp thành công
  final int learnedCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Flashcard({
    required this.flashcardId,
    required this.deckId,
    required this.ownerUserId,
    required this.frontContent,
    required this.backContent,
    this.reviewCount = 0,
    this.lastReviewedAt,
    this.nextReviewAt,
    this.displayOrder = 0,
    this.easeFactor = 2.5,
    this.reviewIntervalDays = 1,
    this.repetitionCount = 0,
    this.learnedCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Flashcard.fromMap(Map<String, dynamic> map, String id) {
    return Flashcard(
      flashcardId: id,
      deckId: map['deckId'] ?? '',
      ownerUserId: map['ownerUserId'] ?? '',
      frontContent: map['frontContent'] ?? '',
      backContent: map['backContent'] ?? '',
      reviewCount: map['reviewCount'] ?? 0,
      lastReviewedAt: map['lastReviewedAt'] != null
          ? (map['lastReviewedAt'] as Timestamp).toDate()
          : null,
      nextReviewAt: map['nextReviewAt'] != null
          ? (map['nextReviewAt'] as Timestamp).toDate()
          : null,
      displayOrder: map['displayOrder'] ?? 0,
      easeFactor: (map['easeFactor'] ?? 2.5).toDouble(),
      reviewIntervalDays: map['reviewIntervalDays'] ?? 1,
      repetitionCount: map['repetitionCount'] ?? 0,
      learnedCount: map['learnedCount'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deckId': deckId,
      'ownerUserId': ownerUserId,
      'frontContent': frontContent,
      'backContent': backContent,
      'reviewCount': reviewCount,
      'lastReviewedAt': lastReviewedAt != null
          ? Timestamp.fromDate(lastReviewedAt!)
          : null,
      'nextReviewAt': nextReviewAt != null
          ? Timestamp.fromDate(nextReviewAt!)
          : null,
      'displayOrder': displayOrder,
      'easeFactor': easeFactor,
      'reviewIntervalDays': reviewIntervalDays,
      'repetitionCount': repetitionCount,
      'learnedCount': learnedCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Flashcard copyWith({
    String? frontContent,
    String? backContent,
    int? reviewCount,
    DateTime? lastReviewedAt,
    DateTime? nextReviewAt,
    int? displayOrder,
    double? easeFactor,
    int? reviewIntervalDays,
    int? repetitionCount,
    int? learnedCount,
    DateTime? updatedAt,
  }) {
    return Flashcard(
      flashcardId: flashcardId,
      deckId: deckId,
      ownerUserId: ownerUserId,
      frontContent: frontContent ?? this.frontContent,
      backContent: backContent ?? this.backContent,
      reviewCount: reviewCount ?? this.reviewCount,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      displayOrder: displayOrder ?? this.displayOrder,
      easeFactor: easeFactor ?? this.easeFactor,
      reviewIntervalDays: reviewIntervalDays ?? this.reviewIntervalDays,
      repetitionCount: repetitionCount ?? this.repetitionCount,
      learnedCount: learnedCount ?? this.learnedCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
