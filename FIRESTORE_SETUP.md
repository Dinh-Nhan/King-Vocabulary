# Hướng dẫn sửa lỗi Firestore

## Lỗi: [cloud_firestore/unknown]

Lỗi này thường xảy ra khi:

### 1. Firestore chưa được kích hoạt

**Cách sửa:**
1. Mở [Firebase Console](https://console.firebase.google.com/)
2. Chọn project: `king-vocabulary`
3. Vào **Firestore Database** ở menu bên trái
4. Nếu chưa có, nhấn **Create database**
5. Chọn **Start in test mode** (hoặc production mode)
6. Chọn location gần nhất (ví dụ: `asia-southeast1`)

### 2. Firestore Rules chưa đúng

**Cách kiểm tra:**
1. Vào Firebase Console → Firestore Database → Rules
2. Kiểm tra rules hiện tại

**Rules đề xuất cho development:**
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Cho phép user đọc/ghi dữ liệu của chính họ
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Hoặc cho phép tất cả (chỉ dùng khi test)
    // match /{document=**} {
    //   allow read, write: if request.auth != null;
    // }
  }
}
```

**Rules cho production (an toàn hơn):**
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/decks/{deckId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    match /users/{userId}/decks/{deckId}/words/{wordId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 3. Kiểm tra kết nối

Chạy lệnh sau để xem log chi tiết:
```bash
flutter run --verbose
```

Hoặc xem log trong Android Studio / VS Code console.

### 4. Test Firestore connection

Thêm code test vào `main.dart`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Test Firestore connection
  try {
    final db = FirebaseFirestore.instance;
    print('✅ Firestore initialized');

    // Test write
    await db.collection('test').doc('test').set({'test': 'value'});
    print('✅ Firestore write OK');

    // Test read
    final doc = await db.collection('test').doc('test').get();
    print('✅ Firestore read OK: ${doc.data()}');
  } catch (e) {
    print('❌ Firestore error: $e');
  }

  runApp(MyApp());
}
```

### 5. Các lỗi thường gặp khác

**Lỗi: permission-denied**
- Firestore Rules không cho phép truy cập
- User chưa đăng nhập

**Lỗi: unavailable**
- Không có internet
- Firestore chưa được kích hoạt
- Firebase project không tồn tại

**Lỗi: not-found**
- Collection hoặc document không tồn tại
- Đường dẫn sai

## Checklist

- [ ] Firestore đã được kích hoạt trong Firebase Console
- [ ] Firestore Rules đã được cấu hình
- [ ] User đã đăng nhập (check `FirebaseAuth.instance.currentUser`)
- [ ] Internet đang hoạt động
- [ ] Package `cloud_firestore` đã được cài đặt trong `pubspec.yaml`
- [ ] Đã chạy `flutter pub get`
- [ ] Đã rebuild app sau khi thay đổi cấu hình
