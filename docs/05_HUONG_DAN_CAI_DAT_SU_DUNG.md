# 🚀 HƯỚNG DẪN CÀI ĐẶT, VẬN HÀNH & SỬ DỤNG
## DỰ ÁN EDUMASTER — BTL_KTHP (TIÊU CHÍ 7 XUẤT SẮC)

> **Mục tiêu:** Đảm bảo bất kỳ người khác (giảng viên, giám khảo, sinh viên) đều có thể cài đặt và chạy thành công ứng dụng **trong vòng dưới 5 phút** theo tài liệu hướng dẫn.

---

## 1. YÊU CẦU MÔI TRƯỜNG TIÊN QUYẾT (PREREQUISITES)

* **Hệ điều hành:** Windows 10/11, macOS hoặc Linux.
* **Flutter SDK:** Phiên bản ổn định $\ge 3.13.x$ (Đã kiểm thử tối ưu trên Flutter 3.27.x / 3.47.x).
* **JDK:** Java Development Kit 17 hoặc 21 (Hỗ trợ Gradle 8.x / 9.x).
* **Thiết bị chạy:**
  * **Máy ảo Android Studio:** Đã tạo sẵn máy ảo (Khuyến nghị `Pixel 8`, Android 10+ / API 29+).
  * **Hoặc Điện thoại Android thật:** Bật tính năng *Tùy chọn cho nhà phát triển* và *Gỡ lỗi USB (USB Debugging)*.

---

## 2. QUY TRÌNH CÀI ĐẶT & CHẠY TỪ MÃ NGUỒN (CHỈ VỚI 5 LỆNH)

Mở cửa sổ dòng lệnh (Terminal / PowerShell) và chạy tuần tự các lệnh sau:

```bash
# Bước 1: Di chuyển vào thư mục dự án
cd d:\Mobile_App\BTL_KTHP

# Bước 2: Tải và đồng bộ toàn bộ gói thư viện phụ thuộc
flutter pub get

# Bước 3: Kiểm tra chất lượng tĩnh mã nguồn (Đảm bảo 0 lỗi, 0 cảnh báo)
flutter analyze

# Bước 4: Chạy toàn bộ 30 bài kiểm thử tự động (Unit, Widget, Accessibility)
flutter test

# Bước 5: Khởi chạy ứng dụng lên máy ảo hoặc thiết bị thật
flutter run
```

---

## 3. CÀI ĐẶT TRỰC TIẾP TỪ FILE APK PHÁT HÀNH (RELEASE APK)

Nếu giảng viên hoặc người chấm không muốn cài đặt Flutter SDK, có thể cài đặt trực tiếp file APK độc lập đã được ký chứng chỉ:

* **Tệp cài đặt:** [app-release.apk](file:///d:/Mobile_App/BTL_KTHP/build/app/outputs/flutter-apk/app-release.apk)
* **Dung lượng:** ~71.5 MB

### Cách A: Cài qua cáp USB bằng lệnh ADB (dành cho kỹ thuật viên)
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Cách B: Cài trực tiếp trên điện thoại Android thật (dành cho người dùng phổ thông)
1. Tải file `app-release.apk` về điện thoại (qua Zalo, Google Drive, hoặc cắm cáp chép file).
2. Nhấn vào file APK trên điện thoại để tiến hành cài đặt.
3. Nếu điện thoại hiển thị cảnh báo:
   * *"Cài đặt ứng dụng không rõ nguồn gốc"* $\rightarrow$ Chọn **Cho phép** (Allow from this source).
   * *"Google Play Protect chưa xác minh"* $\rightarrow$ Chọn **Vẫn cài đặt** (Install anyway).
4. Biểu tượng **EduMaster** sẽ xuất hiện trên màn hình điện thoại và sẵn sàng sử dụng.

---

## 4. HƯỚNG DẪN TRẢI NGHIỆM CÁC TÍNH NĂNG CHÍNH

### 4.1. Ôn tập trắc nghiệm 300 câu (Tab 1: Trắc nghiệm)
* **Luyện tập tự do:** Chọn câu hỏi, bấm chọn đáp án để xem ngay đúng/sai và giải thích chi tiết.
* **Song ngữ tức thời:** Bấm vào biểu tượng lá cờ / nút **VI / EN** ở góc trên để chuyển toàn bộ câu hỏi và đáp án sang Tiếng Anh.
* **Hỏi AI lý do sai:** Nếu chọn nhầm đáp án, bấm nút *"Gia sư AI giải thích"* để nhận gợi ý học tập.
* **Thi thử tính giờ:** Bấm vào chế độ Thi thử để làm bài thi 20 câu có đồng hồ đếm ngược 20 phút.
* **Làm lại câu sai:** Chọn mục *"Ôn lại các câu đã làm sai"* để hệ thống lọc riêng các câu bạn đã từng trả lời sai trước đây.

### 4.2. Thẻ ghi nhớ SM-2 (Tab 2: Flashcards)
* **Lật thẻ 3D:** Bấm vào thẻ để xem hiệu ứng xoay lật 3D hiển thị mặt sau (định nghĩa).
* **Phát âm từ vựng:** Bấm vào biểu tượng loa để nghe giọng đọc chuẩn Text-To-Speech (TTS).
* **Chấm điểm SM-2 (0 đến 5 sao):**
  * Đánh giá 0 - 2 sao (Quên): Thẻ được tự động lên lịch ôn lại vào ngày mai ($I=1$).
  * Đánh giá 3 - 5 sao (Nhớ tốt): Thuật toán tự động tăng hệ số $EF$ và nhân giãn cách ngày ôn tập tiếp theo.
* **Nhập thẻ CSV:** Bấm nút *"Nhập CSV"* để tải hàng loạt thẻ vựng từ file văn bản.

### 4.3. Phòng thi trực tuyến (Tab 3: Phòng thi)
* **Vào phòng nhanh bằng Camera:** Bấm vào biểu tượng quét mã QR tại thanh tiêu đề, hướng camera vào mã QR phòng thi để vào thẳng bài làm.
* **Giám sát chống gian lận:** Trong lúc làm bài, nếu thí sinh thoát app hoặc mở ứng dụng khác (tra tài liệu), hệ thống sẽ lập tức tăng số lần vi phạm và hiển thị thông báo nhắc nhở.

### 4.4. Từ điển IT FTS (Tab 4: Từ điển IT)
* Gõ bất kỳ ký tự nào vào ô tìm kiếm để trải nghiệm tốc độ phản hồi tức thời của SQLite Full-Text Search.
* Bấm vào ngôi sao để đưa từ vào danh sách yêu thích (Bookmark).
* Mỗi ngày mở app, mục *"Từ của ngày"* sẽ tự động gợi ý một thuật ngữ CNTT mới.

### 4.5. Cài đặt AI & Đổi Avatar (Tab 5 & Hồ sơ)
* **Chụp Avatar từ Camera:** Bấm vào nút Camera nhỏ ở góc ảnh đại diện để selfie hoặc chọn ảnh từ thư viện.
* **Kích hoạt Chế độ Demo AI:** Bật công tắc *"Chế độ Demo"* để AI Tutor hoạt động 100% offline không cần kết nối mạng hay tốn phí API.
* **Cấu hình Proxy / Key:** Nhập URL Proxy trung gian hoặc Gemini Key cá nhân nếu muốn trải nghiệm sức mạnh mô hình Gemini 1.5 Flash trực tiếp.

---

## 5. TỰ ĐỘNG HÓA CI/CD TRÊN GITHUB ACTIONS

Dự án đã tích hợp sẵn tệp cấu hình [.github/workflows/ci.yml](file:///d:/Mobile_App/BTL_KTHP/.github/workflows/ci.yml). Khi đẩy mã nguồn lên GitHub, hệ thống tự động:
1. Chạy `flutter analyze --fatal-infos` (Ngăn chặn việc merge code có lỗi).
2. Chạy `flutter test` (Đảm bảo toàn bộ 30 bài kiểm thử phải vượt qua).
3. Biên dịch và xuất bản file APK để các thành viên khác tải về kiểm tra ngay lập tức.
