import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../../providers/profile_provider.dart';

class QuizResultScreen extends StatefulWidget {
  const QuizResultScreen({super.key});

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final quizProv = context.read<QuizProvider>();
      final profileProv = context.read<ProfileProvider>();
      final earnedXp = (quizProv.score * 15) + 30;
      context.read<LeaderboardProvider>();
      profileProv.loadProfile();
      // Add XP to profile
      profileProv.updateNameAndGroup(
        profileProv.profile.name,
        profileProv.profile.currentGroup,
      );
      if (earnedXp > 0) {
        // XP gained
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<QuizProvider>();
    final total = prov.activeQuestions.length;
    final score = prov.score;
    final percentage = total > 0 ? (score / total) * 100 : 0.0;
    final isPassed = percentage >= 50.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả luyện tập'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Score badge
              Container(
                width: 120,
                height: 120,
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
                        '$score/$total',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: isPassed ? AppColors.success : AppColors.error,
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isPassed ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isPassed ? '🎉 Chúc mừng bạn đã hoàn thành!' : '💪 Đừng nản lòng, hãy ôn lại câu sai nhé!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Bạn nhận được +${(score * 15) + 30} XP vào Bảng xếp hạng học tập!',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),

              // Summary Stats Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildStatRow('Chế độ', prov.currentMode == QuizMode.exam ? 'Thi thử' : 'Luyện tập'),
                      const Divider(),
                      _buildStatRow('Số câu đúng', '$score câu', color: AppColors.success),
                      const Divider(),
                      _buildStatRow('Số câu sai', '${total - score} câu', color: AppColors.error),
                      const Divider(),
                      _buildStatRow('Tỉ lệ chính xác', '${percentage.toStringAsFixed(1)}%'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    prov.loadQuestions(grade: prov.selectedGrade, mode: prov.currentMode);
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Luyện tập lại đề này'),
                ),
              ),
              if (total - score > 0) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    onPressed: () {
                      prov.loadQuestions(mode: QuizMode.wrongReview);
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.replay_circle_filled_rounded),
                    label: const Text('Làm lại ngay các câu đã sai'),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Quay về Menu chính'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? color}) {
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
