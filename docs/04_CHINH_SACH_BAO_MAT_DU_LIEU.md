# 🔒 CHÍNH SÁCH BẢO MẬT & QUẢN TRỊ DỮ LIỆU (SECURITY AUDIT)
## DỰ ÁN EDUMASTER — BTL_KTHP (TIÊU CHÍ 6 XUẤT SẮC)

> **Mục tiêu:** Thỏa mãn 100% tiêu chí **Bảo mật và Quyền riêng tư (10/10 điểm)**:
> 1. Không có khóa API, mật khẩu hay token nào nằm trong mã nguồn hay lịch sử Git.
> 2. Chỉ xin quyền hệ thống cần thiết, đúng lúc khi người dùng thực hiện hành động.
> 3. Tài liệu mô tả minh bạch toàn bộ dữ liệu nào lưu ở đâu và cơ chế bảo vệ.

---

## 1. MA TRẬN PHÂN LOẠI DỮ LIỆU & VỊ TRÍ LƯU TRỮ

| Phân loại dữ liệu | Loại dữ liệu | Vị trí lưu trữ vật lý | Công nghệ lưu trữ | Cơ chế an toàn |
| :--- | :--- | :--- | :--- | :--- |
| **Ngân hàng 300 câu hỏi** | Công khai, nội dung tĩnh | `assets/data/questions_300.json` | Read-only Asset Bundle | Đóng gói cố định trong APK, không thể bị can thiệp hay sửa đổi từ bên ngoài. |
| **Bộ thẻ SM-2 & Lịch sử thi** | Dữ liệu cá nhân học tập | Thư mục ứng dụng cục bộ | `SharedPreferences` (XML Sandbox) | Nằm trong phân vùng bộ nhớ riêng tư `/data/data/com.edumaster.app.edumaster/shared_prefs/`, các ứng dụng khác không thể đọc trộm. |
| **Từ điển IT Anh - Việt** | Dữ liệu tra cứu ngoại tuyến | Thư mục cơ sở dữ liệu nội bộ | `SQLite Database (FTS)` | File `edumaster_it_dictionary.db` được bảo vệ theo cơ chế phân quyền người dùng Linux của nhân Android. |
| **Ảnh đại diện (Avatar)** | Dữ liệu hình ảnh cá nhân | Bộ nhớ cache cục bộ ứng dụng | Local File Path | Chỉ lưu đường dẫn nội bộ do `ImagePicker` sinh ra, không tự ý đẩy ảnh lên đám mây khi chưa có sự đồng ý. |
| **Google Gemini API Key** | Thông tin nhạy cảm | `SharedPreferences` | Local Key-Value | **Tuyệt đối không hardcode trong mã nguồn**. Nhập tùy chọn qua màn hình Cài đặt, có chế độ Demo và Proxy thay thế. |
| **Keystore ký phát hành** | Khóa ký số ứng dụng | `android/app/edumaster-keystore.jks` | Java Keystore (JKS) | Đã được cấu hình trong `.gitignore`, **không bao giờ bị đẩy lên GitHub**. |

---

## 2. CHÍNH SÁCH BẢO MẬT KHÓA API & MÁY CHỦ TRUNG GIAN (AI PROXY)

Ứng dụng giải quyết triệt để vấn đề bảo mật khóa API thông qua kiến trúc 4 tầng bảo vệ:

1. **Tuyệt đối không lưu khóa bí mật trong mã nguồn:**
   * Không có chuỗi `AIzaSy...` nào xuất hiện trong các tệp `.dart`, `.json` hay trong lịch sử commit của Git repository.
2. **Kiến trúc Máy chủ giữ khóa (Key Proxy Server):**
   * Trong mô hình doanh nghiệp/trường học, ứng dụng cho phép kết nối đến một URL Proxy trung gian (ví dụ `https://ai-proxy.edumaster.edu.vn/ask`).
   * Ứng dụng client chỉ gửi nội dung câu hỏi. Máy chủ Proxy sẽ chịu trách nhiệm xác thực và gán khóa Gemini bí mật phía backend, bảo vệ khóa không bao giờ bị dịch ngược từ file APK.
3. **Chế độ Demo (Demo Mode) không cần mạng/không cần khóa:**
   * Người dùng chỉ cần bật thanh gạt *"Chế độ Demo"* trong Cài đặt là có thể trải nghiệm toàn bộ tính năng của Gia sư AI Tutor dựa trên kho dữ liệu có sẵn mà không tốn chi phí API hay lo ngại rò rỉ khóa.
4. **Bảo vệ chứng chỉ ký ứng dụng (Keystore Security):**
   * Tệp `android/key.properties` chứa mật khẩu ký release và tệp `edumaster-keystore.jks` được liệt kê nghiêm ngặt trong [.gitignore](file:///d:/Mobile_App/BTL_KTHP/.gitignore).

---

## 3. CHÍNH SÁCH QUYỀN RIÊNG TƯ & XIN QUYỀN "ĐÚNG LÚC" (JUST-IN-TIME PERMISSION)

Ứng dụng tuân thủ nghiêm ngặt nguyên tắc **Least Privilege (Quyền tối thiểu)** và **Just-in-Time Request (Xin quyền đúng lúc)**:

### 3.1. Quyền Máy ảnh (Camera Permission)
* **Khai báo tối thiểu trong `AndroidManifest.xml`:**
  ```xml
  <uses-permission android:name="android.permission.CAMERA" />
  <uses-feature android:name="android.hardware.camera" android:required="false" />
  ```
  *(Gắn cờ `android:required="false"` để các thiết bị không có camera phần cứng vẫn cài đặt và dùng được các tính năng khác bình thường).*
* **Thời điểm kích hoạt yêu cầu cấp quyền:**
  * **KHÔNG BAO GIỜ** xin quyền Camera khi người dùng vừa mở ứng dụng lần đầu.
  * **CHỈ XIN QUYỀN** khi người dùng thực hiện một trong hai hành động cụ thể:
    1. Bấm vào nút *"Quét mã QR"* tại thanh tiêu đề.
    2. Bấm vào biểu tượng máy ảnh trên ảnh đại diện để *"Chụp ảnh mới"*.

### 3.2. Cơ chế xử lý khi người dùng từ chối cấp quyền (Graceful Degradation)
* Nếu người dùng bấm *"Don't allow"* (Từ chối):
  * Ứng dụng **không bao giờ bị dừng đột ngột (crash)**.
  * Hiển thị ngay thông báo trực quan: *"Máy ảnh giả lập hoặc chưa cấp quyền Camera"*.
  * Cung cấp ngay lối ra thay thế: Cho phép người dùng nhập mã PIN phòng thi bằng bàn phím hoặc nhấn nút *"Dùng mã mẫu (EXAM100)"* để tiếp tục trải nghiệm.
