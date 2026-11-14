import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/state_views.dart';
import '../../providers/quiz_provider.dart';
import 'quiz_result_screen.dart';

class QuizPlayScreen extends StatelessWidget {
  const QuizPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<QuizProvider>();

    if (prov.state == QuizUiState.loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Đang tải câu hỏi')),
        body: const LoadingView(message: 'Đang nạp bộ dữ liệu câu hỏi song ngữ...'),
      );
    }

    if (prov.state == QuizUiState.error) {
      return Scaffold(
        appBar: AppBar(title: const Text('Có lỗi')),
        body: ErrorViewWithRetry(
          message: prov.errorMessage,
          onRetry: () => prov.loadQuestions(grade: prov.selectedGrade, mode: prov.currentMode),
          onBack: () => Navigator.of(context).pop(),
        ),
      );
    }

    if (prov.state == QuizUiState.empty || prov.activeQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chưa có câu hỏi')),
        body: EmptyStateView(
          title: prov.currentMode == QuizMode.wrongReview
              ? 'Tuyệt vời! Bạn không có câu hỏi nào bị sai.'
              : 'Không tìm thấy câu hỏi phù hợp với bộ lọc.',
          message: prov.currentMode == QuizMode.wrongReview
              ? 'Hãy tiếp tục làm thêm các đề thi thử để nâng cao kỹ năng nhé!'
              : 'Vui lòng chọn một khối lớp khác hoặc chế độ khác.',
          icon: Icons.check_circle_outline_rounded,
          actionLabel: 'Quay về trang chủ ôn tập',
          onAction: () => Navigator.of(context).pop(),
          onBack: () => Navigator.of(context).pop(),
        ),
      );
    }

    final question = prov.activeQuestions[prov.currentIndex];
    final isEn = prov.isEnglish;
    final questionText = isEn ? question.questionEn : question.questionVi;
    final options = isEn ? question.optionsEn : question.optionsVi;
    final selectedOption = prov.userAnswers[prov.currentIndex];
    final isAnswered = selectedOption != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          prov.currentMode == QuizMode.exam
              ? 'Thi thử (${prov.currentIndex + 1}/${prov.activeQuestions.length})'
              : 'Câu ${prov.currentIndex + 1}/${prov.activeQuestions.length}',
        ),
        actions: [
          // Bilingual toggle (VI / EN)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              avatar: const Icon(Icons.translate_rounded, size: 16),
              label: Text(
                isEn ? 'English' : 'Tiếng Việt',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              onPressed: () => prov.toggleLanguage(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Timer & Progress header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).cardTheme.color,
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (prov.currentIndex + 1) / prov.activeQuestions.length,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(4),
                      backgroundColor: Colors.grey.shade300,
                    ),
                  ),
                  if (prov.currentMode == QuizMode.exam) ...[
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: prov.secondsRemaining < 120
                            ? AppColors.error.withOpacity(0.15)
                            : AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: prov.secondsRemaining < 120 ? AppColors.error : AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTimer(prov.secondsRemaining),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: prov.secondsRemaining < 120 ? AppColors.error : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Question body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category & Grade tag
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            question.category,
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Khối ${question.grade}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Question text
                    Text(
                      questionText,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 20),
                    // Options list
                    ...List.generate(options.length, (idx) {
                      final isSelected = selectedOption == idx;
                      final isCorrect = question.correctIndex == idx;

                      Color borderColor = AppColors.borderLight;
                      Color bgColor = Colors.transparent;
                      IconData? icon;

                      if (isAnswered) {
                        if (isCorrect) {
                          borderColor = AppColors.success;
                          bgColor = AppColors.success.withOpacity(0.1);
                          icon = Icons.check_circle_rounded;
                        } else if (isSelected) {
                          borderColor = AppColors.error;
                          bgColor = AppColors.error.withOpacity(0.1);
                          icon = Icons.cancel_rounded;
                        }
                      } else if (isSelected) {
                        borderColor = AppColors.primary;
                        bgColor = AppColors.primary.withOpacity(0.08);
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: InkWell(
                          onTap: isAnswered ? null : () => prov.selectAnswer(idx),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 48), // >= 48dp touch target
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor, width: isSelected || (isAnswered && isCorrect) ? 2 : 1),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: borderColor.withOpacity(0.2),
                                  child: Text(
                                    String.fromCharCode(65 + idx),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: borderColor == AppColors.borderLight ? AppColors.primary : borderColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    options[idx],
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                if (icon != null) ...[
                                  const SizedBox(width: 8),
                                  Icon(icon, color: borderColor, size: 20),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    // AI Explanation card if wrong answer chosen
                    if (isAnswered && selectedOption != question.correctIndex) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.accent.withOpacity(0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.auto_awesome, color: AppColors.accent, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Gia sư AI giải thích lý do sai',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const Spacer(),
                                if (prov.aiExplanation.isEmpty)
                                  TextButton.icon(
                                    onPressed: prov.isExplaining ? null : () => prov.requestAiExplanation(),
                                    icon: prov.isExplaining
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.psychology_alt_rounded, size: 18),
                                    label: Text(prov.isExplaining ? 'Đang hỏi...' : 'Xem AI giải thích'),
                                  ),
                              ],
                            ),
                            if (prov.aiExplanation.isNotEmpty) ...[
                              const Divider(height: 16),
                              Text(
                                prov.aiExplanation,
                                style: const TextStyle(fontSize: 13, height: 1.4),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Navigation controls (Bottom Bar)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                border: const Border(top: BorderSide(color: AppColors.borderLight)),
              ),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: prov.currentIndex > 0 ? () => prov.previousQuestion() : null,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Trước'),
                  ),
                  const Spacer(),
                  if (prov.currentIndex < prov.activeQuestions.length - 1)
                    ElevatedButton.icon(
                      onPressed: () => prov.nextQuestion(),
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Tiếp theo'),
                    )
                  else
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        prov.calculateScore();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const QuizResultScreen()),
                        );
                      },
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: const Text('Nộp bài & Hoàn thành'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
