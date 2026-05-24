# Hướng dẫn Import Từ Vựng

Tài liệu mô tả các định dạng file và cấu trúc dữ liệu được hỗ trợ khi import từ vựng vào King Vocabulary.

---

## Các định dạng file được hỗ trợ

| Định dạng | Mô tả |
|-----------|-------|
| `.xlsx` | File Excel |
| `.csv` | Comma-Separated Values |
| `.txt` | Plain text |
| Dán văn bản | Paste trực tiếp vào ô văn bản (cùng logic với `.txt`) |

---

## 1. File Excel (`.xlsx`)

Đọc **sheet đầu tiên** trong file. Mỗi dòng là một từ vựng:

- **Cột A** → Từ tiếng Anh (front)
- **Cột B** → Nghĩa tiếng Việt (back)
- Các cột từ C trở đi bị bỏ qua
- Dòng nào có cột A hoặc cột B trống sẽ bị bỏ qua

**Ví dụ:**

| A | B |
|---|---|
| apple | quả táo |
| banana | quả chuối |
| run | chạy |

> ⚠️ **Lưu ý:** Nếu file có dòng header (tiêu đề cột), dòng đó sẽ bị import thành một từ vựng. Hãy xóa dòng header trước khi import hoặc kiểm tra lại ở tab Nhập tay.

---

## 2. File CSV (`.csv`)

Mỗi dòng là một từ vựng, các cột phân cách bằng dấu phẩy:

- **Cột 0** → Từ tiếng Anh
- **Cột 1** → Nghĩa tiếng Việt
- Dòng nào có ít hơn 2 cột sẽ bị bỏ qua

**Ví dụ:**

```
apple,quả táo
banana,quả chuối
run,chạy
```

Hỗ trợ giá trị có dấu phẩy bên trong nếu được bọc trong dấu ngoặc kép (chuẩn CSV):

```
"good morning","chào buổi sáng"
"by the way","nhân tiện"
```

> ⚠️ **Lưu ý:** Tương tự Excel, dòng header sẽ bị import thành từ vựng nếu có.

---

## 3. File TXT (`.txt`) và Dán văn bản

Mỗi dòng là một từ vựng. Hỗ trợ **4 dạng delimiter**, được nhận diện theo thứ tự ưu tiên:

### Thứ tự ưu tiên delimiter

| Thứ tự | Delimiter | Ký hiệu |
|--------|-----------|---------|
| 1 | Gạch ngang có khoảng trắng | ` - ` |
| 2 | Dấu hai chấm có khoảng trắng | `: ` |
| 3 | Tab | `\t` |
| 4 | Dấu phẩy | `,` |

> Nếu một dòng chứa nhiều loại delimiter, loại có thứ tự ưu tiên cao hơn sẽ được dùng.

---

### Dạng 1: Gạch ngang ` - `

```
apple - quả táo
banana - quả chuối
good morning - chào buổi sáng
```

Nghĩa có thể chứa ` - ` mà không bị cắt:

```
run - chạy - di chuyển nhanh
```
→ front: `run`, back: `chạy - di chuyển nhanh` ✅

---

### Dạng 2: Dấu hai chấm `: `

```
apple: quả táo
banana: quả chuối
```

Nghĩa có thể chứa `: ` mà không bị cắt:

```
note: ghi chú: lưu ý
```
→ front: `note`, back: `ghi chú: lưu ý` ✅

---

### Dạng 3: Tab `\t`

Thường xuất hiện khi copy từ Excel hoặc Google Sheets:

```
apple	quả táo
banana	quả chuối
```

> ⚠️ Chỉ lấy cột 1 và cột 2. Nếu có thêm cột từ cột 3 trở đi, chúng sẽ bị bỏ qua.

---

### Dạng 4: Dấu phẩy `,`

```
apple,quả táo
banana,quả chuối
```

Nghĩa có thể chứa dấu phẩy mà không bị cắt:

```
apple,quả táo, trái táo
```
→ front: `apple`, back: `quả táo, trái táo` ✅

---

## Các trường hợp bị bỏ qua

| Trường hợp | Hành vi |
|------------|---------|
| Dòng trống | Bỏ qua |
| Dòng không có delimiter nào | Bỏ qua |
| Cột front hoặc back trống sau khi trim | Bỏ qua |
| File `.docx`, `.pdf`, `.json`... | Không được hỗ trợ, trả về danh sách rỗng |

---

## Lưu ý chung

- Sau khi import, tất cả từ vựng sẽ được hiển thị ở tab **Nhập tay** để bạn kiểm tra và chỉnh sửa trước khi lưu.
- Nếu app báo "Không tìm thấy từ nào", hãy kiểm tra lại định dạng file theo hướng dẫn trên.
- Khuyến nghị dùng định dạng ` - ` (gạch ngang) khi tạo file `.txt` thủ công vì dễ đọc và ít xung đột nhất.
