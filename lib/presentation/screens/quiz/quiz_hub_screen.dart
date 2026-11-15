import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/quiz_provider.dart';
import 'mock_exam_setup_sheet.dart';
import 'quiz_play_screen.dart';

class QuizHubScreen extends StatelessWidget {
  const QuizHubScreen({super.key});

  void _startQuiz(BuildContext context, {int grade = 0, QuizMode mode = QuizMode.practice}) {
    context.read<QuizProvider>().loadQuestions(grade: grade, mode: mode);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QuizPlayScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ôn tập trắc nghiệm'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Ngân hàng 300 câu hỏi song ngữ',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.school_rounded, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Luyện thi & Củng cố kiến thức',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '20 khối kiến thức chuyên sâu • Thi thử tính giờ chuẩn 50 câu / 60 phút',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Feature Banner: Thi thử tính giờ chuẩn
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.warning, width: 1.5),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => MockExamSetupSheet.show(context),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.alarm_on_rounded, color: AppColors.warning, size: 30),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Thi thử tính giờ',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                SizedBox(width: 6),
                                Chip(
                                  padding: EdgeInsets.zero,
                                  labelPadding: EdgeInsets.symmetric(horizontal: 6),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  label: Text('Chuẩn 50c / 60p', style: TextStyle(fontSize: 10, color: Colors.white)),
                                  backgroundColor: AppColors.warning,
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tùy chọn khối thi, mức độ (Dễ/Vừa/Khó), số câu và số phút theo yêu cầu.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textSecondaryLight),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Quick Actions: Practice, Exam, Wrong Review
            Text(
              'Chế độ ôn luyện khác',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildModeTile(
              context,
              icon: Icons.menu_book_rounded,
              color: AppColors.primary,
              title: 'Luyện tập tự do',
              subtitle: 'Làm bài không giới hạn thời gian, có lời giải & AI Tutor',
              onTap: () => _startQuiz(context, grade: 0, mode: QuizMode.practice),
            ),
            const SizedBox(height: 12),
            _buildModeTile(
              context,
              icon: Icons.replay_circle_filled_rounded,
              color: AppColors.error,
              title: 'Ôn lại các câu đã làm sai',
              subtitle: 'Luyện lại danh sách những câu từng chọn sai để ghi nhớ',
              onTap: () => _startQuiz(context, grade: 0, mode: QuizMode.wrongReview),
            ),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textSecondaryLight),
            ],
          ),
        ),
      ),
    );
  }
}
