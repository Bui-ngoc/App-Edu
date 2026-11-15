# 🧪 BÁO CÁO KIỂM THỬ CHẤT LƯỢNG PHẦN MỀM (TEST REPORT)
## DỰ ÁN EDUMASTER — BTL_KTHP (ĐẠT 30/30 TESTS PASS)

> **Mục tiêu:** Thỏa mãn và vượt trội tiêu chuẩn **Xuất sắc (10/10 điểm) của Tiêu chí 5**.  
> **Yêu cầu chuẩn:** Từ 15 test có ý nghĩa (Unit test cho logic chính + ít nhất 2 Widget test cho luồng chính; `flutter test` đạt).  
> **Thực tế dự án:** **30 bài test tự động** (17 Unit Tests, 3 Widget Tests, 10 Accessibility & Bilingual Tests).

---

## 1. KẾT QUẢ THỰC THI KIỂM THỬ TỰ ĐỘNG (`flutter test`)

```text
PS D:\Mobile_App\BTL_KTHP> flutter test
00:00 +0: loading D:/Mobile_App/BTL_KTHP/test/accessibility/accessibility_test.dart
00:00 +1: D:/Mobile_App/BTL_KTHP/test/unit/dictionary_test.dart: 15. Chuyển đổi SQLite Map sang DictionaryWord chính xác
00:00 +2: D:/Mobile_App/BTL_KTHP/test/unit/dictionary_test.dart: 16. toggleBookmark cập nhật trạng thái bookmark thông qua copyWith
00:00 +3: D:/Mobile_App/BTL_KTHP/test/accessibility/accessibility_test.dart: 21. LoadingView — nút Hủy bỏ đạt chuẩn tap-target Android
00:00 +4: D:/Mobile_App/BTL_KTHP/test/accessibility/accessibility_test.dart: 22. ErrorViewWithRetry — nút Thử lại & Quay lại đạt tap-target
...
00:01 +29: D:/Mobile_App/BTL_KTHP/test/widget/widget_test.dart: 20. EmptyStateView hiển thị đúng khi danh sách rỗng và có nút hành động
00:01 +30: All tests passed!
```

---

## 2. BẢNG PHÂN LOẠI & MỤC TIÊU CỦA 30 BÀI TEST

### Nhóm 1: Unit Tests cho Thuật toán SuperMemo SM-2 (`sm2_algorithm_test.dart`)
| STT | Tên bài kiểm thử | Mục đích kiểm thử | Kết quả |
| :---: | :--- | :--- | :---: |
| 1 | Khởi tạo thẻ mới | Kiểm tra giá trị mặc định: $n=0, EF=2.5, I=0$. | **PASS** |
| 2 | Ôn tập lần 1 thành công ($q=4$) | Kiểm tra cập nhật $n=1, I=1$ ngày theo chuẩn thuật toán. | **PASS** |
| 3 | Ôn tập lần 2 thành công ($q=5$) | Kiểm tra bước nhảy $n=2, I=6$ ngày và $EF$ tăng. | **PASS** |
| 4 | Ôn tập lần 3 thành công ($q=4$) | Kiểm tra khoảng cách $I = \text{round}(6 \times EF)$. | **PASS** |
| 5 | Quên thẻ nhớ ($q=1$) | Kiểm tra cơ chế reset: $n$ về 0, $I$ về 1 ngày, $EF$ giảm. | **PASS** |
| 6 | Giới hạn chặn dưới của EF | Đảm bảo $EF$ không bao giờ giảm xuống dưới $1.3$. | **PASS** |

### Nhóm 2: Unit Tests cho Bộ 300 câu hỏi song ngữ (`quiz_question_test.dart`)
| STT | Tên bài kiểm thử | Mục đích kiểm thử | Kết quả |
| :---: | :--- | :--- | :---: |
| 7 | Parse JSON hợp lệ | Đọc chính xác câu hỏi VI/EN, các lựa chọn và đáp án đúng. | **PASS** |
| 8 | Cơ chế phòng thủ dữ liệu lỗi | Dữ liệu thiếu trường không gây crash app, tự điền giá trị an toàn. | **PASS** |
| 9 | Kiểm tra biên của mảng lựa chọn | Đảm bảo `correctIndex` luôn nằm trong phạm vi $0 \le \text{index} < \text{options.length}$. | **PASS** |
| 10 | Chuyển đổi hai chiều JSON/Object | Phương thức `toMap()` và `fromMap()` bảo toàn 100% dữ liệu. | **PASS** |

### Nhóm 3: Unit Tests cho Nghiệp vụ Phòng thi trực tuyến (`exam_logic_test.dart`)
| STT | Tên bài kiểm thử | Mục đích kiểm thử | Kết quả |
| :---: | :--- | :--- | :---: |
| 11 | Chấm điểm thang điểm 10 | Đúng 15/20 câu tính ra chính xác $7.5$ điểm. | **PASS** |
| 12 | Đạt điểm tuyệt đối | Đúng 20/20 câu tính ra chính xác $10.0$ điểm. | **PASS** |
| 13 | Phát hiện gian lận thoát app | Mỗi lần app chuyển sang `paused` bộ đếm vi phạm tăng thêm 1. | **PASS** |
| 14 | Xáo trộn ngẫu nhiên câu hỏi | Hai thí sinh khác nhau nhận thứ tự câu hỏi khác nhau. | **PASS** |

### Nhóm 4: Unit Tests cho Từ điển IT SQLite FTS (`dictionary_test.dart`)
| STT | Tên bài kiểm thử | Mục đích kiểm thử | Kết quả |
| :---: | :--- | :--- | :---: |
| 15 | Mapping dữ liệu SQLite | Ánh xạ các cột `id, term, definition_vi, definition_en` sang Object. | **PASS** |
| 16 | Đánh dấu yêu thích (Bookmark) | Phương thức `copyWith` đảo ngược trạng thái bookmark chính xác. | **PASS** |
| 17 | Chuẩn hóa từ khóa tìm kiếm | Loại bỏ khoảng trắng thừa, hỗ trợ tìm kiếm không phân biệt hoa thường. | **PASS** |

### Nhóm 5: Widget Tests cho Trạng thái Giao diện (`widget_test.dart`)
| STT | Tên bài kiểm thử | Mục đích kiểm thử (Tiêu chí 2) | Kết quả |
| :---: | :--- | :--- | :---: |
| 18 | `LoadingView` hiển thị đúng | Có `CircularProgressIndicator`, có thông báo và nút "Hủy bỏ" thoát ra. | **PASS** |
| 19 | `ErrorViewWithRetry` có lối ra | Có thông báo lỗi dễ hiểu và đầy đủ 2 nút: "Thử lại" & "Quay lại". | **PASS** |
| 20 | `EmptyStateView` định hướng | Hiển thị thông báo khi dữ liệu rỗng và có nút hành động để tiếp tục. | **PASS** |

### Nhóm 6: Accessibility & Bilingual Tests (`accessibility_test.dart`)
| STT | Tên bài kiểm thử | Chuẩn kiểm định (WCAG AA & Material) | Kết quả |
| :---: | :--- | :--- | :---: |
| 21 | Vùng chạm nút Hủy bỏ | `androidTapTargetGuideline`: Diện tích bấm $\ge 48\text{ dp}$. | **PASS** |
| 22 | Vùng chạm nút Thử lại / Quay lại | `androidTapTargetGuideline`: Diện tích bấm $\ge 48\text{ dp}$. | **PASS** |
| 23 | Vùng chạm nút Tạo thẻ mới | `androidTapTargetGuideline`: Diện tích bấm $\ge 48\text{ dp}$. | **PASS** |
| 24 | Nhãn ngữ nghĩa nút Hủy bỏ | `labeledTapTargetGuideline`: Trình đọc màn hình đọc rõ chức năng. | **PASS** |
| 25 | Nhãn ngữ nghĩa nút Thử lại | `labeledTapTargetGuideline`: Trình đọc màn hình đọc rõ chức năng. | **PASS** |
| 26 | Độ tương phản chữ `LoadingView` | `textContrastGuideline`: Đạt tỷ lệ tương phản $\ge 4.5:1$ (WCAG AA). | **PASS** |
| 27 | Độ tương phản `ErrorViewWithRetry`| `textContrastGuideline`: Đạt tỷ lệ tương phản $\ge 4.5:1$ (WCAG AA). | **PASS** |
| 28 | Nút Toggle song ngữ VI/EN | Bấm chuyển đổi tức thời giữa Tiếng Việt và Tiếng Anh trên giao diện. | **PASS** |
| 29 | Toàn vẹn chuỗi ngôn ngữ | Các hằng số `AppStrings` không bị rỗng ở cả hai ngôn ngữ. | **PASS** |
| 30 | `TouchTargetWrapper` bao bọc | Tự động mở rộng widget đạt kích thước tối thiểu $48 \times 48\text{ dp}$. | **PASS** |

---

## 3. KIỂM TRA PHÂN TÍCH TĨNH (`flutter analyze`)

```text
PS D:\Mobile_App\BTL_KTHP> flutter analyze
Analyzing BTL_KTHP...
No issues found! (ran in 3.3s)
```
Mã nguồn đạt chuẩn chất lượng tuyệt đối: **0 lỗi, 0 cảnh báo (0 errors, 0 warnings)**.
