# 🧠 ĐẶC TẢ TÍNH NĂNG VÀ THUẬT TOÁN CỐT LÕI

## 1. THUẬT TOÁN SM-2 (SUPERMEMO SPACED REPETITION)

Hệ thống ghi nhớ từ vựng và kiến thức Flashcards sử dụng thuật toán **SuperMemo SM-2** nâng cao:

* **Công thức cập nhật hệ số Ease Factor ($EF$):**
  $$\Delta EF = 0.1 - (5 - q) \times (0.08 + (5 - q) \times 0.02)$$
  $$EF' = \max(1.3, EF + \Delta EF)$$
* **Lịch ôn tập ngắt quãng ($I$):**
  - Nếu $q < 3$ (Học viên quên): Reset $n = 0, I = 1\text{ ngày}$.
  - Nếu $q \ge 3$ (Học viên nhớ): $n' = n + 1$, $I(1) = 1, I(2) = 6, I(n) = \text{round}(I(n - 1) \times EF')$.

---

## 2. CƠ SỞ DỮ LIỆU SQLITE FULL-TEXT SEARCH (FTS)

* Từ điển IT Offline triển khai bảng ảo `CREATE VIRTUAL TABLE dictionary_fts USING fts4(...)`.
* Cho phép tìm kiếm toàn văn tốc độ cao $O(\log N)$, phản hồi tức thì dưới $5\text{ms}$ ngay khi người dùng gõ từng ký tự.

---

## 3. CƠ CHẾ GIÁM SÁT CHỐNG GIAN LẬN VÀ THEO DÕI REALTIME

* Lắng nghe tín hiệu chu trình sống `AppLifecycleState.paused`/`inactive` thông qua `WidgetsBindingObserver`.
* Tự động đếm số lần vi phạm và lưu chính xác mốc thời gian rời app (ví dụ: *10:14:02 — Rời màn hình thi*).
* Dữ liệu sinh viên đang làm bài được đồng bộ định kỳ mỗi 3 giây sang `LiveStudentSession` phục vụ màn hình giám sát của Giáo viên.

---

## 4. KIẾN TRÚC GIA SƯ AI TUTOR 4 TẦNG AN TOÀN

1. **Demo Mode:** Trả lời bằng bộ dữ liệu mẫu song ngữ offline, không cần internet hay API key.
2. **Key Proxy Server:** Định tuyến câu hỏi qua máy chủ trung gian giữ khóa Gemini, bảo mật tuyệt đối client.
3. **Direct Key:** Cho phép nhập Gemini API key cá nhân lưu riêng trong `SharedPreferences`.
4. **Offline Fallback:** Khi mất mạng hoặc quá thời gian chờ (10s), tự động trả lời bằng bộ quy tắc cục bộ thông minh.
