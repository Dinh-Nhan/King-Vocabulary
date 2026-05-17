import 'package:king_vocabulary/features/flashcards/services/deck_service.dart';

/// Service để xử lý việc ôn tập từ vựng
class ReviewService {
  final _deckService = DeckService();

  /// Đánh dấu một từ đã được ôn tập
  ///
  /// Gọi method này sau khi user ôn một từ (đúng hoặc sai)
  /// Sẽ tự động:
  /// - Tăng reviewCount của flashcard
  /// - Cập nhật lastReviewedAt
  /// - Cập nhật learnedCount của deck
  Future<void> markAsReviewed({
    required String deckId,
    required String flashcardId,
  }) async {
    await _deckService.incrementReviewCount(deckId, flashcardId);
  }

  /// Cập nhật learnedCount cho một deck cụ thể
  ///
  /// Gọi khi cần sync lại số liệu
  Future<void> syncLearnedCount(String deckId) async {
    await _deckService.updateLearnedCount(deckId);
  }

  /// Cập nhật learnedCount cho tất cả decks
  ///
  /// Gọi khi cần sync lại toàn bộ số liệu
  Future<void> syncAllLearnedCounts() async {
    await _deckService.updateAllLearnedCounts();
  }
}
