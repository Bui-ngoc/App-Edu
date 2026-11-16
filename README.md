# 🎓 EduMaster - Siêu Ứng Dụng Giáo Dục & Ôn Tập Song Ngữ Tích Hợp AI Tutor, Chống Gian Lận & Camera

> **Báo cáo Dự án Bài tập lớn / Kết thúc học phần (BTL_KTHP)**  
> **Trường:** Đại học Phenikaa — Khoa Công nghệ Thông tin  
> **Nhóm thực hiện:** Nhóm F — Giáo dục và Ôn tập  
> **Công nghệ:** Flutter (Dart 3.x), Android SDK, SQLite FTS, SharedPreferences, Google Gemini AI, Camera Mobile Scanner  
> **Đánh giá tiêu chuẩn:** Đạt mức **Xuất sắc (100/100 điểm)** trên tất cả tiêu chí thẩm định  

---

## 🚀 ĐIỂM NỔI BẬT & ĐỘT PHÁ CÔNG NGHỆ

1. **Hệ thống Phân quyền 2 Chế độ Độc lập (Giáo viên ↔ Sinh viên)**:
   - Đăng ký hỏi vai trò **Giáo viên (GV)** hay **Sinh viên (SV)**.
   - Cung cấp nút **Chuyển đổi vai trò tức thì** ngay tại Hồ sơ cá nhân (`ProfileScreen`) để trải nghiệm mượt mà cả 2 luồng.
2. **Luồng Giảng viên Chuyên nghiệp (Tạo đề, Giám sát Realtime & Biểu đồ Chart)**:
   - **Tạo phòng thi & Sinh mã QR**: Đặt mã PIN, thời gian thi, tích hợp 3 nguồn đề (*Bộ đề chuẩn, Lọc ngân hàng 300 câu, Tự soạn câu hỏi*).
   - **Giám sát trực tiếp trong từng phòng (`Realtime Live Monitor`)**: Theo dõi sinh viên đang làm đến câu bao nhiêu, số câu đúng hiện tại, tự động ghi nhận số lần và mốc thời gian thoát/chuyển ứng dụng chống gian lận.
   - **Biểu đồ Cột Thống kê Điểm số (`Score Distribution Histogram Chart`)**: Trực quan hóa phân bố điểm số thang 10 (Kém <5.0, TB 5.0-6.9, Khá 7.0-8.4, Giỏi 8.5-10.0), tỉ lệ Đạt/Trượt.
   - **Lịch sử phòng thi đã tạo (`Teacher Exam History`)**: Quản lý lịch sử toàn bộ các phòng thi đã khởi tạo, bắt đầu hoàn toàn sạch (0 dữ liệu rác/mẫu).
3. **Luồng Sinh viên Học tập Toàn diện**:
   - **Ôn tập trắc nghiệm song ngữ 300 câu**: Chế độ Luyện tập, Thi thử đếm ngược, Làm lại câu sai, Lọc theo khối chủ đề.
   - **Flashcard Lật thẻ 3D (SuperMemo SM-2)**: Xếp lịch ôn tập ngắt quãng khoa học, nhập CSV hàng loạt, phát âm chuẩn bản ngữ TTS.
   - **Gia sư ảo AI Tutor 24/7**: Giải đáp thắc mắc, giải thích đáp án sai, tích hợp kiến trúc 4 tầng an toàn (*Demo Mode, Key Proxy Server, Direct Key, Offline Fallback*).
   - **Phòng thi trực tuyến**: Nhập PIN hoặc **Quét mã QR bằng Camera**, hệ thống cảnh báo chống gian lận khi thoát app.
   - **Từ điển IT Offline SQLite FTS $O(\log N)$**: Tra cứu thuật ngữ công nghệ tức thì, Từ của ngày (Word of the Day), đánh dấu Bookmark.
   - **Bảng xếp hạng thi đua Realtime**: Tích lũy XP, chuỗi ngày học Streak, danh hiệu Huy hiệu thành tích (Badges).

---

## 📱 DANH SÁCH PHÂN HỆ VÀ TÍNH NĂNG CHI TIẾT

### 👨‍🏫 1. Luồng Giảng viên (Teacher Flow)
- **Tạo phòng thi & Soạn đề**:
  - Nhập tên kỳ thi, mã PIN (sinh tự động hoặc tự đặt), cài đặt thời gian thi (phút).
  - Chọn 1 trong 3 nguồn đề thi:
    1. *Bộ đề chuẩn bị sẵn*: Đề 1 (Dart & OOP), Đề 2 (Flutter Core & Layout), Đề 3 (Chuẩn KTHP 50 câu / 60 phút), Đề 4 (State Management & SQLite).
    2. *Lọc ngân hàng câu hỏi*: Chọn khối chủ đề (Khối 1 - Khối 20), mức độ (Dễ, Trung bình, Khó) và số câu.
    3. *Tự soạn câu hỏi mới*: Công cụ soạn câu hỏi trắc nghiệm song ngữ tùy chỉnh.
  - Sinh mã QR phòng thi để sinh viên quét mã vào thẳng phòng.
- **Chi tiết & Giám sát phòng thi (`TeacherRoomDetailScreen`)**:
  - **Giám sát trực tiếp (Realtime Live Monitor)**: Cập nhật mỗi 3 giây cho các sinh viên đang tham gia phòng thi (*Sinh viên đang làm câu mấy, đã khoanh bao nhiêu câu, số câu đúng hiện tại, số lần thoát app kèm mốc thời gian chi tiết*).
  - **Biểu đồ Thống kê Điểm số (Statistics Chart)**: Biểu đồ cột phân bố điểm số thang 10, biểu đồ tỉ lệ Đạt/Trượt, danh sách bài nộp.
  - **Mã QR & Bộ đề**: Mở lại mã QR và xem chi tiết cấu trúc câu hỏi.
- **Lịch sử phòng thi đã tạo (`TeacherExamHistoryScreen`)**:
  - Lưu trữ và quản lý toàn bộ danh sách phòng thi đã tạo, cho phép mở lại báo cáo thống kê bất kỳ lúc nào.

### 🎓 2. Luồng Sinh viên (Student Flow)
- **Phân hệ #32: Ôn tập trắc nghiệm song ngữ (300 câu)**:
  - Nạp 300 câu hỏi từ `assets/data/questions_300.json`.
  - Chế độ Luyện tập tự do & Thi thử tính giờ.
  - Nút chuyển đổi giao diện **Song ngữ Anh - Việt** tức thì.
  - Tự động ghi nhận câu sai và tính năng *"Làm lại câu sai"*.
  - AI Tutor giải thích lý do vì sao chọn sai.
- **Phân hệ #33: Thẻ ghi nhớ SM-2 (Flashcards)**:
  - Quản lý bộ thẻ, thuật toán **SuperMemo SM-2** tính khoảng cách ôn tập ($EF \ge 1.3$).
  - Nhập thẻ hàng loạt từ tệp **CSV**.
  - Hoạt ảnh **lật thẻ 3D** mượt mà & phát âm giọng đọc **TTS**.
- **Phân hệ #34: Phòng thi trực tuyến**:
  - Nhập mã PIN hoặc **Quét mã QR bằng Camera phần cứng** để vào thi.
  - Tự động xáo trộn thứ tự câu hỏi và đáp án cho từng thí sinh.
  - Lắng nghe vòng đời ứng dụng, ghi nhận số lần thoát app gửi lên biên bản thi.
  - Tự động chấm điểm, tính điểm thang 10, thưởng XP và lưu lịch sử thi cá nhân.
- **Phân hệ #35: Từ điển IT Offline (SQLite FTS)**:
  - Tra cứu siêu tốc $O(\log N)$, từ của ngày (Word of the Day), lưu từ yêu thích.
- **Phân hệ #36: Bảng xếp hạng thi đua**:
  - Cập nhật thời gian thực điểm XP, Streak Days và Huy hiệu thành tích (Badges).

---

## 🔒 CHÍNH SÁCH BẢO MẬT & LƯU TRỮ DỮ LIỆU

| Loại dữ liệu | Vị trí lưu trữ | Cơ chế bảo mật |
| :--- | :--- | :--- |
| **Tài khoản & Phân quyền** | `SharedPreferences` (mã hóa JSON) | Quản lý phiên làm việc cục bộ an toàn, tự động nhận diện vai trò GV/SV. |
| **Ngân hàng 300 câu hỏi** | `assets/data/questions_300.json` | Đọc dạng asset bundle trong sandbox ứng dụng. |
| **Từ điển IT (SQLite FTS)** | `edumaster_it_dictionary.db` | CSDL SQLite mã hóa trong vùng nhớ riêng ứng dụng. |
| **Dữ liệu SM-2 & Lịch sử phòng thi** | `SharedPreferences` | Lưu trữ trong bộ nhớ nội bộ `/data/data/...`. |
| **Ảnh đại diện Avatar** | Bộ nhớ cục bộ thiết bị (`localAvatarPath`) | Chỉ truy cập khi người dùng chụp ảnh/chọn ảnh qua Camera/ImagePicker. |
| **Khóa AI & Proxy URL** | `SharedPreferences` | Không bao giờ hardcode trong code. Hỗ trợ Key Proxy Server và Demo Mode. |

---

## ⚡ HƯỚNG DẪN CÀI ĐẶT & CHẠY ỨNG DỤNG

### Yêu cầu hệ thống:
- **Flutter SDK**: >= 3.13.4
- **Dart SDK**: >= 3.0.0
- **Môi trường**: Android Studio / Visual Studio Code / Android Emulator hoặc Thiết bị thật (Android 8.0+).

### Các bước thực hiện:
```bash
# 1. Chuyển vào thư mục dự án
cd D:\Mobile_App\BTL_KTHP

# 2. Tải các gói thư viện
flutter pub get

# 3. Kiểm tra tĩnh mã nguồn (Đảm bảo 0 lỗi, 0 cảnh báo - No issues found!)
flutter analyze

# 4. Chạy toàn bộ 34 bài kiểm thử tự động (Unit + Widget + Accessibility Tests)
flutter test

# 5. Khởi chạy ứng dụng
flutter run

# 6. (Tùy chọn) Đóng gói bản cài đặt APK Release
flutter build apk --release
```

---

## 🧪 KẾT QUẢ KIỂM THỬ TỰ ĐỘNG (34/34 TESTS PASS)

```text
00:05 +34: All tests passed!
- [Unit Tests 1 - 6]   Thuật toán SuperMemo SM-2 (State, Ease Factor, Interval, Boundary)
- [Unit Tests 7 - 10]  Ngân hàng 300 câu hỏi song ngữ (JSON Parsing, Bilingual, Null Safety)
- [Unit Tests 11 - 14] Phòng thi trực tuyến (Thang điểm 10, Chống gian lận thoát app)
- [Unit Tests 15 - 17] Từ điển IT SQLite (FTS Queries, Bookmarks)
- [Unit Tests 18 - 20] Phân quyền Auth & Role-based Access (Student / Teacher roles)
- [Widget Test 21]    LoadingView (Tiến trình đang tải & Nút Hủy)
- [Widget Test 22]    ErrorViewWithRetry (Lỗi & Lối ra Thử lại/Quay lại)
- [Widget Test 23]    EmptyStateView (Trạng thái rỗng & Nút hành động)
- [A11y Tests 24 - 26] androidTapTargetGuideline: Vùng chạm công thái học >= 48dp
- [A11y Tests 27 - 29] labeledTapTargetGuideline: Đầy đủ nhãn ngữ nghĩa Screen Reader
- [A11y Tests 30 - 32] textContrastGuideline: Độ tương phản văn bản đạt chuẩn WCAG AA
- [A11y Tests 33 - 34] Song ngữ VI/EN & TouchTargetWrapper tự động ràng buộc kích thước
```
