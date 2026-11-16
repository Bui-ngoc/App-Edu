import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/exam_provider.dart';
import 'teacher_room_detail_screen.dart';

class TeacherExamHistoryScreen extends StatefulWidget {
  const TeacherExamHistoryScreen({super.key});

  @override
  State<TeacherExamHistoryScreen> createState() => _TeacherExamHistoryScreenState();
}

class _TeacherExamHistoryScreenState extends State<TeacherExamHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExamProvider>().loadRooms();
    });
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
                'Sinh viên quét mã QR này để vào phòng thi.',
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
    final examProv = context.watch<ExamProvider>();
    final rooms = examProv.availableRooms;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử phòng thi đã tạo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
            onPressed: () => examProv.loadRooms(),
          ),
        ],
      ),
      body: rooms.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'Chưa có phòng thi nào được tạo',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Các phòng thi bạn tạo sẽ được lưu lại lịch sử tại đây để dễ dàng xem lại báo cáo thống kê.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                final dateStr = DateFormat('HH:mm — dd/MM/yyyy').format(room.createdAt);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.borderLight),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'PIN: ${room.id}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              dateStr,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Text(
                          room.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 6),

                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 14, color: AppColors.textSecondaryLight),
                            const SizedBox(width: 4),
                            Text(
                              '${room.durationMinutes} phút',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                            ),
                            const SizedBox(width: 14),
                            const Icon(Icons.quiz_outlined, size: 14, color: AppColors.textSecondaryLight),
                            const SizedBox(width: 4),
                            Text(
                              '${room.questions.length} câu hỏi',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                              label: const Text('Mã QR', style: TextStyle(fontSize: 12)),
                              onPressed: () => _showQrDialog(context, room.id, room.title),
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              icon: const Icon(Icons.analytics_rounded, size: 18),
                              label: const Text('Chi tiết & Giám sát', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
