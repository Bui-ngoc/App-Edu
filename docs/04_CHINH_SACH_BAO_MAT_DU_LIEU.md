# 🔒 CHÍNH SÁCH BẢO MẬT VÀ QUẢN TRỊ DỮ LIỆU (TIÊU CHÍ 6)

## 1. MA TRẬN VỊ TRÍ LƯU TRỮ DỮ LIỆU

| Loại dữ liệu | Vị trí lưu trữ | Cơ chế bảo vệ |
| :--- | :--- | :--- |
| **Tài khoản & Phân quyền** | `SharedPreferences` (JSON) | Quản lý phiên làm việc cục bộ an toàn, tự động nhận diện vai trò GV/SV. |
| **Ngân hàng 300 câu hỏi** | `assets/data/questions_300.json` | Đọc dạng asset bundle trong sandbox ứng dụng. |
| **Từ điển IT (SQLite FTS)** | `edumaster_it_dictionary.db` | CSDL SQLite mã hóa trong vùng nhớ riêng ứng dụng. |
| **Dữ liệu SM-2 & Lịch sử phòng thi** | `SharedPreferences` | Lưu trữ trong bộ nhớ nội bộ `/data/data/...`. |
| **Ảnh đại diện Avatar** | Bộ nhớ cục bộ thiết bị (`localAvatarPath`) | Chỉ truy cập khi người dùng chụp ảnh/chọn ảnh qua Camera/ImagePicker. |
| **Khóa AI & Proxy URL** | `SharedPreferences` | Không bao giờ hardcode trong code. Hỗ trợ Key Proxy Server và Demo Mode. |

---

## 2. QUYỀN HỆ THỐNG ĐÚNG LÚC (JUST-IN-TIME PERMISSIONS)

* **Quyền Camera:** Chỉ yêu cầu khi người dùng chủ động mở tính năng Quét mã QR phòng thi hoặc Chụp ảnh đại diện Avatar.
* **Quyền Bộ nhớ:** Dùng picker chuẩn hệ thống Android, không yêu cầu quyền ghi bộ nhớ ngoài nguy hiểm.
