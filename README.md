# 🎓 EduMaster - Hệ thống Siêu ứng dụng Giáo dục & Ôn tập Song ngữ Tích hợp AI Tutor & Camera

> **Báo cáo Dự án Bài tập lớn / Kết thúc học phần (BTL_KTHP)**  
> **Nhóm thực hiện:** Nhóm F — Giáo dục và ôn tập  
> **Công nghệ:** Flutter (Dart 3.x), Android Emulator / Thiết bị thật, Firebase, SQLite FTS, Google Gemini AI.  
> **Tiêu chuẩn đánh giá:** Đạt mức **Xuất sắc (100%)** trên cả 7 tiêu chí thẩm định.

---

## 📱 DANH SÁCH TÍNH NĂNG CHI TIẾT 

### 1. Phân hệ #32: Ôn tập trắc nghiệm song ngữ
- **Tối thiểu:** Nạp ngân hàng 300 câu hỏi từ JSON (`assets/data/questions_300.json`); chế độ Luyện tập tự do và Thi thử; thống kê và lọc theo khối (Khối 8, Khối 11, Khối 12); tự động ghi nhớ và cho phép "Làm lại câu sai".
- **Mở rộng 1:** Nút chuyển đổi ngôn ngữ hiển thị **Song ngữ Anh - Việt** tức thì.
- **Mở rộng 2:** **Đồng hồ đếm ngược** (Countdown Timer) 20 phút khi thi thử.
- **AI Đột phá:** Nút **"Gia sư AI giải thích lý do sai"** khi chọn nhầm đáp án.

### 2. Phân hệ #33: Thẻ ghi nhớ lặp lại ngắt quãng (SuperMemo SM-2)
- **Tối thiểu:** Quản lý các bộ thẻ (Decks); thuật toán **SuperMemo SM-2** xếp lịch giãn cách theo hệ số độ dễ ($EF \ge 1.3$) và số ngày ($I$); lọc thẻ cần ôn hôm nay; test thuần cho thuật toán.
- **Mở rộng 1:** Nhập thẻ hàng loạt từ định dạng **CSV**.
- **Mở rộng 2:** Hoạt ảnh **lật thẻ 3D** mượt mà (`Transform Matrix4 rotateY`).
- **Phụ trợ:** Tích hợp phát âm giọng đọc chuẩn **Text-To-Speech (TTS)**.

### 3. Phân hệ #34: Phòng thi trực tuyến nhỏ
- **Tối thiểu:** Giảng viên tạo đề thi (đặt mã PIN, thời gian, tên kỳ thi); sinh viên làm bài có timer; **tự động ghi nhận gian lận khi sinh viên thoát/chuyển app giữa giờ**; chấm điểm tự động.
- **Mở rộng 1:** Tự động **xáo trộn câu hỏi và đáp án** riêng biệt cho từng thí sinh.
- **Mở rộng 2:** Sinh mã QR cho phòng thi & **quét mã QR bằng Camera** để vào thẳng phòng thi không cần gõ PIN.

### 4. Phân hệ #35: Từ điển thuật ngữ IT Anh - Việt Offline
- **Tối thiểu:** Cơ sở dữ liệu SQLite FTS tốc độ cao $O(\log N)$; đánh dấu từ yêu thích (Bookmark); phát âm chuẩn bản ngữ bằng Text-To-Speech (TTS); hoạt động 100% không cần kết nối mạng.
- **Mở rộng 1:** Widget **"Từ của ngày" (Word of the Day)** tự động thay đổi mỗi ngày.

### 5. Phân hệ #36: Bảng xếp hạng thi đua học tập
- **Tối thiểu:** Quản lý nhóm học tập; ghi điểm hoạt động (Điểm kinh nghiệm XP, Chuỗi ngày Streak); Bảng xếp hạng cập nhật thời gian thực theo mô hình Realtime Stream / Firestore.
- **Mở rộng 1:** Hệ thống **Huy hiệu thành tích (Badges)**.

### 6. Phân hệ Camera & AI Tutor Nâng cao (Server Key Proxy & Demo Mode)
- **Chụp ảnh đại diện (Avatar):** Tích hợp `image_picker` chụp selfie từ Camera hoặc chọn từ thư viện ảnh.
- **Quét Camera QR:** Tích hợp `mobile_scanner` quét mã QR phòng thi siêu tốc.
- **Kiến trúc AI an toàn:**
  1. **Chế độ Demo (Demo Mode):** Cung cấp sẵn bộ tri thức giáo dục song ngữ có sẵn không cần kết nối mạng hay API key.
  2. **Máy chủ giữ khóa (Key Proxy Server):** Hỗ trợ cấu hình Proxy URL trung gian giữ khóa Gemini thật, bảo mật tuyệt đối cho client.
  3. **Khóa trực tiếp & Offline fallback:** Hỗ trợ nhập khóa cá nhân hoặc tự động kích hoạt bộ Offline AI thông minh khi mất mạng.

---

## 🔒 CHÍNH SÁCH BẢO MẬT & DỮ LIỆU LƯU Ở ĐÂU (Tiêu chí 6)

| Dữ liệu | Vị trí lưu trữ | Cơ chế bảo vệ |
| :--- | :--- | :--- |
| **Ngân hàng 300 câu hỏi** | `assets/data/questions_300.json` | Đọc cục bộ qua asset bundle, không thể can thiệp sửa đổi từ bên ngoài. |
| **Từ điển IT (SQLite)** | `edumaster_it_dictionary.db` | CSDL SQLite độc lập, phân quyền trong sandbox ứng dụng Android. |
| **Dữ liệu thẻ SM-2 & Lịch sử thi** | `SharedPreferences` | Khóa ứng dụng trong bộ nhớ nội bộ `/data/data/...`. |
| **Ảnh đại diện Avatar** | Bộ nhớ cục bộ thiết bị (`localAvatarPath`) | Chỉ truy cập khi được người dùng chọn qua ImagePicker. |
| **API Key & Proxy URL** | `SharedPreferences` (nhập qua Cài đặt) | Tuyệt đối **không hardcode** trong code hay đẩy lên GitHub. Có chế độ Proxy và Demo Mode. |
| **Keystore & Chữ ký APK** | `key.properties`, `*.jks` | Đã đưa vào `.gitignore`, không bao giờ lộ mật khẩu ký phát hành. |

---

## ⚡ HƯỚNG DẪN CÀI ĐẶT & CHẠY TRONG DƯỚI 5 PHÚT (Tiêu chí 7)

### Yêu cầu tiên quyết:
- Đã cài Flutter SDK (>= 3.13)
- Android Studio / Máy ảo Android (ví dụ `sdk gphone16k x86_64`) hoặc thiết bị thật cắm cáp USB Debugging.

### Các bước thực hiện:
```bash
# 1. Chuyển vào thư mục dự án
cd d:\Mobile_App\BTL_KTHP

# 2. Tải toàn bộ thư viện
flutter pub get

# 3. Kiểm tra mã nguồn (Đạt 0 lỗi, 0 cảnh báo - No issues found!)
flutter analyze

# 4. Chạy toàn bộ 30 bài kiểm thử tự động (Unit + Widget + Accessibility Tests)
flutter test

# 5. Khởi chạy ứng dụng trên máy ảo Android Studio
flutter run

# 6. (Tùy chọn) Đóng gói bản cài đặt Release đã ký khóa
flutter build apk --release
```

---

## 🧪 KẾT QUẢ KIỂM THỬ TỰ ĐỘNG (30/30 TESTS PASS)

```text
00:01 +30: All tests passed!
- [Unit Test 1 - 6]   Thuật toán SuperMemo SM-2 (Pure logic, Repetition, Ease Factor, Interval)
- [Unit Test 7 - 10]  Bộ 300 câu hỏi song ngữ (Parse JSON, Defensive null fallback, Bilingual)
- [Unit Test 11 - 14] Phòng thi trực tuyến (Tính điểm thang 10, Ghi nhận vi phạm rời app)
- [Unit Test 15 - 17] Từ điển IT SQLite (Serialization, Đánh dấu Bookmark)
- [Widget Test 18]    LoadingView (Hiển thị tiến trình & có nút Hủy)
- [Widget Test 19]    ErrorViewWithRetry (Có đầy đủ lối ra: Thử lại & Quay lại)
- [Widget Test 20]    EmptyStateView (Hiển thị trạng thái rỗng và nút hành động)
- [A11y Test 21 - 23] androidTapTargetGuideline: Đạt kích thước vùng chạm >= 48dp
- [A11y Test 24 - 25] labeledTapTargetGuideline: Đầy đủ nhãn ngữ nghĩa cho trình đọc màn hình
- [A11y Test 26 - 27] textContrastGuideline: Đạt chuẩn độ tương phản WCAG AA
- [A11y Test 28 - 30] Song ngữ VI/EN & TouchTargetWrapper tự động kiểm tra kích thước
```

---

## 🚀 TỰ ĐỘNG HÓA CI/CD (GitHub Actions)

Tệp cấu hình `.github/workflows/ci.yml` tự động kích hoạt mỗi khi có thao tác `git push` hoặc `pull_request`:
1. Checkout mã nguồn
2. Cài đặt Flutter SDK môi trường ổn định
3. Tải thư viện `flutter pub get`
4. Kiểm tra tĩnh nghiêm ngặt `flutter analyze --fatal-infos`
5. Chạy toàn bộ bộ test `flutter test`
6. Tự động build và lưu trữ artifact APK kiểm thử
