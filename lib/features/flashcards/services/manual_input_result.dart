import 'package:king_vocabulary/features/flashcards/models/flash_card.dart';
import 'package:king_vocabulary/features/flashcards/models/flash_card_deck.dart';
import 'deck_service.dart';

/// Kết quả sau khi lưu
class ManualInputResult {
  final FlashcardDeck deck;
  final int savedCount;
  final int skippedCount; // số từ bị bỏ qua vì trống

  const ManualInputResult({
    required this.deck,
    required this.savedCount,
    required this.skippedCount,
  });
}

class ManualInputService {
  final _deckService = DeckService();

  /// Tạo bộ từ mới + lưu danh sách từ nhập tay
  ///
  /// [entries] — list cặp {front: 'word', back: 'nghĩa'}
  /// Bỏ qua các entry mà front hoặc back trống
  Future<ManualInputResult> createDeckWithWords({
    required String title,
    String description = '',
    required List<({String front, String back})> entries,
  }) async {
    if (title.trim().isEmpty) {
      throw Exception('Tên bộ từ không được để trống.');
    }

    // Lọc bỏ các entry trống
    final valid = entries
        .where((e) => e.front.trim().isNotEmpty && e.back.trim().isNotEmpty)
        .toList();

    final skipped = entries.length - valid.length;

    // Tạo deck
    final deck = await _deckService.createDeck(
      title: title,
      description: description,
    );

    // Lưu từ nếu có
    if (valid.isNotEmpty) {
      await _deckService.addFlashcards(deckId: deck.deckId, entries: valid);
    }

    return ManualInputResult(
      deck: deck,
      savedCount: valid.length,
      skippedCount: skipped,
    );
  }

  /// Thêm từ vào bộ từ đã có
  Future<ManualInputResult> addWordsToDeck({
    required String deckId,
    required List<({String front, String back})> entries,
  }) async {
    final valid = entries
        .where((e) => e.front.trim().isNotEmpty && e.back.trim().isNotEmpty)
        .toList();

    final skipped = entries.length - valid.length;

    if (valid.isNotEmpty) {
      await _deckService.addFlashcards(deckId: deckId, entries: valid);
    }

    final deck = await _deckService.getDeck(deckId);
    if (deck == null) throw Exception('Không tìm thấy bộ từ.');

    return ManualInputResult(
      deck: deck,
      savedCount: valid.length,
      skippedCount: skipped,
    );
  }

  /// Thêm 1 từ đơn lẻ vào bộ từ
  Future<Flashcard> addSingleWord({
    required String deckId,
    required String front,
    required String back,
  }) async {
    if (front.trim().isEmpty || back.trim().isEmpty) {
      throw Exception('Từ và nghĩa không được để trống.');
    }
    return _deckService.addFlashcard(
      deckId: deckId,
      frontContent: front,
      backContent: back,
    );
  }
}
