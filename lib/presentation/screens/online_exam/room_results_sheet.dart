import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/exam.dart';

class RoomResultsSheet extends StatelessWidget {
  final ExamRoom room;
  final List<ExamSessionResult> results;

  const RoomResultsSheet({
    super.key,
    required this.room,
    required this.results,
  });

  static void show(BuildContext context, ExamRoom room, List<ExamSessionResult> results) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RoomResultsSheet(room: room, results: results),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m phút ${s.toString().padLeft(2, '0')} giây';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = results.length;

    // Calculate metrics
    double avgScore = 0;
    int maxScore = 0;
    int passCount = 0;

    if (count > 0) {
      int sumScore = 0;
      for (final r in results) {
        sumScore += r.score;
        if (r.score > maxScore) maxScore = r.score;
        final pct = r.totalQuestions > 0 ? (r.score / r.totalQuestions) * 100 : 0;
        if (pct >= 50) passCount++;
      }
      avgScore = sumScore / count;
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.analytics_rounded, color: AppColors.primary, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kết quả thi: ${room.id}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        room.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'Chưa có học sinh nào nộp bài',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Hãy chia sẻ mã PIN "${room.id}" hoặc quét mã QR để học sinh vào làm bài.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Statistics Row
                        Row(
                          children: [
                            _buildMetricCard(
                              title: 'Bài đã nộp',
                              value: '$count',
                              subtitle: 'Học sinh',
                              color: AppColors.primary,
                              icon: Icons.people_rounded,
                            ),
                            const SizedBox(width: 12),
                            _buildMetricCard(
                              title: 'Điểm TB',
                              value: avgScore.toStringAsFixed(1),
                              subtitle: 'Điểm cao: $maxScore',
                              color: AppColors.accent,
                              icon: Icons.grade_rounded,
                            ),
                            const SizedBox(width: 12),
                            _buildMetricCard(
                              title: 'Tỉ lệ Đạt',
                              value: '${count > 0 ? ((passCount / count) * 100).toStringAsFixed(0) : 0}%',
                              subtitle: '$passCount/$count học sinh',
                              color: AppColors.success,
                              icon: Icons.check_circle_outline_rounded,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Section Title
                        Row(
                          children: [
                            const Icon(Icons.format_list_bulleted_rounded, size: 20, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Danh sách bài nộp của học sinh ($count)',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // List of student submissions
                        ...results.map((res) {
                          final isPassed = res.totalQuestions > 0 &&
                              ((res.score / res.totalQuestions) * 100) >= 50.0;
                          final dateStr = DateFormat('HH:mm - dd/MM/yyyy').format(res.submittedAt);
                          final hasViolations = res.appSwitchViolations > 0;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 1.5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: hasViolations ? AppColors.warning.withOpacity(0.5) : AppColors.borderLight,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: isPassed
                                            ? AppColors.success.withOpacity(0.15)
                                            : AppColors.error.withOpacity(0.15),
                                        child: Text(
                                          '${res.score}/${res.totalQuestions}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: isPassed ? AppColors.success : AppColors.error,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              res.studentName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Thời gian làm: ${_formatDuration(res.timeSpentSeconds)} • Nộp lúc $dateStr',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textSecondaryLight,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Anti-cheat status banner
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: hasViolations
                                          ? AppColors.warning.withOpacity(0.12)
                                          : AppColors.success.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          hasViolations ? Icons.warning_amber_rounded : Icons.verified_user_rounded,
                                          size: 16,
                                          color: hasViolations ? AppColors.warning : AppColors.success,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            hasViolations
                                                ? 'Cảnh báo: Phát hiện rời màn hình ${res.appSwitchViolations} lần!'
                                                : 'Bài thi hợp lệ — Không phát hiện gian lận chuyển màn hình',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: hasViolations ? AppColors.warning : AppColors.success,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // If violations exist, list timestamps
                                  if (hasViolations && res.violationTimestamps.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    ...res.violationTimestamps.map((ts) {
                                      return Padding(
                                        padding: const EdgeInsets.only(left: 12, bottom: 2),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.arrow_right_rounded, size: 16, color: AppColors.error),
                                            Text(
                                              ts,
                                              style: const TextStyle(fontSize: 11, color: AppColors.error),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight),
            ),
          ],
        ),
      ),
    );
  }
}
