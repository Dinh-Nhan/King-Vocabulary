# Auto Refresh HomeScreen - Giải thích

## Vấn đề

Khi dùng `Navigator.push/pop`, màn hình HomeScreen không tự động cập nhật vì:
- HomeScreen đã được tạo từ trước
- StreamBuilder chỉ rebuild khi có event mới từ Firestore
- Khi pop về, không có trigger nào để refresh data

## Giải pháp

Đã implement **3 cơ chế tự động refresh**:

### 1. RouteAware - Refresh khi pop về

```dart
class _HomeScreenState extends State<HomeScreen> with RouteAware {
  @override
  void didPopNext() {
    // Được gọi khi pop về màn hình này
    _updateLearnedCountsOnce();
  }
}
```

**Khi hoạt động:**
- User vào ListVocabularyScreen
- User nhấn back
- `didPopNext()` được gọi
- Tự động refresh data

### 2. WidgetsBindingObserver - Refresh khi app resume

```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    _updateLearnedCountsOnce();
  }
}
```

**Khi hoạt động:**
- User thoát app (home button)
- User quay lại app
- Tự động refresh data

### 3. Await Navigator - Refresh thủ công

```dart
Future<void> _onDeckTap(...) async {
  await Navigator.push(...);

  // Khi quay về, refresh
  if (mounted) {
    setState(() {});
  }
}
```

**Khi hoạt động:**
- Backup cho RouteAware
- Đảm bảo refresh ngay cả khi RouteAware fail

## Cách hoạt động

### Flow khi user vào ListVocabularyScreen và quay về:

```
1. User tap vào deck
   ↓
2. Navigator.push(ListVocabularyScreen)
   ↓
3. User xem/chỉnh sửa từ
   ↓
4. User nhấn back
   ↓
5. Navigator.pop()
   ↓
6. didPopNext() được gọi ← RouteAware
   ↓
7. _updateLearnedCountsOnce()
   ↓
8. DeckService.updateAllLearnedCounts()
   ↓
9. Firestore cập nhật learnedCount
   ↓
10. StreamBuilder nhận event mới
   ↓
11. UI rebuild với data mới ✅
```

## Setup cần thiết

### 1. Thêm RouteObserver vào app.dart

```dart
// Global observer
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [routeObserver], // ← Thêm dòng này
      ...
    );
  }
}
```

### 2. Subscribe trong HomeScreen

```dart
class _HomeScreenState extends State<HomeScreen> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route); // ← Subscribe
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this); // ← Unsubscribe
    super.dispose();
  }
}
```

## Test

### Test 1: Pop từ ListVocabularyScreen

```
1. Vào HomeScreen → Thấy "0/5 từ"
2. Tap vào deck
3. Vào ListVocabularyScreen
4. Thêm/xóa/sửa từ
5. Nhấn back
6. Kiểm tra console: "🔄 HomeScreen: didPopNext - Refreshing data..."
7. Thấy số từ cập nhật ✅
```

### Test 2: App resume

```
1. Vào HomeScreen
2. Nhấn home button (thoát app)
3. Mở app khác, học từ bằng cách khác
4. Quay lại app
5. Data tự động refresh ✅
```

### Test 3: Await Navigator

```
1. Vào HomeScreen
2. Tap vào deck
3. Quay về
4. Nếu RouteAware không hoạt động, await Navigator vẫn trigger refresh ✅
```

## Debug

Nếu không refresh, kiểm tra:

### 1. Console log

Khi pop về, phải thấy:
```
🔄 HomeScreen: didPopNext - Refreshing data...
```

Nếu không thấy → RouteObserver chưa được setup đúng

### 2. Kiểm tra navigatorObservers

```dart
// Trong app.dart
MaterialApp(
  navigatorObservers: [routeObserver], // ← Phải có dòng này
  ...
)
```

### 3. Kiểm tra subscribe/unsubscribe

```dart
// Trong HomeScreen
@override
void didChangeDependencies() {
  routeObserver.subscribe(this, route); // ← Phải có
}

@override
void dispose() {
  routeObserver.unsubscribe(this); // ← Phải có
  super.dispose();
}
```

## Performance

- ✅ **Hiệu quả**: Chỉ refresh khi cần (khi pop về)
- ✅ **Không ảnh hưởng UX**: Refresh diễn ra trong background
- ✅ **Debounce**: `_isUpdatingCounts` flag ngăn refresh nhiều lần
- ⚠️ **Lưu ý**: Nếu có nhiều deck (>50), có thể hơi chậm

## Tối ưu hóa (nếu cần)

Nếu refresh chậm:

1. **Chỉ refresh deck đã xem**:
```dart
void didPopNext() {
  // Chỉ refresh deck vừa xem thay vì tất cả
  if (_lastViewedDeckId != null) {
    _deckService.updateLearnedCount(_lastViewedDeckId);
  }
}
```

2. **Cache trong memory**:
```dart
// Cache learnedCount, chỉ sync với Firestore định kỳ
```

3. **Debounce refresh**:
```dart
// Chỉ refresh sau 500ms để tránh spam
Timer? _refreshTimer;
void didPopNext() {
  _refreshTimer?.cancel();
  _refreshTimer = Timer(Duration(milliseconds: 500), () {
    _updateLearnedCountsOnce();
  });
}
```

Nhưng với app học từ vựng thông thường, không cần tối ưu.
