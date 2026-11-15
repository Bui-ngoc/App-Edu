import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/exam_provider.dart';

class ExamResultScreen extends StatelessWidget {
  const ExamResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final result = context.watch<ExamProvider>().lastResult;

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kết quả thi')),
        body: const Center(child: Text('Không tìm thấy kết quả phiên thi.')),
      );
    }

    final isPassed = result.scoreOnScale10 >= 5.0;
    final minutes = result.timeSpentSeconds ~/ 60;
    final seconds = result.timeSpentSeconds % 60;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả kỳ thi'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Score circle
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: isPassed ? AppColors.success.withOpacity(0.12) : AppColors.error.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isPassed ? AppColors.success : AppColors.error,
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        result.scoreOnScale10.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isPassed ? AppColors.success : AppColors.error,
                        ),
                      ),
                      const Text(
                        'Thang điểm 10',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isPassed ? '🎓 Chúc mừng! Bạn đã đạt yêu cầu bài thi.' : '⚠️ Điểm chưa đạt, hãy cố gắng ở lần sau!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Summary details
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildRow('Thí sinh', result.studentName),
                      const Divider(),
                      _buildRow('Mã phòng thi', result.roomId),
                      const Divider(),
                      _buildRow('Số câu đúng', '${result.score} / ${result.totalQuestions} câu'),
                      const Divider(),
                      _buildRow('Thời gian làm bài', '$minutes phút $seconds giây'),
                      const Divider(),
                      _buildRow(
                        'Cảnh báo rời app',
                        '${result.appSwitchViolations} lần',
                        color: result.appSwitchViolations > 0 ? AppColors.error : AppColors.success,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Anti-cheat audit trail log
              if (result.violationTimestamps.isNotEmpty) ...[
                Card(
                  color: AppColors.error.withOpacity(0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.gavel_rounded, color: AppColors.error, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Nhật ký ghi nhận gian lận (Rời app):',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...result.violationTimestamps.map(
                          (t) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Text('• $t', style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Return button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<ExamProvider>().loadRooms();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Quay về danh sách phòng thi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondaryLight)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
