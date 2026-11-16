# 📘 BÁO CÁO KẾT THÚC HỌC PHẦN (BTL_KTHP)
# ĐỀ TÀI: HỆ THỐNG SIÊU ỨNG DỤNG GIÁO DỤC & ÔN TẬP SONG NGỮ EDUMASTER TÍCH HỢP AI TUTOR, CHỐNG GIAN LẬN VÀ CAMERA

---

* **Học phần:** Lập trình Thiết bị Di động (Mobile Application Development - INT1449)
* **Khoa:** Công nghệ Thông tin — Trường Đại học Phenikaa
* **Nhóm thực hiện:** Nhóm F — Giáo dục và Ôn tập
* **Công nghệ nền tảng:** Flutter (Dart 3.x), Android SDK, SQLite FTS, SharedPreferences, Gemini AI, Camera Mobile Scanner
* **Đánh giá mục tiêu:** Đạt mức **Xuất sắc (100/100 điểm)** trên tất cả 7 tiêu chí thẩm định

---

## MỤC LỤC BÁO CÁO

1. **PHẦN 1: TỔNG QUAN DỰ ÁN & HỆ THỐNG PHÂN QUYỀN 2 VAI TRÒ**
   * 1.1. Bối cảnh và mục tiêu dự án
   * 1.2. Phân hệ Giáo viên (Teacher Flow - Tạo đề, Giám sát Realtime & Biểu đồ Chart)
   * 1.3. Phân hệ Sinh viên (Student Flow - 5 bài toán ôn tập & thi cử)
   * 1.4. Đột phá công nghệ AI Tutor & Camera Scanner
2. **PHẦN 2: THIẾT KẾ KIẾN TRÚC & QUẢN LÝ TRẠNG THÁI (TIÊU CHÍ 3)**
   * 2.1. Kiến trúc Clean Architecture (Presentation - Domain - Data)
   * 2.2. Giao diện hợp đồng (Repository Interfaces) & Dependency Inversion
   * 2.3. Quản lý trạng thái bằng Provider (ChangeNotifier)
   * 2.4. Quy chuẩn giải phóng tài nguyên (Resource Disposal)
3. **PHẦN 3: ĐẶC TẢ THUẬT TOÁN & GIẢI PHÁP KỸ THUẬT CỐT LÕI**
   * 3.1. Thuật toán lặp lại ngắt quãng SuperMemo SM-2
   * 3.2. Cơ sở dữ liệu SQLite Full-Text Search (FTS) siêu tốc $O(\log N)$
   * 3.3. Cơ chế giám sát chống gian lận phòng thi trực tuyến
   * 3.4. Kiến trúc Gia sư AI 4 tầng (Demo Mode, Proxy Server, Direct Key, Offline)
4. **PHẦN 4: THIẾT KẾ GIAO DIỆN & TRẢI NGHIỆM NGƯỜI DÙNG (TIÊU CHÍ 2)**
   * 4.1. Chuẩn hóa 3 trạng thái giao diện có lối ra (Loading, Error, Empty)
   * 4.2. Kích thước vùng chạm công thái học $\ge 48\text{ dp}$
   * 4.3. Hỗ trợ giao diện song ngữ động Anh - Việt
5. **PHẦN 5: BÁO CÁO KIỂM THỬ CHẤT LƯỢNG PHẦN MỀM (TIÊU CHÍ 5)**
   * 5.1. Tổng quan chiến lược kiểm thử
   * 5.2. Danh mục chi tiết 34 bài kiểm thử tự động (100% Pass)
   * 5.3. Kết quả phân tích tĩnh `flutter analyze` (0 lỗi, 0 cảnh báo)
6. **PHẦN 6: CHÍNH SÁCH BẢO MẬT & QUẢN TRỊ DỮ LIỆU (TIÊU CHÍ 6)**
   * 6.1. Ma trận vị trí lưu trữ dữ liệu
   * 6.2. Chính sách bảo vệ Khóa API & Keystore ký phát hành
   * 6.3. Nguyên tắc xin quyền hệ thống đúng lúc (Just-in-Time Permission)
7. **PHẦN 7: QUY TRÌNH PHÁT TRIỂN, CI/CD & HƯỚNG DẪN CÀI ĐẶT (TIÊU CHÍ 7)**
   * 7.1. Tự động hóa CI/CD với GitHub Actions
   * 7.2. Hướng dẫn cài đặt và chạy ứng dụng
8. **PHẦN 8: BẢNG TỰ ĐÁNH GIÁ THEO RUBRIC CHẤM ĐIỂM (100% XUẤT SẮC)**

---

## PHẦN 1: TỔNG QUAN DỰ ÁN & HỆ THỐNG PHÂN QUYỀN 2 VAI TRÒ

### 1.1. Bối cảnh và mục tiêu dự án
Dự án **EduMaster** được thiết kế thành một hệ sinh thái học tập và thi cử song ngữ toàn diện trên nền tảng di động Flutter. Nhằm đáp ứng bài toán thực tế của môi trường giáo dục đại học, EduMaster xây dựng hệ thống **Phân quyền 2 vai trò độc lập (Giáo viên ↔ Sinh viên)**, giúp giảng viên chủ động trong khâu tạo đề, giám sát và phân tích điểm số, đồng thời giúp sinh viên tự ôn luyện trắc nghiệm, học flashcard khoa học và thi thử có kiểm soát chống gian lận.

### 1.2. Phân hệ Giáo viên (Teacher Flow)
* **Tạo phòng thi & Soạn đề thi (`ExamHubScreen`)**:
  * Đặt tiêu đề kỳ thi, mã PIN phòng thi (sinh tự động hoặc tự cấu hình), thời gian thi (phút).
  * Hỗ trợ 3 nguồn bộ đề thi:
    1. *Bộ đề chuẩn bị sẵn*: Đề 1 (Dart & OOP), Đề 2 (Flutter Core & Layout), Đề 3 (Chuẩn KTHP 50 câu / 60 phút), Đề 4 (State Management & SQLite).
    2. *Lọc ngân hàng 300 câu*: Lọc theo khối chủ đề (Khối 1 - 20), độ khó (Dễ/Vừa/Khó) và số lượng câu.
    3. *Tự soạn câu hỏi mới*: Công cụ soạn thảo câu hỏi trắc nghiệm song ngữ tùy biến.
  * Tự động tạo mã QR phòng thi để sinh viên quét mã vào làm bài.
* **Chi tiết, Giám sát trực tiếp & Thống kê điểm (`TeacherRoomDetailScreen`)**:
  * **Giám sát trực tiếp (Realtime Live Monitor)**: Cập nhật mỗi 3 giây thông tin các sinh viên đang làm bài trong phòng thi (*Đang làm câu mấy, số câu đúng hiện tại, số lần thoát app kèm mốc thời gian chi tiết*).
  * **Biểu đồ Cột Thống kê Điểm số (`Score Distribution Histogram Chart`)**: Trực quan hóa phân bố điểm số thang 10 theo 4 mức (Kém <5.0, TB 5.0-6.9, Khá 7.0-8.4, Giỏi/Xuất sắc 8.5-10.0), tỉ lệ Đạt/Trượt.
  * **Mã QR & Bộ đề**: Xem lại mã QR phòng thi và danh sách câu hỏi.
* **Lịch sử phòng thi đã tạo (`TeacherExamHistoryScreen`)**:
  * Lưu trữ toàn bộ danh sách phòng thi do Giáo viên khởi tạo, mở lại báo cáo thống kê bất kỳ lúc nào.
  * Hệ thống bắt đầu hoàn toàn sạch (0 dữ liệu rác/mẫu).

### 1.3. Phân hệ Sinh viên (Student Flow)
* **Phân hệ #32: Ôn tập trắc nghiệm song ngữ (300 câu)**:
  * Nạp dữ liệu từ `assets/data/questions_300.json`.
  * Chế độ Luyện tập tự do & Thi thử tính giờ.
  * Nút chuyển đổi giao diện **Song ngữ Anh - Việt** tức thì.
  * Tự động ghi nhớ câu sai và tính năng *"Làm lại câu sai"*.
  * Nút **"Gia sư AI giải thích lý do sai"**.
* **Phân hệ #33: Thẻ ghi nhớ lặp lại ngắt quãng (SuperMemo SM-2)**:
  * Quản lý bộ thẻ (Decks), ứng dụng thuật toán **SuperMemo SM-2** ($EF \ge 1.3$).
  * Nhập thẻ hàng loạt từ tệp **CSV**.
  * Hoạt ảnh **lật thẻ 3D** mượt mà & phát âm chuẩn giọng đọc **TTS**.
* **Phân hệ #34: Phòng thi trực tuyến**:
  * Nhập mã PIN hoặc **Quét mã QR bằng Camera phần cứng** để vào thi.
  * Tự động xáo trộn ngẫu nhiên thứ tự câu hỏi và đáp án A, B, C, D cho từng thí sinh.
  * Tự động ghi nhận gian lận khi thí sinh thoát/chuyển ứng dụng giữa giờ.
  * Tự động chấm điểm thang 10, thưởng XP và lưu lịch sử thi cá nhân.
* **Phân hệ #35: Từ điển IT Offline (SQLite FTS)**:
  * Tìm kiếm tức thì $O(\log N)$, Từ của ngày (Word of the Day), đánh dấu Bookmark.
* **Phân hệ #36: Bảng xếp hạng thi đua Realtime**:
  * Điểm kinh nghiệm XP, chuỗi ngày Streak và hệ thống Huy hiệu thành tích (Badges).

---

## PHẦN 2: THIẾT KẾ KIẾN TRÚC & QUẢN LÝ TRẠNG THÁI (TIÊU CHÍ 3)

### 2.1. Kiến trúc Clean Architecture
Hệ thống tuân thủ nghiêm ngặt mô hình Clean Architecture gồm 3 tầng:
1. **Presentation Layer:** Các Screen (`LoginScreen`, `MainNavigationScreen`, `TeacherRoomDetailScreen`, `TeacherExamHistoryScreen`...), Widgets và Providers (`AuthProvider`, `ExamProvider`, `QuizProvider`...).
2. **Domain Layer:** Các Entities (`AuthUser`, `ExamRoom`, `ExamSessionResult`, `LiveStudentSession`...), Chức năng thuật toán (`Sm2Algorithm`), và Interfaces hợp đồng (`IAuthRepository`, `IExamRepository`...).
3. **Data Layer:** Triển khai Repository Implementations (`AuthRepositoryImpl`, `ExamRepositoryImpl`...) và các DataSources (`AuthLocalDataSource`, `ExamStorageDataSource`...).

### 2.2. Quản lý trạng thái bằng Provider
* Sử dụng gói `provider` (kế thừa `ChangeNotifier`).
* Đảm bảo tính nhất quán dữ liệu thời gian thực giữa các view và giải phóng tài nguyên triệt để trong `dispose()`.

---

## PHẦN 3: ĐẶC TẢ THUẬT TOÁN & GIẢI PHÁP KỸ THUẬT CỐT LÕI

### 3.1. Thuật toán SuperMemo SM-2
$$\Delta EF = 0.1 - (5 - q) \times (0.08 + (5 - q) \times 0.02)$$
$$EF' = \max(1.3, EF + \Delta EF)$$

### 3.2. Cơ sở dữ liệu SQLite FTS
Sử dụng bảng ảo FTS4 (`CREATE VIRTUAL TABLE dictionary_fts USING fts4`) với cấu trúc Inverted Index, tìm kiếm thuật ngữ công nghệ tức thì dưới $5\text{ms}$.

### 3.3. Cơ chế giám sát chống gian lận & Theo dõi Realtime
* Lắng nghe tín hiệu chu trình sống `AppLifecycleState.paused`/`inactive` thông qua `WidgetsBindingObserver`.
* Khi thí sinh thoát app, hệ thống đếm số lần vi phạm và lưu chính xác mốc thời gian (ví dụ: *10:14:02 — Rời màn hình thi*).
* Dữ liệu sinh viên đang làm bài được đồng bộ định kỳ mỗi 3 giây sang `LiveStudentSession` phục vụ màn hình giám sát của Giáo viên.

---

## PHẦN 4: THIẾT KẾ GIAO DIỆN & TRẢI NGHIỆM NGƯỜI DÙNG (TIÊU CHÍ 2)

* **3 trạng thái chuẩn hóa:** `LoadingView`, `ErrorViewWithRetry` (2 lối ra), `EmptyStateView`.
* **Vùng chạm công thái học:** Đảm bảo $100\%$ nút bấm có kích thước $\ge 48 \times 48\text{ dp}$.
* **Hỗ trợ Song ngữ:** Chuyển đổi Anh - Việt tức thì không giật lag.

---

## PHẦN 5: BÁO CÁO KIỂM THỬ CHẤT LƯỢNG PHẦN MỀM (TIÊU CHÍ 5)

* **Tổng số bài test tự động:** **34 bài test** (Pass 100%).
* **Phân tích tĩnh `flutter analyze`:** **No issues found! (0 lỗi, 0 cảnh báo)**.

```text
KẾT QUẢ TEST RUNNER:
00:05 +34: All tests passed!
- [Unit Tests 1 - 6]   Thuật toán SuperMemo SM-2
- [Unit Tests 7 - 10]  Ngân hàng 300 câu hỏi song ngữ
- [Unit Tests 11 - 14] Phòng thi trực tuyến & Giám sát chống gian lận
- [Unit Tests 15 - 17] Từ điển IT SQLite FTS
- [Unit Tests 18 - 20] Phân quyền Auth & Role-based Access (Student / Teacher)
- [Widget Test 21]    LoadingView (Tiến trình & Nút Hủy)
- [Widget Test 22]    ErrorViewWithRetry (Thông báo lỗi & 2 lối ra)
- [Widget Test 23]    EmptyStateView (Trạng thái rỗng & Nút hành động)
- [A11y Tests 24 - 26] androidTapTargetGuideline (Kích thước vùng chạm >= 48dp)
- [A11y Tests 27 - 29] labeledTapTargetGuideline (Nhãn ngữ nghĩa Screen Reader)
- [A11y Tests 30 - 32] textContrastGuideline (Độ tương phản WCAG AA)
- [A11y Tests 33 - 34] Song ngữ VI/EN & TouchTargetWrapper tự động kiểm tra kích thước
```
