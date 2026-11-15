import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/exam.dart';
import '../../../domain/entities/quiz_question.dart';
import '../../providers/exam_provider.dart';
import '../../providers/quiz_provider.dart';
import '../scanner/qr_scanner_screen.dart';
import 'create_custom_question_dialog.dart';
import 'exam_room_screen.dart';
import 'room_results_sheet.dart';

class ExamHubScreen extends StatefulWidget {
  const ExamHubScreen({super.key});

  @override
  State<ExamHubScreen> createState() => _ExamHubScreenState();
}

class _ExamHubScreenState extends State<ExamHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _pinController = TextEditingController();

  // Create room form
  final TextEditingController _createPinController = TextEditingController();
  final TextEditingController _createTitleController = TextEditingController();
  final TextEditingController _createDurationController = TextEditingController(text: '15');

  // Exam source mode: 0 = Preset Decks, 1 = Bank Extractor, 2 = Custom Builder
  int _examSourceType = 0;

  // Preset option: 0..3
  int _selectedPreset = 0;

  // Bank Extractor options
  int _extractorGrade = 0; // 0 = All
  String _extractorDifficulty = 'all';
  int _extractorQuestionCount = 20;

  // Custom composed questions list
  final List<QuizQuestion> _customQuestions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _generateRandomPin();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExamProvider>().loadRooms();
      // Ensure all 300 questions are loaded for presets/extractors
      final quizProv = context.read<QuizProvider>();
      if (quizProv.allQuestions.isEmpty) {
        quizProv.loadQuestions();
      }
    });
  }

  void _generateRandomPin() {
    final rand = Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final code = List.generate(6, (index) => chars[rand.nextInt(chars.length)]).join();
    _createPinController.text = code;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pinController.dispose();
    _createPinController.dispose();
    _createTitleController.dispose();
    _createDurationController.dispose();
    super.dispose();
  }

  Future<void> _joinExam(String pin) async {
    final cleanPin = pin.trim().toUpperCase();
    if (cleanPin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mã PIN phòng thi!')),
      );
      return;
    }
    final success = await context.read<ExamProvider>().joinRoom(cleanPin);
    if (success && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ExamRoomScreen()),
      );
    } else if (mounted) {
      final err = context.read<ExamProvider>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _scanQr() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (result != null && result.isNotEmpty && mounted) {
      _pinController.text = result;
      _joinExam(result);
    }
  }

  void _showQrDialog(BuildContext context, String roomId, String title) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: QrImageView(
                  data: roomId,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Mã PIN: $roomId',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Sinh viên bật Camera quét mã QR này để vào thẳng phòng thi.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _viewRoomResults(BuildContext context, ExamRoom room) async {
    final prov = context.read<ExamProvider>();
    final results = await prov.getRoomResults(room.id);
    if (context.mounted) {
      RoomResultsSheet.show(context, room, results);
    }
  }

  List<QuizQuestion> _buildQuestionsForNewRoom() {
    final allQuestions = context.read<QuizProvider>().allQuestions;

    if (_examSourceType == 0) {
      // Preset Decks
      if (allQuestions.isEmpty) return [];
      switch (_selectedPreset) {
        case 0:
          // Đề 1: Cơ bản Ngôn ngữ Dart & OOP (15 câu)
          return allQuestions.where((q) => q.grade <= 3).take(15).toList();
        case 1:
          // Đề 2: Giao diện Flutter, Bố cục & Widget (20 câu)
          return allQuestions.where((q) => q.grade >= 4 && q.grade <= 9).take(20).toList();
        case 2:
          // Đề 3: Chuẩn Kỳ thi KTHP Lập trình Di động (50 câu / 60 phút)
          return (List<QuizQuestion>.from(allQuestions)..shuffle()).take(50).toList();
        case 3:
          // Đề 4: Quản lý trạng thái, SQLite & Kiến trúc (25 câu)
          return allQuestions.where((q) => q.grade >= 12 && q.grade <= 17).take(25).toList();
        default:
          return allQuestions.take(15).toList();
      }
    } else if (_examSourceType == 1) {
      // Bank Extractor
      List<QuizQuestion> pool = List.from(allQuestions);
      if (_extractorGrade > 0) {
        pool = pool.where((q) => q.grade == _extractorGrade).toList();
      }
      if (_extractorDifficulty == 'easy') {
        pool = pool.where((q) => q.grade <= 5).toList();
      } else if (_extractorDifficulty == 'medium') {
        pool = pool.where((q) => q.grade >= 6 && q.grade <= 12).toList();
      } else if (_extractorDifficulty == 'hard') {
        pool = pool.where((q) => q.grade >= 13).toList();
      }
      pool.shuffle();
      final takeCount = pool.length < _extractorQuestionCount ? pool.length : _extractorQuestionCount;
      return pool.take(takeCount).toList();
    } else {
      // Custom builder
      return List.from(_customQuestions);
    }
  }

  void _previewQuestions(BuildContext context, List<QuizQuestion> questions) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.preview_rounded, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Danh sách câu hỏi trong đề (${questions.length} câu)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: questions.isEmpty
                    ? const Center(child: Text('Chưa có câu hỏi nào trong đề!'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: questions.length,
                        itemBuilder: (context, idx) {
                          final q = questions[idx];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Câu ${idx + 1} (${q.category}):',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(q.questionVi, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  const SizedBox(height: 8),
                                  ...List.generate(q.optionsVi.length, (optIdx) {
                                    final isCorrect = optIdx == q.correctIndex;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 2.0),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                                            size: 14,
                                            color: isCorrect ? AppColors.success : Colors.grey,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              '${String.fromCharCode(65 + optIdx)}. ${q.optionsVi[optIdx]}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                                                color: isCorrect ? AppColors.success : null,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ExamProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phòng thi trực tuyến'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.school_rounded), text: 'Sinh viên vào thi'),
            Tab(icon: Icon(Icons.add_task_rounded), text: 'Giảng viên tạo đề'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── TAB 1: SINH VIÊN VÀO THI ──────────────────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PIN Entry Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nhập mã PIN hoặc Quét mã QR',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _pinController,
                                textCapitalization: TextCapitalization.characters,
                                decoration: const InputDecoration(
                                  hintText: 'Ví dụ: EXAM100',
                                  prefixIcon: Icon(Icons.vpn_key_rounded),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 52,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _scanQr,
                                icon: const Icon(Icons.qr_code_scanner_rounded),
                                label: const Text('Quét QR'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _joinExam(_pinController.text),
                            child: const Text('Vào phòng thi'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Anti-cheat policy reminder
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: AppColors.warning, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Lưu ý: Không thoát ứng dụng hoặc chuyển màn hình khi đang làm bài thi. Mọi vi phạm đều được ghi nhận vào biên bản thi.',
                          style: TextStyle(fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // List of available rooms
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Các phòng thi hiện có',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'Làm mới',
                      onPressed: () => prov.loadRooms(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                ...prov.availableRooms.map((room) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              child: Icon(Icons.assignment_outlined, size: 20),
                            ),
                            title: Text(
                              room.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text(
                              '${room.creatorName} • ${room.durationMinutes} phút • Mã: ${room.id} (${room.questions.length} câu)',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.qr_code_2_rounded, color: AppColors.primary, size: 28),
                              tooltip: 'Hiển thị mã QR phòng',
                              onPressed: () => _showQrDialog(context, room.id, room.title),
                            ),
                            onTap: () {
                              _pinController.text = room.id;
                              _joinExam(room.id);
                            },
                          ),
                          const Divider(height: 14),
                          // Action buttons row for room
                          Row(
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                ),
                                icon: const Icon(Icons.insights_rounded, size: 16),
                                label: const Text('Kết quả bài nộp của học sinh', style: TextStyle(fontSize: 12)),
                                onPressed: () => _viewRoomResults(context, room),
                              ),
                              const Spacer(),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                ),
                                onPressed: () {
                                  _pinController.text = room.id;
                                  _joinExam(room.id);
                                },
                                child: const Text('Vào thi', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // ── TAB 2: GIẢNG VIÊN TẠO ĐỀ & CHỌN BỘ ĐỀ ──────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Thông tin phòng thi mới',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),

                        // Title
                        TextField(
                          controller: _createTitleController,
                          decoration: const InputDecoration(
                            labelText: 'Tên kỳ thi / Môn học',
                            hintText: 'Ví dụ: Kiểm tra Giữa kỳ Lập trình Di động',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.edit_note_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // PIN & Duration
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _createPinController,
                                textCapitalization: TextCapitalization.characters,
                                decoration: InputDecoration(
                                  labelText: 'Mã PIN phòng',
                                  hintText: 'VD: KTHP2026',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.vpn_key_rounded),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.casino_outlined, size: 20),
                                    tooltip: 'Sinh mã PIN ngẫu nhiên',
                                    onPressed: _generateRandomPin,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _createDurationController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Thời gian (phút)',
                                  hintText: '15, 60...',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.timer_outlined),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── Nguồn bộ đề thi ────────────────────────────────
                        Text(
                          'Chọn nguồn câu hỏi cho đề thi',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),

                        // Segmented selector for Source Type
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              _buildSourceSegment(0, 'Bộ đề có sẵn', Icons.folder_special_rounded),
                              _buildSourceSegment(1, 'Lọc ngân hàng', Icons.filter_alt_rounded),
                              _buildSourceSegment(2, 'Tự soạn đề mới', Icons.edit_rounded),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── TYPE 0: BỘ ĐỀ CHUẨN BỊ SẴN ────────────────────
                        if (_examSourceType == 0) ...[
                          _buildPresetTile(
                            0,
                            '📘 Đề 1: Cơ bản Ngôn ngữ Dart & OOP',
                            '15 câu • Thời lượng gợi ý: 15-20 phút • Nhận biết & Cú pháp',
                          ),
                          const SizedBox(height: 8),
                          _buildPresetTile(
                            1,
                            '📗 Đề 2: Giao diện Flutter, Widget & Bố cục',
                            '20 câu • Thời lượng gợi ý: 25-30 phút • Stateless/Stateful & Layout',
                          ),
                          const SizedBox(height: 8),
                          _buildPresetTile(
                            2,
                            '📕 Đề 3: Chuẩn Kỳ thi KTHP Lập trình Di động',
                            '50 câu • Thời lượng gợi ý: 60 phút • Tổng hợp toàn diện 20 khối',
                          ),
                          const SizedBox(height: 8),
                          _buildPresetTile(
                            3,
                            '📙 Đề 4: Quản lý trạng thái, SQLite & Kiến trúc',
                            '25 câu • Thời lượng gợi ý: 30-40 phút • Provider, Clean Arch, SQLite',
                          ),
                        ],

                        // ── TYPE 1: TRÍCH XUẤT TỪ NGÂN HÀNG 300 CÂU ───────
                        if (_examSourceType == 1) ...[
                          DropdownButtonFormField<int>(
                            value: _extractorGrade,
                            decoration: const InputDecoration(
                              labelText: 'Khối kiến thức',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.category_rounded),
                            ),
                            items: const [
                              DropdownMenuItem(value: 0, child: Text('Tất cả các khối (Tổng hợp 300 câu)')),
                              DropdownMenuItem(value: 1, child: Text('Khối 1: Ngôn ngữ Dart')),
                              DropdownMenuItem(value: 3, child: Text('Khối 3: Flutter Core & Widget')),
                              DropdownMenuItem(value: 4, child: Text('Khối 4: Bố cục & Layout')),
                              DropdownMenuItem(value: 7, child: Text('Khối 7: Form & Biểu mẫu')),
                              DropdownMenuItem(value: 12, child: Text('Khối 12: Quản lý trạng thái')),
                              DropdownMenuItem(value: 13, child: Text('Khối 13: Dữ liệu & SQLite')),
                              DropdownMenuItem(value: 14, child: Text('Khối 14: Kiến trúc Clean Architecture')),
                              DropdownMenuItem(value: 16, child: Text('Khối 16: Kiểm thử & Testing')),
                              DropdownMenuItem(value: 20, child: Text('Khối 20: AI trong Flutter')),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _extractorGrade = v);
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _extractorDifficulty,
                                  decoration: const InputDecoration(
                                    labelText: 'Mức độ',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'all', child: Text('Tất cả mức độ')),
                                    DropdownMenuItem(value: 'easy', child: Text('Cơ bản (Dễ)')),
                                    DropdownMenuItem(value: 'medium', child: Text('Thông hiểu')),
                                    DropdownMenuItem(value: 'hard', child: Text('Vận dụng cao')),
                                  ],
                                  onChanged: (v) {
                                    if (v != null) setState(() => _extractorDifficulty = v);
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: _extractorQuestionCount,
                                  decoration: const InputDecoration(
                                    labelText: 'Số câu',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 10, child: Text('10 câu')),
                                    DropdownMenuItem(value: 20, child: Text('20 câu')),
                                    DropdownMenuItem(value: 30, child: Text('30 câu')),
                                    DropdownMenuItem(value: 50, child: Text('50 câu (Chuẩn ⭐)')),
                                  ],
                                  onChanged: (v) {
                                    if (v != null) setState(() => _extractorQuestionCount = v);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],

                        // ── TYPE 2: GIẢNG VIÊN TỰ SOẠN ĐỀ MỚI ──────────────
                        if (_examSourceType == 2) ...[
                          Row(
                            children: [
                              Text(
                                'Câu hỏi tự soạn: ${_customQuestions.length} câu',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                  foregroundColor: Colors.white,
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Thêm câu hỏi'),
                                onPressed: () async {
                                  final q = await CreateCustomQuestionDialog.show(
                                    context,
                                    1000 + _customQuestions.length + 1,
                                  );
                                  if (q != null) {
                                    setState(() => _customQuestions.add(q));
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_customQuestions.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: const Center(
                                child: Text(
                                  'Chưa có câu hỏi tự soạn nào.\nBấm nút "Thêm câu hỏi" để bắt đầu soạn đề!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                                ),
                              ),
                            )
                          else
                            ..._customQuestions.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final q = entry.value;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    radius: 12,
                                    child: Text('${idx + 1}', style: const TextStyle(fontSize: 11)),
                                  ),
                                  title: Text(q.questionVi, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  subtitle: Text('Đáp án: ${String.fromCharCode(65 + q.correctIndex)}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                                    onPressed: () => setState(() => _customQuestions.removeAt(idx)),
                                  ),
                                ),
                              );
                            }),
                        ],

                        const SizedBox(height: 20),

                        // Action Buttons: Preview + Create Room
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.visibility_rounded, size: 18),
                                label: const Text('Xem trước đề'),
                                onPressed: () {
                                  final qs = _buildQuestionsForNewRoom();
                                  _previewQuestions(context, qs);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final title = _createTitleController.text.trim();
                                  final pin = _createPinController.text.trim().toUpperCase();
                                  final dur = int.tryParse(_createDurationController.text.trim()) ?? 15;

                                  if (title.isEmpty || pin.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Vui lòng điền đủ tiêu đề và mã PIN!')),
                                    );
                                    return;
                                  }

                                  final questions = _buildQuestionsForNewRoom();
                                  if (questions.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Bộ đề chưa có câu hỏi nào. Vui lòng chọn hoặc thêm câu hỏi!'),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                    return;
                                  }

                                  await prov.createNewRoom(
                                    roomId: pin,
                                    title: title,
                                    teacherName: 'Giảng viên CNTT',
                                    durationMinutes: dur,
                                    questions: questions,
                                  );

                                  _createTitleController.clear();
                                  _generateRandomPin();
                                  _tabController.animateTo(0);

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Đã tạo phòng thi $pin (${questions.length} câu) thành công!'),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                    _showQrDialog(context, pin, title);
                                  }
                                },
                                icon: const Icon(Icons.add_circle_outline_rounded),
                                label: const Text('Tạo phòng & Sinh mã QR'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceSegment(int type, String label, IconData icon) {
    final isSelected = _examSourceType == type;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _examSourceType = type;
            if (type == 0 && _selectedPreset == 2) {
              _createDurationController.text = '60';
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : AppColors.textSecondaryLight),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetTile(int index, String title, String subtitle) {
    final isSelected = _selectedPreset == index;
    return Card(
      color: isSelected ? AppColors.primary.withOpacity(0.08) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.borderLight,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
          color: isSelected ? AppColors.primary : Colors.grey,
        ),
        title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, fontSize: 13)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        onTap: () {
          setState(() {
            _selectedPreset = index;
            if (index == 2) {
              _createDurationController.text = '60';
            } else if (index == 0) {
              _createDurationController.text = '15';
            } else {
              _createDurationController.text = '30';
            }
          });
        },
      ),
    );
  }
}
