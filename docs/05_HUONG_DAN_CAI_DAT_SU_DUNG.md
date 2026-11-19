# ⚡ HƯỚNG DẪN CÀI ĐẶT VÀ SU DỤNG ỨNG DỤNG (TIÊU CHÍ 7)

## 1. YÊU CẦU HỆ THỐNG
* **Flutter SDK:** >= 3.13.4
* **Dart SDK:** >= 3.0.0
* **Môi trường:** Android Studio / VS Code / Android Emulator hoặc Thiết bị thật (Android 8.0+).

---

## 2. CÁC BƯỚC CÀI ĐẶT VÀ CHẠY DỰ ÁN

```bash
# 1. Chuyển vào thư mục dự án
cd D:\Mobile_App\BTL_KTHP

# 2. Tải toàn bộ thư viện
flutter pub get

# 3. Phân tích mã nguồn tĩnh (Đảm bảo 0 lỗi, 0 cảnh báo)
flutter analyze

# 4. Chạy toàn bộ 34 bài kiểm thử tự động
flutter test

# 5. Chạy ứng dụng trên thiết bị/máy ảo
flutter run

# 6. Đóng gói bản cài đặt APK Release
flutter build apk --release
```

---

## 3. HƯỚNG DẪN SỬ DỤNG THEO VAI TRÒ

### 👨‍🏫 Dành cho Giáo viên:
1. Đăng nhập với tài khoản `teacher@edumaster.edu.vn` (mật khẩu `password123`) hoặc chọn Đăng ký vai trò Giáo viên.
2. **Tạo phòng thi**: Nhập tên kỳ thi, mã PIN, chọn nguồn đề (*Bộ đề chuẩn, Lọc ngân hàng 300 câu, Tự soạn câu hỏi*) và lấy Mã QR.
3. **Giám sát & Xem biểu đồ điểm**: Bấm nút *"Chi tiết & Giám sát"* trên thẻ phòng thi để xem tiến độ làm bài sinh viên realtime và biểu đồ phân bố điểm số.
4. **Lịch sử phòng thi**: Mở tab *"Lịch sử phòng thi"* để xem danh sách các phòng thi đã khởi tạo.
5. **Quản lý nhóm học tập**: Vào mục Xếp hạng / Quản lý nhóm -> Bấm *"Tạo nhóm"* (ví dụ: Nhóm 01) -> Bấm *"Thêm SV"* -> Nhập Mã ID (SVxxxx) hoặc Email sinh viên để phân công sinh viên vào nhóm. Hệ thống sẽ tự động cập nhật nhóm cho sinh viên ngay lập tức.

### 🎓 Dành cho Sinh viên:
1. Đăng nhập với tài khoản `student@edumaster.edu.vn` (mật khẩu `password123`) hoặc chọn Đăng ký vai trò Sinh viên.
2. **Ôn tập trắc nghiệm**: Luyện tập 20 khối chủ đề, thi thử đếm ngược 20 phút, làm lại câu sai.
3. **Flashcards SM-2**: Ôn tập thẻ lật 3D, nhập CSV, phát âm giọng đọc TTS.
4. **Phòng thi trực tuyến**: Nhập PIN hoặc bấm *"Quét QR"* để vào thi. Hệ thống cảnh báo khi thoát app.
5. **Từ điển IT Offline**: Tra cứu thuật ngữ CNTT siêu tốc $O(\log N)$, xem Từ của ngày.
6. **Nhóm học tập & Thi đua EXP**: Mở tab *"Xếp hạng nhóm"* để xem nhóm học tập được Giáo viên xếp vào, thứ hạng và điểm EXP tích lũy.
