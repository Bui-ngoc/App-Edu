import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/exam_provider.dart';
import '../../providers/quiz_provider.dart';
import '../scanner/qr_scanner_screen.dart';
import 'exam_room_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExamProvider>().loadRooms();
    });
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

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ExamProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phòng thi trực tuyến (#34)'),
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
          // TAB 1: Student Join Room
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
                        const SizedBox(height: 8),
                        const Text(
                          'Nhận mã phòng thi từ Giảng viên để bắt đầu làm bài.',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                        ),
                        const SizedBox(height: 16),
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
                const SizedBox(height: 24),
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
                          'Hệ thống tự động phát hiện và ghi nhận vi phạm nếu bạn thoát ứng dụng hoặc chuyển tab trong khi làm bài thi.',
                          style: TextStyle(fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Các phòng thi hiện có',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...prov.availableRooms.map((room) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        child: Icon(Icons.assignment_outlined, size: 20),
                      ),
                      title: Text(room.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text('${room.creatorName} • ${room.durationMinutes} phút • Mã: ${room.id}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.qr_code_2_rounded, color: AppColors.primary),
                        tooltip: 'Hiển thị mã QR phòng',
                        onPressed: () => _showQrDialog(context, room.id, room.title),
                      ),
                      onTap: () {
                        _pinController.text = room.id;
                        _joinExam(room.id);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          // TAB 2: Teacher Create Room
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
                        Text('Tạo phòng thi mới',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _createTitleController,
                          decoration: const InputDecoration(
                            labelText: 'Tên kỳ thi / Môn học',
                            hintText: 'Ví dụ: Kiểm tra 15 phút Lập trình Di động',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _createPinController,
                                textCapitalization: TextCapitalization.characters,
                                decoration: const InputDecoration(
                                  labelText: 'Mã PIN phòng',
                                  hintText: 'VD: KTHP2026',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _createDurationController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Thời gian (phút)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
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

                              // Grab sample questions from QuizProvider
                              final sampleQuestions = context.read<QuizProvider>().activeQuestions;
                              final examQuestions = sampleQuestions.isNotEmpty
                                  ? (List.from(sampleQuestions)..shuffle()).take(10).toList()
                                  : [];

                              await prov.createNewRoom(
                                roomId: pin,
                                title: title,
                                teacherName: 'Giảng viên CNTT',
                                durationMinutes: dur,
                                questions: examQuestions.cast(),
                              );

                              _createTitleController.clear();
                              _createPinController.clear();
                              _tabController.animateTo(0);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Đã tạo phòng thi $pin thành công!')),
                                );
                              }
                            },
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            label: const Text('Tạo phòng & Sinh mã QR'),
                          ),
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
}
