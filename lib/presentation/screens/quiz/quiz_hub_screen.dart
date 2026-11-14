import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/quiz_provider.dart';
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
        title: const Text('Ôn tập trắc nghiệm song ngữ'),
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
                      const Icon(Icons.language_rounded, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Luyện thi & Củng cố kiến thức',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Toán học • Tin học • Tiếng Anh • Khoa học tự nhiên',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions: Practice, Exam, Wrong Review
            Text('Chế độ ôn luyện',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            _buildModeTile(
              context,
              icon: Icons.menu_book_rounded,
              color: AppColors.primary,
              title: 'Chế độ Luyện tập tự do',
              subtitle: 'Làm quen bộ câu hỏi, không áp lực thời gian, có trợ lý AI hỗ trợ giải thích',
              onTap: () => _startQuiz(context, grade: 0, mode: QuizMode.practice),
            ),
            const SizedBox(height: 12),
            _buildModeTile(
              context,
              icon: Icons.timer_outlined,
              color: AppColors.warning,
              title: 'Thi thử có bấm giờ (20 phút)',
              subtitle: 'Đề thi 20 câu ngẫu nhiên có đếm ngược, tính điểm và đánh giá năng lực',
              onTap: () => _startQuiz(context, grade: 0, mode: QuizMode.exam),
            ),
            const SizedBox(height: 12),
            _buildModeTile(
              context,
              icon: Icons.replay_circle_filled_rounded,
              color: AppColors.error,
              title: 'Làm lại các câu đã làm sai',
              subtitle: 'Hệ thống tự động lưu các câu bạn từng chọn sai để ôn lại cho đến khi thuộc',
              onTap: () => _startQuiz(context, grade: 0, mode: QuizMode.wrongReview),
            ),

            const SizedBox(height: 28),
            // Grade Filter
            Text('Lọc câu hỏi theo Khối lớp',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildGradeCard(
                    context,
                    gradeNumber: 8,
                    title: 'Khối 8',
                    desc: 'Toán, Tin & Khoa học THCS',
                    onTap: () => _startQuiz(context, grade: 8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildGradeCard(
                    context,
                    gradeNumber: 11,
                    title: 'Khối 11',
                    desc: 'Python, Lượng giác & Lý',
                    onTap: () => _startQuiz(context, grade: 11),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildGradeCard(
                    context,
                    gradeNumber: 12,
                    title: 'Khối 12',
                    desc: 'Cơ sở dữ liệu & Giải tích',
                    onTap: () => _startQuiz(context, grade: 12),
                  ),
                ),
              ],
            ),
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
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
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

  Widget _buildGradeCard(
    BuildContext context, {
    required int gradeNumber,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Column(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text('$gradeNumber',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(desc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight)),
            ],
          ),
        ),
      ),
    );
  }
}
