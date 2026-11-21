import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/quiz_question.dart';
import '../../providers/auth_provider.dart';
import '../../providers/exam_provider.dart';
import '../../providers/quiz_provider.dart';
import '../scanner/qr_scanner_screen.dart';
import '../teacher/teacher_room_detail_screen.dart';
import 'create_custom_question_dialog.dart';
import 'exam_room_screen.dart';

class ExamHubScreen extends StatefulWidget {
  const ExamHubScreen({super.key});

  @override
  State<ExamHubScreen> createState() => _ExamHubScreenState();
}

class _ExamHubScreenState extends State<ExamHubScreen> {
  final TextEditingController _pinController = TextEditingController();

  // Create room form for Teacher
  final TextEditingController _createPinController = TextEditingController();
  final TextEditingController _createTitleController = TextEditingController();
  final TextEditingController _createDurationController = TextEditingController(text: '15');

  // Exam source mode for Teacher: 0 = Preset Decks, 1 = Bank Extractor, 2 = Custom Builder
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
    _generateRandomPin();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExamProvider>().loadRooms();
      // Ensure all 300 questions are loaded for presets/extractors
      final quizProv = context.read<QuizProvider>();
      if (quizProv.allQuestions.isEmpty) {
        quizProv.loadQuestions();
      }
      // Load personal exam history for current student
      final authProv = context.read<AuthProvider>();
      final uid = authProv.currentUser?.id ?? 'guest';
      context.read<ExamProvider>().loadStudentHistory(uid);
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
                    Expanded(
                      child: Text(
                        'Danh sách câu hỏi trong đề (${questions.length} câu)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
    final authProv = context.watch<AuthProvider>();
    final isTeacher = authProv.currentUser?.isTeacher ?? false;
    final prov = context.watch<ExamProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(isTeacher ? 'Tạo & Quản lý phòng thi' : 'Phòng thi trực tuyến'),
      ),
      body: isTeacher ? _buildTeacherView(prov) : _buildStudentView(prov),
    );
  }

  // ── LUỒNG SINH VIÊN (SV): VÀO THI & XEM LỊCH SỬ THI ─────────────────────────
  Widget _buildStudentView(ExamProvider prov) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PIN Entry Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nhập mã PIN hoặc Quét mã QR vào phòng',
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
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => _joinExam(_pinController.text),
                      child: const Text('VÀO PHÒNG THI NGAY', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    'Lưu ý: Không thoát ứng dụng hoặc chuyển màn hình khi đang làm bài thi. Mọi vi phạm đều được tự động ghi nhận vào biên bản thi.',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Lịch sử thi cá nhân ──────────────────────────────────
          Row(
            children: [
              const Icon(Icons.history_edu_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Lịch sử thi của bạn',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                tooltip: 'Làm mới lịch sử',
                onPressed: () {
                  final authProv = context.read<AuthProvider>();
                  final uid = authProv.currentUser?.id ?? 'guest';
                  prov.loadStudentHistory(uid);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (prov.studentHistory.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text(
                    'Bạn chưa tham gia kỳ thi nào.',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nhập mã PIN hoặc quét QR ở trên để vào phòng thi ngay!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          else
            ...prov.studentHistory.map((entry) {
              final pct = entry.percentage;
              final isPassed = pct >= 50;
              final mins = entry.timeSpentSeconds ~/ 60;
              final secs = entry.timeSpentSeconds % 60;
              final timeStr = '${mins}p ${secs.toString().padLeft(2, '0')}s';
              final dt = entry.submittedAt;
              final dateStr =
                  '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} — '
                  '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isPassed ? AppColors.success.withOpacity(0.4) : AppColors.error.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPassed
                                  ? AppColors.success.withOpacity(0.1)
                                  : AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isPassed ? '✅ Đạt' : '❌ Chưa đạt',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isPassed ? AppColors.success : AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.roomTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.vpn_key_rounded, size: 13, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Phòng: ${entry.roomId}',
                            style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.person_outline_rounded, size: 13, color: AppColors.textSecondaryLight),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'GV: ${entry.teacherName}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.score_rounded, size: 13, color: AppColors.textSecondaryLight),
                          const SizedBox(width: 4),
                          Text(
                            'Kết quả: ${entry.score}/${entry.totalQuestions} (${pct.toStringAsFixed(0)}%)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isPassed ? AppColors.success : AppColors.error,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.timer_outlined, size: 13, color: AppColors.textSecondaryLight),
                          const SizedBox(width: 4),
                          Text(
                            'Thời gian: $timeStr',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
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
    );
  }

  // ── LUỒNG GIÁO VIÊN (GV): TẠO ĐỀ THI & QUẢN LÝ PHÒNG THI ─────────────────────
  Widget _buildTeacherView(ExamProvider prov) {
    final authProv = context.watch<AuthProvider>();
    final teacherName = authProv.currentUser?.name ?? 'Giảng viên CNTT';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Soạn đề & Tạo phòng thi mới',
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
                        flex: 11,
                        child: TextField(
                          controller: _createPinController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: 'Mã PIN phòng',
                            hintText: 'VD: KTHP2026',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.vpn_key_rounded, size: 20),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.casino_outlined, size: 20),
                              tooltip: 'Sinh mã PIN ngẫu nhiên',
                              onPressed: _generateRandomPin,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 9,
                        child: TextField(
                          controller: _createDurationController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Thời gian',
                            suffixText: 'phút',
                            hintText: '15, 60...',
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.timer_outlined, size: 20),
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
                      isExpanded: true,
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
                            isExpanded: true,
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
                            isExpanded: true,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Câu hỏi tự soạn: ${_customQuestions.length} câu',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Thêm câu hỏi', style: TextStyle(fontSize: 12)),
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
                        flex: 2,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                            side: const BorderSide(color: AppColors.secondary),
                          ),
                          icon: const Icon(Icons.visibility_rounded, size: 16, color: AppColors.secondary),
                          label: const Text(
                            'Xem trước',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.secondary),
                          ),
                          onPressed: () {
                            final qs = _buildQuestionsForNewRoom();
                            _previewQuestions(context, qs);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          ),
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
                              teacherName: teacherName,
                              durationMinutes: dur,
                              questions: questions,
                            );

                            _createTitleController.clear();
                            _generateRandomPin();

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
                          icon: const Icon(Icons.qr_code_rounded, size: 18),
                          label: const Text(
                            'Tạo phòng & QR',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Phòng thi đã tạo (Giáo viên xem kết quả) ─────────────
          Row(
            children: [
              const Icon(Icons.list_alt_rounded, color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Phòng thi đã tạo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                tooltip: 'Làm mới danh sách',
                onPressed: () => prov.loadRooms(),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (prov.availableRooms.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Center(
                child: Text(
                  'Chưa có phòng thi nào. Hãy tạo phòng thi mới ở trên!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
              ),
            )
          else
            ...prov.availableRooms.map((room) {
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TeacherRoomDetailScreen(room: room),
                      ),
                    );
                  },
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.assignment_outlined, size: 18),
                  ),
                  title: Text(
                    room.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: Text(
                    'Mã PIN: ${room.id} • ${room.durationMinutes} phút • ${room.questions.length} câu',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.qr_code_2_rounded, color: AppColors.primary),
                        tooltip: 'Mã QR phòng thi',
                        onPressed: () => _showQrDialog(context, room.id, room.title),
                      ),
                      IconButton(
                        icon: const Icon(Icons.analytics_rounded, color: AppColors.secondary),
                        tooltip: 'Chi tiết / Giám sát & Thống kê',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TeacherRoomDetailScreen(room: room),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
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
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.secondary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : AppColors.textSecondaryLight),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
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
      color: isSelected ? AppColors.secondary.withOpacity(0.08) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? AppColors.secondary : AppColors.borderLight,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
          color: isSelected ? AppColors.secondary : Colors.grey,
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
