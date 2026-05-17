# Test LearnedCount Realtime Update

## Vấn đề đã sửa

**Trước**: `learnedCount` không cập nhật realtime, phải reload app mới thấy thay đổi

**Sau**: `learnedCount` cập nhật ngay lập tức khi user ôn từ

## Cách test

### 1. Tạo bộ từ mới với vài từ

```
1. Vào HomeScreen
2. Nhấn "Tạo bộ từ"
3. Nhập tên: "Test Deck"
4. Thêm 3-5 từ
5. Nhấn "Lưu"
```

Kết quả: Hiển thị "0/5 từ" (chưa học từ nào)

### 2. Học một từ (giả lập)

Vì chưa có màn hình học, hãy test bằng code:

```dart
// Trong màn hình nào đó, thêm button test:
ElevatedButton(
  onPressed: () async {
    final reviewService = ReviewService();

    // Lấy deck đầu tiên
    final decks = await DeckService().watchDecks().first;
    if (decks.isEmpty) return;

    final deck = decks.first;

    // Lấy từ đầu tiên
    final words = await DeckService().watchFlashcards(deck.deckId).first;
    if (words.isEmpty) return;

    final word = words.first;

    // Đánh dấu đã học
    await reviewService.markAsReviewed(
      deckId: deck.deckId,
      flashcardId: word.flashcardId,
    );

    print('✅ Đã đánh dấu từ "${word.frontContent}" là đã học');
  },
  child: Text('Test: Học từ đầu tiên'),
)
```

### 3. Kiểm tra kết quả

**Mong đợi**:
- HomeScreen tự động cập nhật từ "0/5 từ" → "1/5 từ"
- Progress bar tăng lên
- **KHÔNG CẦN reload app**

### 4. Test nhiều lần

Nhấn button test nhiều lần (với các từ khác nhau):
- Lần 1: "1/5 từ"
- Lần 2: "2/5 từ"
- Lần 3: "3/5 từ"
- ...

Mỗi lần phải cập nhật ngay lập tức.

## Cách hoạt động

### Flow cập nhật:

```
User ôn từ
    ↓
reviewService.markAsReviewed()
    ↓
DeckService.incrementReviewCount()
    ↓
1. Cập nhật reviewCount trong Firestore (flashcard)
2. Đếm lại số từ có reviewCount > 0
3. Cập nhật learnedCount trong Firestore (deck)
    ↓
Firestore trigger snapshot
    ↓
StreamBuilder rebuild
    ↓
UI cập nhật ngay lập tức ✅
```

### Tại sao realtime?

1. **StreamBuilder** lắng nghe `watchDecks()` stream
2. Khi `learnedCount` thay đổi trong Firestore → Firestore emit event mới
3. StreamBuilder nhận event → rebuild widget
4. UI hiển thị số mới

## Nếu vẫn không hoạt động

### Kiểm tra 1: Firestore Rules

Đảm bảo rules cho phép update:

```javascript
match /users/{userId}/decks/{deckId} {
  allow read, write: if request.auth.uid == userId;
}

match /users/{userId}/decks/{deckId}/words/{wordId} {
  allow read, write: if request.auth.uid == userId;
}
```

### Kiểm tra 2: Internet connection

Firestore cần internet để sync. Nếu offline:
- Thay đổi sẽ được cache
- Khi online lại sẽ sync và cập nhật

### Kiểm tra 3: Console log

Thêm log để debug:

```dart
// Trong DeckService.updateLearnedCount()
print('🔄 Updating learnedCount for deck: $deckId');
print('📊 New learnedCount: $learnedCount');

// Trong ReviewService.markAsReviewed()
print('✅ Marked as reviewed: $flashcardId');
```

### Kiểm tra 4: Firestore Console

Vào Firebase Console → Firestore → Xem document:
- `users/{uid}/decks/{deckId}`
- Kiểm tra field `learnedCount` có thay đổi không

## Performance

- ✅ **Nhanh**: Chỉ query 1 lần để đếm words
- ✅ **Hiệu quả**: Không query lại toàn bộ decks
- ✅ **Realtime**: StreamBuilder tự động rebuild
- ⚠️ **Lưu ý**: Nếu có nhiều từ (>1000), có thể hơi chậm khi đếm

## Tối ưu hóa (nếu cần)

Nếu app chậm khi có nhiều từ, có thể:

1. **Cache learnedCount**: Lưu trong memory, chỉ sync định kỳ
2. **Debounce**: Chỉ cập nhật sau 1-2 giây
3. **Background sync**: Dùng Cloud Functions để tính

Nhưng với app học từ vựng thông thường (<500 từ/deck), không cần tối ưu.
