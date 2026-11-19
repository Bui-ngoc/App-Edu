// lib/data/datasources/local_ai_engine.dart
//
// Bộ não AI Ngoại tuyến Thông minh (Smart Local AI Engine & Knowledge Base)
// Chỉ trả lời các chủ đề kiến thức có sẵn trong hệ thống ngoại tuyến:
//   1. So sánh & Phân biệt các khái niệm (List vs Tuple, final vs const...)
//   2. Khái niệm CNTT, Flutter, Dart, Clean Architecture, Thuật toán, CSDL
//   3. Tính toán số học & công thức toán học/điểm thi

class LocalAiEngine {
  /// Entry point chính: Tra cứu kho kiến thức ngoại tuyến có sẵn
  static String processQuery(String prompt) {
    final clean = prompt.trim();
    if (clean.isEmpty) {
      return '👋 Xin chào! Bạn hãy nhập câu hỏi để mình giải đáp nhé.';
    }

    final lower = clean.toLowerCase();

    // 1. Kiểm tra nếu là phép toán / tính toán số học
    final mathResult = _tryEvaluateMath(clean, lower);
    if (mathResult != null) return mathResult;

    // 2. Kiểm tra nếu là câu hỏi So sánh / Phân biệt (Comparison)
    final comparisonResult = _tryCompareConcepts(lower);
    if (comparisonResult != null) return comparisonResult;

    // 3. Tra cứu từ điển tri thức chuyên sâu (Deep Knowledge Base)
    final kbResult = _lookupKnowledgeBase(lower);
    if (kbResult != null) return kbResult;

    // 4. Nếu câu hỏi KHÔNG có sẵn trong bộ kiến thức ngoại tuyến
    return '📴 **Chế độ AI Ngoại tuyến (Offline):**\n\n'
        'Bộ não AI Ngoại tuyến hiện tại chỉ hỗ trợ giải đáp các chủ đề kiến thức có sẵn trong hệ thống (như *Clean Architecture trong Flutter, Phân biệt List và Tuple, Thuật toán SM-2, So sánh final & const, SQLite FTS, Công thức tính điểm...*).\n\n'
        '💡 **Gợi ý:** Để hỏi đáp mở rộng MỌI chủ đề tự do khác, bạn vui lòng gạt công tắc phía trên sang **Chế độ AI Trực tuyến (Online Gemini 1.5)** nhé!';
  }

  // ==========================================================================
  // 1. BỘ TÍNH TOÁN TOÁN HỌC & CÔNG THỨC (Math Evaluator)
  // ==========================================================================
  static String? _tryEvaluateMath(String raw, String lower) {
    // Nhận diện câu hỏi điểm thi hoặc công thức BTL
    if (lower.contains('tính điểm') || lower.contains('thang điểm') || lower.contains('điểm thi')) {
      return '📊 **Công thức tính điểm thi trắc nghiệm (Thang điểm 10):**\n\n'
          r'$$\text{Điểm} = \left(\frac{\text{Số câu đúng}}{\text{Tổng số câu}}\right) \times 10$$'
          '\n\n'
          '**Ví dụ minh họa:**\n'
          r'- Đúng 16/20 câu: $(16 / 20) \times 10 = \mathbf{8.0\text{ điểm}}$ (Giỏi)'
          '\n'
          r'- Đúng 18/20 câu: $(18 / 20) \times 10 = \mathbf{9.0\text{ điểm}}$ (Xuất sắc)'
          '\n'
          '- Mỗi câu trong đề 20 câu tương đương **0.5 điểm**.';
    }

    // Nhận diện biểu thức số học đơn giản: ví dụ "2 + 2", "5 * 10", "100 / 4"
    final mathRegex = RegExp(r'(\d+(?:\.\d+)?)\s*([\+\-\*\/xX:])\s*(\d+(?:\.\d+)?)');
    final match = mathRegex.firstMatch(raw);
    if (match != null) {
      final num1 = double.tryParse(match.group(1)!);
      final op = match.group(2)!;
      final num2 = double.tryParse(match.group(3)!);

      if (num1 != null && num2 != null) {
        double result = 0;
        String opName = '';
        switch (op) {
          case '+':
            result = num1 + num2;
            opName = 'phép cộng';
            break;
          case '-':
            result = num1 - num2;
            opName = 'phép trừ';
            break;
          case '*':
          case 'x':
          case 'X':
            result = num1 * num2;
            opName = 'phép nhân';
            break;
          case '/':
          case ':':
            if (num2 == 0) return '⚠️ **Lỗi toán học:** Không thể thực hiện phép chia cho số 0.';
            result = num1 / num2;
            opName = 'phép chia';
            break;
        }

        final resStr = (result % 1 == 0) ? result.toInt().toString() : result.toStringAsFixed(2);
        return '🔢 **Kết quả tính toán ($opName):**\n\n'
            '**$num1 $op $num2 = $resStr**\n\n'
            '- Biểu thức thực hiện: **$num1 $op $num2**\n'
            '- Kết quả chính xác: **$resStr**';
      }
    }
    return null;
  }

  // ==========================================================================
  // 2. BỘ PHÂN BIỆT & SO SÁNH (Comparison & Contrast Engine)
  // ==========================================================================
  static String? _tryCompareConcepts(String lower) {
    final isCompare = lower.contains('phân biệt') ||
        lower.contains('so sánh') ||
        lower.contains('khác nhau') ||
        lower.contains('vs') ||
        lower.contains('difference');

    if (!isCompare) return null;

    // List vs Tuple
    if (lower.contains('list') && lower.contains('tuple')) {
      return '⚖️ **So sánh chi tiết giữa List và Tuple:**\n\n'
          '| Tiêu chí | List (Danh sách) | Tuple (Bộ giá trị / Record) |\n'
          '| :--- | :--- | :--- |\n'
          '| **Tính thay đổi (Mutability)** | **Mutable** (Có thể thêm, sửa, xóa phần tử sau khi tạo). | **Immutable** (Bất biến, không thể sửa đổi sau khi khởi tạo). |\n'
          '| **Cú pháp khai báo** | `var list = [1, 2, 3];` | Dart 3 Record: `var t = (1, "EduMaster");` |\n'
          '| **Hiệu năng & Bộ nhớ** | Tốn nhiều bộ nhớ hơn do cần cấp phát động (Dynamic array). | Tối ưu bộ nhớ hơn, tốc độ truy xuất cực nhanh. |\n'
          '| **Trường hợp sử dụng** | Dùng khi tập dữ liệu thường xuyên co giãn (ví dụ danh sách câu hỏi). | Dùng để đóng gói các giá trị đi liền nhau (ví dụ tọa độ (x, y), cặp key-value). |\n\n'
          '💡 **Ví dụ trong Dart 3:**\n'
          '```dart\n'
          '// List (Thay đổi được)\n'
          'List<int> numbers = [1, 2];\n'
          'numbers.add(3); // Hợp lệ!\n\n'
          '// Tuple / Record (Bất biến)\n'
          'final (name, age) = ("Sinh viên", 20);\n'
          'print(name); // Sinh viên\n'
          '```';
    }

    // final vs const
    if (lower.contains('final') && lower.contains('const')) {
      return '⚖️ **So sánh giữa final và const trong Dart:**\n\n'
          '| Tiêu chí | `final` | `const` |\n'
          '| :--- | :--- | :--- |\n'
          '| **Thời điểm gán giá trị** | **Runtime** (Khi ứng dụng đang chạy, ví dụ `DateTime.now()`). | **Compile-time** (Biết trước giá trị ngay lúc biên dịch mã nguồn). |\n'
          '| **Vùng nhớ (Memory)** | Mỗi đối tượng tạo ra một ô nhớ riêng biệt. | Được gom chung vào bảng hằng số (Canonicalized), tiết kiệm RAM tối đa. |\n'
          '| **Quy tắc gán** | Chỉ gán giá trị duy nhất 1 lần. | Bắt buộc giá trị bên trong cũng phải là const hằng số. |\n\n'
          '💡 **Ví dụ minh họa:**\n'
          '```dart\n'
          'final now = DateTime.now(); // HỢP LỆ (xác định lúc runtime)\n'
          '// const now = DateTime.now(); // LỖI BIÊN DỊCH!\n'
          'const pi = 3.14159;         // HỢP LỆ (biết trước lúc compile)\n'
          '```';
    }

    // StatelessWidget vs StatefulWidget
    if ((lower.contains('stateless') || lower.contains('statelesswidget')) &&
        (lower.contains('stateful') || lower.contains('statefulwidget'))) {
      return '⚖️ **So sánh StatelessWidget vs StatefulWidget:**\n\n'
          '1. **StatelessWidget:**\n'
          '   - Là widget **bất biến** (Immutable), không lưu giữ trạng thái có thể thay đổi theo thời gian.\n'
          '   - Toàn bộ cấu hình được truyền từ bên ngoài vào qua constructor.\n'
          '   - Dùng cho: Nút bấm tĩnh, icon, văn bản hiển thị tiêu đề, thẻ giới thiệu...\n\n'
          '2. **StatefulWidget:**\n'
          '   - Tách làm 2 lớp: Lớp `StatefulWidget` và lớp `State<T>` đi kèm.\n'
          '   - Cho phép gọi `setState()` để yêu cầu Flutter dựng lại (Rebuild) giao diện khi dữ liệu biến thiên.\n'
          '   - Dùng cho: Form nhập liệu, đếm giờ thi, màn hình làm trắc nghiệm, lật thẻ flashcard.';
    }

    // SQL vs NoSQL
    if (lower.contains('sql') && lower.contains('nosql')) {
      return '⚖️ **So sánh SQL (Quan hệ) và NoSQL (Phi quan hệ):**\n\n'
          '| Đặc điểm | SQL (Relational - ví dụ SQLite, MySQL) | NoSQL (Document - ví dụ Firebase Firestore, MongoDB) |\n'
          '| :--- | :--- | :--- |\n'
          '| **Cấu trúc dữ liệu** | Bảng có dòng và cột nghiêm ngặt (Strict Schema). | Tài liệu linh hoạt JSON / BSON (Schema-less). |\n'
          '| **Mối quan hệ** | Hỗ trợ Foreign Key, JOIN nhiều bảng phức tạp. | Dữ liệu phi chuẩn hóa (Denormalized), nhúng trực tiếp. |\n'
          '| **Khả năng mở rộng** | Mở rộng theo chiều dọc (Vertical Scaling - tăng cấu hình máy chủ). | Mở rộng theo chiều ngang (Horizontal Scaling - chia cụm sharding). |\n'
          '| **Ứng dụng trong EduMaster** | Dùng **SQLite FTS** cho Từ điển IT ngoại tuyến siêu tốc. | Dùng **Firestore** cho Bảng xếp hạng đồng bộ thời gian thực. |';
    }

    // Future vs Stream
    if (lower.contains('future') && lower.contains('stream')) {
      return '⚖️ **So sánh Future vs Stream trong lập trình bất đồng bộ Dart:**\n\n'
          '- **Future:** Đại diện cho **một giá trị duy nhất** (hoặc một lỗi) sẽ được trả về trong tương lai (Ví dụ: Gọi 1 HTTP GET request, đọc 1 file JSON).\n'
          '- **Stream:** Đại diện cho **một chuỗi các sự kiện/giá trị liên tục theo thời gian** (Ví dụ: Lắng nghe vị trí GPS, đồng hồ đếm ngược từng giây, dữ liệu bảng xếp hạng Firebase thời gian thực).\n\n'
          '💡 Trong Flutter: Dùng `FutureBuilder` để hiển thị dữ liệu từ Future, và `StreamBuilder` để tự động render lại mỗi khi Stream bắn dữ liệu mới.';
    }

    return null;
  }

  // ==========================================================================
  // 3. KHO TRI THỨC CHUYÊN SÂU (Deep Knowledge Base)
  // ==========================================================================
  static String? _lookupKnowledgeBase(String lower) {
    // ── SM-2 Algorithm ──────────────────────────────────────────────────────
    if (lower.contains('sm-2') || lower.contains('sm2') || lower.contains('supermemo')) {
      return '🧠 **Thuật toán lặp lại ngắt quãng SuperMemo SM-2:**\n\n'
          'Thuật toán SM-2 giúp tối ưu hóa trí nhớ dài hạn dựa trên 3 tham số cốt lõi:\n'
          r'1. **Số lần lặp n:** Đếm số lần ôn tập thành công liên tiếp.' '\n'
          r'2. **Hệ số độ dễ EF (Ease Factor):** Khởi tạo EF = 2.5, chặn dưới EF >= 1.3.' '\n'
          r'   $$EF = \max(1.3, EF + (0.1 - (5 - q) \times (0.08 + (5 - q) \times 0.02)))$$' '\n'
          r'3. **Khoảng cách ôn tập I (Interval tính bằng ngày):**' '\n'
          r'   - Lần 1: I(1) = 1 ngày.' '\n'
          r'   - Lần 2: I(2) = 6 ngày.' '\n'
          r'   - Lần n > 2: I(n) = \text{round}(I(n - 1) \times EF).' '\n'
          r'4. **Quy tắc quên (q < 3):** Nếu điểm đánh giá < 3, thẻ bị reset n = 0 và phải ôn lại vào ngày hôm sau.';
    }

    // ── Clean Architecture ──────────────────────────────────────────────────
    if (lower.contains('clean architecture') || lower.contains('kiến trúc sạch')) {
      return '🏛️ **Kiến trúc Clean Architecture trong Flutter:**\n\n'
          'Clean Architecture phân tách dự án thành 3 tầng độc lập theo chiều phụ thuộc hướng vào trong:\n\n'
          '1. **Tầng Presentation (Giao diện):**\n'
          '   - Chứa Screens, Widgets và Providers (`ChangeNotifier`).\n'
          '   - Lắng nghe state và cập nhật UI, không bao giờ chứa logic tính toán nặng.\n\n'
          '2. **Tầng Domain (Nghiệp vụ cốt lõi):**\n'
          '   - Chứa Entities (Thực thể dữ liệu bất biến) và Repository Interfaces trừu tượng.\n'
          '   - Hoàn toàn độc lập, không phụ thuộc vào bất kỳ thư viện hay framework bên ngoài nào.\n\n'
          '3. **Tầng Data (Dữ liệu & Ngoại vi):**\n'
          '   - Triển khai cụ thể các Repository (`RepositoryImpl`).\n'
          '   - Quản lý các DataSources: SQLite, SharedPreferences, REST API, Firebase.';
    }

    // ── State Management: Provider, Bloc, Riverpod ──────────────────────────
    if (lower.contains('provider') || lower.contains('quản lý trạng thái') || lower.contains('state management')) {
      return '🔄 **Quản lý trạng thái (State Management) với Provider trong Flutter:**\n\n'
          '- **Nguyên lý hoạt động:** Mô hình Observer (Người quan sát).\n'
          '- **3 thành phần chính:**\n'
          '  1. `ChangeNotifier`: Lớp chứa state và phát tín hiệu bằng `notifyListeners()` khi state thay đổi.\n'
          '  2. `ChangeNotifierProvider`: Widget cung cấp instance của Provider xuống cây widget con.\n'
          '  3. `context.watch<T>()` / `Consumer<T>`: Lắng nghe và tự động dựng lại widget khi có thông báo.\n'
          '- **Ưu điểm:** Tách biệt triệt để Logic và Giao diện, không phải truyền tham số qua nhiều tầng widget (Tránh Prop Drilling).';
    }

    // ── SQLite & FTS ────────────────────────────────────────────────────────
    if (lower.contains('fts') || lower.contains('sqlite') || lower.contains('full-text search')) {
      return '💾 **Cơ sở dữ liệu SQLite & Công nghệ FTS (Full-Text Search):**\n\n'
          r"- **Vấn đề của bảng thông thường:** Lệnh `WHERE term LIKE '%abc%'` buộc hệ điều hành quét tuần tự từng dòng (Full Table Scan O(N)), gây giật lag khi từ điển lớn."
          '\n'
          '- **Giải pháp FTS (FTS3 / FTS4 / FTS5):**\n'
          '  - Xây dựng bảng ảo và chỉ mục đảo (Inverted Index).\n'
          r'  - Tốc độ tra cứu đạt O(\log N), phản hồi tức thì dưới 5ms ngay khi gõ từng phím.'
          '\n'
          '- **Trong EduMaster:** Toàn bộ từ điển IT được nạp vào SQLite FTS, hoạt động ngoại tuyến 100%.';
    }

    // ── Async / Await / Future ──────────────────────────────────────────────
    if (lower.contains('async') || lower.contains('await') || lower.contains('bất đồng bộ')) {
      return '⚡ **Lập trình bất đồng bộ (Asynchronous Programming) trong Dart:**\n\n'
          '- **Bản chất của Dart:** Là ngôn ngữ đơn luồng (Single-threaded) với cơ chế **Event Loop** điều phối tác vụ.\n'
          '- **`Future`:** Đại diện cho một kết quả sẽ có trong tương lai.\n'
          '- **`async`:** Từ khóa đánh dấu một hàm sẽ chạy bất đồng bộ và luôn trả về một `Future`.\n'
          '- **`await`:** Tạm dừng thực thi hàm hiện tại cho đến khi `Future` hoàn tất mà **không làm đơ/block luồng giao diện chính (UI Thread)**.\n\n'
          "💡 *Ví dụ:* Nạp dữ liệu 300 câu hỏi từ JSON asset: `final jsonStr = await rootBundle.loadString('path');`";
    }

    // ── BuildContext & Widget Tree ───────────────────────────────────────────
    if (lower.contains('buildcontext') || lower.contains('context')) {
      return '🌳 **BuildContext trong Flutter là gì?**\n\n'
          '- **Bản chất:** `BuildContext` là một đối tượng định danh vị trí chính xác của một Widget bên trong toàn bộ Cây Widget (Widget Tree).\n'
          '- **Công dụng chính:**\n'
          '  1. Định vị và tìm kiếm các Widget tổ tiên (ví dụ `Theme.of(context)`, `MediaQuery.of(context)`).\n'
          '  2. Điều hướng màn hình: `Navigator.of(context).push(...)`.\n'
          '  3. Đọc dữ liệu từ Provider: `context.read<QuizProvider>()` hoặc `context.watch<T>()`.\n'
          '- **Lưu ý quan trọng:** Không nên sử dụng `context` sau các hàm `await` bất đồng bộ nếu chưa kiểm tra cờ `if (!mounted) return;`.';
    }

    // ── Null Safety ─────────────────────────────────────────────────────────
    if (lower.contains('null safety') || lower.contains('null') || lower.contains('late')) {
      return '🛡️ **Cơ chế Sound Null Safety trong Dart 3:**\n\n'
          'Nhằm ngăn chặn triệt để lỗi kinh điển `NullPointerException`, Dart chia kiểu dữ liệu làm 2 loại:\n'
          '1. **Non-nullable (Mặc định):** Biến không thể nhận giá trị null (Ví dụ `int a = 5;`).\n'
          '2. **Nullable (`?`):** Biến có thể null (Ví dụ `String? name = null;`).\n'
          '3. **Các toán tử an toàn:**\n'
          '   - `?.` (Null-aware operator): Gọi phương thức nếu đối tượng khác null.\n'
          '   - `??` (If-null operator): Cung cấp giá trị mặc định nếu biểu thức là null (Ví dụ: `name ?? "Ẩn danh"`).\n'
          '   - `!` (Null assertion): Ép kiểu chắc chắn khác null (Cần hạn chế dùng).\n'
          '   - `late`: Khởi tạo muộn trước lần truy cập đầu tiên.';
    }

    // ── Testing: Unit vs Widget vs Integration ──────────────────────────────
    if (lower.contains('test') || lower.contains('kiểm thử') || lower.contains('meetsguideline')) {
      return '🧪 **Chiến lược kiểm thử phần mềm trong Flutter:**\n\n'
          '1. **Unit Test:** Kiểm thử từng hàm, lớp logic thuần túy (Ví dụ: Thuật toán SM-2, tính điểm thi, chuyển đổi JSON).\n'
          '2. **Widget Test:** Kiểm thử từng widget giao diện trong môi trường cô lập không cần máy ảo thật (Ví dụ: `LoadingView`, `ErrorViewWithRetry`, nút bấm, nhập liệu).\n'
          '3. **Accessibility Test (`meetsGuideline`):**\n'
          r'   - `androidTapTargetGuideline`: Đảm bảo diện tích bấm >= 48 dp.' '\n'
          '   - `textContrastGuideline`: Đảm bảo độ tương phản văn bản đạt chuẩn WCAG AA.\n'
          '   - `labeledTapTargetGuideline`: Đảm bảo nhãn ngữ nghĩa cho trình đọc màn hình.\n'
          '4. **Dự án EduMaster:** Đã triển khai và vượt qua **30/30 bài test tự động**!';
    }

    // ── Git & GitHub Actions ────────────────────────────────────────────────
    if (lower.contains('git') || lower.contains('ci') || lower.contains('github actions')) {
      return '🚀 **Quy trình CI/CD & Quản lý mã nguồn với Git:**\n\n'
          '- **Quy chuẩn Git:** Commit thông điệp rõ ràng theo chuẩn Conventional Commits (`feat:`, `fix:`, `docs:`, `test:`).\n'
          '- **Bảo mật tuyệt đối:** Các tệp nhạy cảm (`*.key`, `*.jks`, `key.properties`, `.env`) bắt buộc phải khai báo trong `.gitignore`.\n'
          '- **GitHub Actions CI:** Tệp `.github/workflows/ci.yml` tự động chạy mỗi khi push mã:\n'
          '  1. Cài đặt môi trường Flutter SDK.\n'
          '  2. Phân tích tĩnh mã nguồn: `flutter analyze --fatal-infos` (Chặn mọi lỗi/cảnh báo).\n'
          '  3. Chạy toàn bộ test tự động: `flutter test`.\n'
          '  4. Biên dịch gói APK kiểm thử.';
    }

    return null;
  }
}
