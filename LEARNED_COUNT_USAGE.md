# Hướng dẫn sử dụng LearnedCount

## Tổng quan

`learnedCount` là số từ đã học trong một bộ từ (deck). Một từ được coi là "đã học" khi `reviewCount > 0`.

## Cách hoạt động

### 1. Tự động cập nhật khi vào HomeScreen

Khi user vào HomeScreen, hệ thống tự động cập nhật `learnedCount` cho tất cả các deck:

```dart
// Trong HomeScreen
@override
void initState() {
  super.initState();
  _updateLearnedCountsOnce(); // Tự động cập nhật
}
```

### 2. Cập nhật khi user ôn từ

Khi user ôn một từ (trong màn hình học/ôn tập), gọi:

```dart
import 'package:king_vocabulary/features/flashcards/services/review_service.dart';

final reviewService = ReviewService();

// Sau khi user ôn một từ (đúng hoặc sai)
await reviewService.markAsReviewed(
  deckId: 'deck_id_here',
  flashcardId: 'flashcard_id_here',
);
```

Method này sẽ:
- ✅ Tăng `reviewCount` của flashcard
- ✅ Cập nhật `lastReviewedAt`
- ✅ Tự động cập nhật `learnedCount` của deck

### 3. Sync thủ công (nếu cần)

```dart
// Sync một deck cụ thể
await reviewService.syncLearnedCount('deck_id');

// Sync tất cả decks
await reviewService.syncAllLearnedCounts();
```

## Ví dụ sử dụng trong màn hình học từ

```dart
class StudyScreen extends StatefulWidget {
  final String deckId;
  const StudyScreen({required this.deckId});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  final _reviewService = ReviewService();

  Future<void> _onAnswerSubmitted(String flashcardId, bool isCorrect) async {
    // Xử lý logic học từ (SM-2, etc.)
    // ...

    // Đánh dấu đã ôn
    await _reviewService.markAsReviewed(
      deckId: widget.deckId,
      flashcardId: flashcardId,
    );

    // UI sẽ tự động cập nhật vì StreamBuilder trong HomeScreen
  }
}
```

## Hiển thị trong UI

HomeScreen tự động hiển thị:

```dart
Text('${deck.learnedCount}/${deck.totalFlashcardCount} từ')
```

Progress bar:
```dart
final progress = deck.totalFlashcardCount > 0
    ? deck.learnedCount / deck.totalFlashcardCount
    : 0.0;
```

## Lưu ý

1. **Performance**: `updateAllLearnedCounts()` chỉ chạy 1 lần khi vào HomeScreen, không ảnh hưởng performance
2. **Realtime**: Khi user ôn từ, `learnedCount` tự động cập nhật và StreamBuilder sẽ rebuild UI
3. **Offline**: Nếu offline, Firestore sẽ cache và sync khi online lại
4. **Accuracy**: `learnedCount` luôn chính xác vì được tính từ Firestore

## API Reference

### DeckService

```dart
// Cập nhật learnedCount cho một deck
Future<void> updateLearnedCount(String deckId)

// Cập nhật learnedCount cho tất cả decks
Future<void> updateAllLearnedCounts()

// Tăng reviewCount và tự động cập nhật learnedCount
Future<void> incrementReviewCount(String deckId, String flashcardId)
```

### ReviewService

```dart
// Đánh dấu một từ đã được ôn tập
Future<void> markAsReviewed({
  required String deckId,
  required String flashcardId,
})

// Sync learnedCount cho một deck
Future<void> syncLearnedCount(String deckId)

// Sync learnedCount cho tất cả decks
Future<void> syncAllLearnedCounts()
```
