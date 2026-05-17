import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:king_vocabulary/features/flashcards/models/flash_card.dart';
import 'package:king_vocabulary/features/flashcards/models/flash_card_deck.dart';

class DeckService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ── Helpers ─────────────────────────────────────────────────────────────────
  String get _uid => _auth.currentUser!.uid;

  /// users/{uid}/decks
  CollectionReference<Map<String, dynamic>> get _decksRef =>
      _db.collection('users').doc(_uid).collection('decks');

  /// users/{uid}/decks/{deckId}/words
  CollectionReference<Map<String, dynamic>> _wordsRef(String deckId) =>
      _decksRef.doc(deckId).collection('words');

  // ── Deck CRUD ────────────────────────────────────────────────────────────────

  /// Tạo bộ từ mới (không có từ nào)
  Future<FlashcardDeck> createDeck({
    required String title,
    String description = '',
  }) async {
    final now = DateTime.now();
    final docRef = _decksRef.doc(); // auto-generate id

    final deck = FlashcardDeck(
      deckId: docRef.id,
      ownerUserId: _uid,
      title: title.trim(),
      description: description.trim(),
      totalFlashcardCount: 0,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(deck.toMap());
    return deck;
  }

  /// Lấy tất cả bộ từ của user
  Stream<List<FlashcardDeck>> watchDecks() {
    return _decksRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => FlashcardDeck.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Lấy 1 bộ từ theo id
  Future<FlashcardDeck?> getDeck(String deckId) async {
    final doc = await _decksRef.doc(deckId).get();
    if (!doc.exists) return null;
    return FlashcardDeck.fromMap(doc.data()!, doc.id);
  }

  /// Cập nhật tên / mô tả bộ từ
  Future<void> updateDeck(
    String deckId, {
    String? title,
    String? description,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
      if (title != null) 'title': title.trim(),
      if (description != null) 'description': description.trim(),
    };
    await _decksRef.doc(deckId).update(updates);
  }

  /// Xóa bộ từ và toàn bộ từ bên trong (batch delete)
  Future<void> deleteDeck(String deckId) async {
    // Xóa tất cả words trước
    final words = await _wordsRef(deckId).get();
    final batch = _db.batch();
    for (final doc in words.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_decksRef.doc(deckId));
    await batch.commit();
  }

  // ── Flashcard CRUD ───────────────────────────────────────────────────────────

  /// Thêm 1 từ vào bộ từ
  Future<Flashcard> addFlashcard({
    required String deckId,
    required String frontContent,
    required String backContent,
    int? displayOrder,
  }) async {
    final now = DateTime.now();
    final docRef = _wordsRef(deckId).doc();

    // Lấy displayOrder tự động nếu không truyền vào
    final order =
        displayOrder ?? (await _wordsRef(deckId).count().get()).count ?? 0;

    final card = Flashcard(
      flashcardId: docRef.id,
      deckId: deckId,
      ownerUserId: _uid,
      frontContent: frontContent.trim(),
      backContent: backContent.trim(),
      displayOrder: order,
      createdAt: now,
      updatedAt: now,
    );

    // Dùng batch để vừa thêm từ vừa tăng totalFlashcardCount
    final batch = _db.batch();
    batch.set(docRef, card.toMap());
    batch.update(_decksRef.doc(deckId), {
      'totalFlashcardCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();

    return card;
  }

  /// Thêm nhiều từ cùng lúc (dùng cho import)
  Future<void> addFlashcards({
    required String deckId,
    required List<({String front, String back})> entries,
  }) async {
    if (entries.isEmpty) return;

    final now = DateTime.now();
    final currentCount = (await _wordsRef(deckId).count().get()).count ?? 0;

    // Firestore batch tối đa 500 writes — chia nhỏ nếu cần
    final chunks = <List<({String front, String back})>>[];
    for (var i = 0; i < entries.length; i += 400) {
      chunks.add(
        entries.sublist(i, i + 400 > entries.length ? entries.length : i + 400),
      );
    }

    int orderOffset = currentCount;
    for (final chunk in chunks) {
      final batch = _db.batch();
      for (final entry in chunk) {
        final docRef = _wordsRef(deckId).doc();
        final card = Flashcard(
          flashcardId: docRef.id,
          deckId: deckId,
          ownerUserId: _uid,
          frontContent: entry.front.trim(),
          backContent: entry.back.trim(),
          displayOrder: orderOffset++,
          createdAt: now,
          updatedAt: now,
        );
        batch.set(docRef, card.toMap());
      }
      // Cập nhật count sau mỗi chunk
      batch.update(_decksRef.doc(deckId), {
        'totalFlashcardCount': FieldValue.increment(chunk.length),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    }
  }

  /// Lấy tất cả từ trong bộ từ
  Stream<List<Flashcard>> watchFlashcards(String deckId) {
    return _wordsRef(deckId)
        .orderBy('displayOrder')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Flashcard.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Cập nhật nội dung 1 từ
  Future<void> updateFlashcard(
    String deckId,
    String flashcardId, {
    String? frontContent,
    String? backContent,
  }) async {
    await _wordsRef(deckId).doc(flashcardId).update({
      if (frontContent != null) 'frontContent': frontContent.trim(),
      if (backContent != null) 'backContent': backContent.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Xóa 1 từ
  Future<void> deleteFlashcard(String deckId, String flashcardId) async {
    final batch = _db.batch();
    batch.delete(_wordsRef(deckId).doc(flashcardId));
    batch.update(_decksRef.doc(deckId), {
      'totalFlashcardCount': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  /// Lấy các từ cần ôn hôm nay (nextReviewAt <= now)
  Future<List<Flashcard>> getDueFlashcards(String deckId) async {
    final snap = await _wordsRef(deckId)
        .where('nextReviewAt', isLessThanOrEqualTo: Timestamp.now())
        .orderBy('nextReviewAt')
        .get();
    return snap.docs
        .map((doc) => Flashcard.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Lấy tất cả từ cần ôn hôm nay từ mọi bộ từ
  Future<List<Flashcard>> getAllDueFlashcards() async {
    final decks = await _decksRef.get();
    final results = <Flashcard>[];
    for (final deck in decks.docs) {
      final due = await getDueFlashcards(deck.id);
      results.addAll(due);
    }
    return results;
  }
}
