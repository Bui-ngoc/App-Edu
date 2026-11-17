import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/state_views.dart';
import '../../providers/quiz_provider.dart';
import 'quiz_result_screen.dart';

class QuizPlayScreen extends StatefulWidget {
  const QuizPlayScreen({super.key});

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  bool _submitted = false;

  void _showQuestionPalette(BuildContext context, QuizProvider prov) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Bảng danh sách câu hỏi',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'Đã làm: ${prov.userAnswers.length}/${prov.activeQuestions.length}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.45,
                  ),
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: prov.activeQuestions.length,
                    itemBuilder: (context, idx) {
                      final isAnswered = prov.userAnswers.containsKey(idx);
                      final isCurrent = idx == prov.currentIndex;

                      Color bgColor = Colors.grey.shade100;
                      Color textColor = Colors.black87;
                      Border? border;

                      if (isAnswered) {
                        bgColor = AppColors.primary.withOpacity(0.18);
                        textColor = AppColors.primary;
                      }
                      if (isCurrent) {
                        border = Border.all(color: AppColors.primary, width: 2);
                      }

                      return InkWell(
                        onTap: () {
                          prov.jumpToQuestion(idx);
                          Navigator.of(ctx).pop();
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(10),
                            border: border,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${idx + 1}',
                            style: TextStyle(
                              fontWeight: isCurrent || isAnswered ? FontWeight.bold : FontWeight.normal,
                              color: textColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Đóng'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmSubmitExam(BuildContext context, QuizProvider prov) {
    final answered = prov.userAnswers.length;
    final total = prov.activeQuestions.length;
    final unAnswered = total - answered;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.assignment_turned_in_rounded, color: AppColors.success),
            SizedBox(width: 8),
            Text('Nộp bài thi?'),
          ],
        ),
        content: Text(
          unAnswered > 0
              ? 'Bạn đã hoàn thành $answered/$total câu (còn $unAnswered câu chưa chọn đáp án).\n\nBạn có chắc chắn muốn nộp bài ngay bây giờ?'
              : 'Bạn đã hoàn thành toàn bộ $total/$total câu hỏi!\n\nBạn có muốn nộp bài và xem kết quả chi tiết?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tiếp tục làm'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _submitAndNavigate(prov);
            },
            child: const Text('Nộp bài ngay'),
          ),
        ],
      ),
    );
  }

  void _submitAndNavigate(QuizProvider prov) {
    if (_submitted) return;
    _submitted = true;
    prov.calculateScore();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const QuizResultScreen()),
    );
  }

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

    // Auto-submit when time is up in Exam mode
    if (prov.currentMode == QuizMode.exam && prov.isTimeUp && !_submitted) {
      _submitted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.alarm_off_rounded, color: AppColors.error),
                SizedBox(width: 8),
                Text('Hết giờ làm bài!'),
              ],
            ),
            content: const Text(
              'Đã hết thời gian làm bài thi. Hệ thống đang tự động nộp bài và chấm điểm kết quả của bạn.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _submitAndNavigate(prov);
                },
                child: const Text('Xem kết quả'),
              ),
            ],
          ),
        );
      });
    }

    final question = prov.activeQuestions[prov.currentIndex];
    final isEn = prov.isEnglish;
    final questionText = isEn ? question.questionEn : question.questionVi;
    final options = isEn ? question.optionsEn : question.optionsVi;
    final selectedOption = prov.userAnswers[prov.currentIndex];
    final isAnswered = selectedOption != null;
    final isExamMode = prov.currentMode == QuizMode.exam;

    return WillPopScope(
      onWillPop: () async {
        if (isExamMode) {
          final exit = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Thoát bài thi?'),
              content: const Text('Nếu thoát bây giờ, kết quả thi sẽ được tính theo số câu bạn đã hoàn thành.'),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Làm tiếp')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Thoát & Nộp bài'),
                ),
              ],
            ),
          );
          if (exit == true) {
            _submitAndNavigate(prov);
            return true;
          }
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isExamMode
                ? 'Đề thi (${prov.currentIndex + 1}/${prov.activeQuestions.length})'
                : 'Câu ${prov.currentIndex + 1}/${prov.activeQuestions.length}',
          ),
          actions: [
            // Question Grid jump button
            IconButton(
              icon: const Icon(Icons.grid_view_rounded),
              tooltip: 'Bảng câu hỏi',
              onPressed: () => _showQuestionPalette(context, prov),
            ),
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
                    if (isExamMode) ...[
                      const SizedBox(width: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: prov.secondsRemaining < 180
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
                              color: prov.secondsRemaining < 180 ? AppColors.error : AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTimer(prov.secondsRemaining),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: prov.secondsRemaining < 180 ? AppColors.error : AppColors.primary,
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
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                question.category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.secondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          if (isExamMode) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Đã làm: ${prov.userAnswers.length}/${prov.activeQuestions.length}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                          ],
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

                        if (isExamMode) {
                          // In exam mode: only highlight selected, do not reveal right/wrong yet
                          if (isSelected) {
                            borderColor = AppColors.primary;
                            bgColor = AppColors.primary.withOpacity(0.12);
                            icon = Icons.check_circle_rounded;
                          }
                        } else {
                          // In practice mode: reveal immediately
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
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: InkWell(
                            // In exam mode, always allow changing answer
                            onTap: isExamMode
                                ? () => prov.selectAnswer(idx)
                                : (isAnswered ? null : () => prov.selectAnswer(idx)),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 48), // >= 48dp touch target
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: borderColor,
                                  width: isSelected || (!isExamMode && isAnswered && isCorrect) ? 2 : 1,
                                ),
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

                      // AI Explanation card (only in practice mode when wrong)
                      if (!isExamMode && isAnswered && selectedOption != question.correctIndex) ...[
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
                                  const Icon(Icons.lightbulb_rounded, color: AppColors.accent, size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Giải thích từ EduMaster',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const Spacer(),
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
                    const SizedBox(width: 8),
                    // Quick jump button
                    IconButton(
                      icon: const Icon(Icons.apps_rounded, color: AppColors.primary),
                      tooltip: 'Bảng câu hỏi',
                      onPressed: () => _showQuestionPalette(context, prov),
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
                        onPressed: () => _confirmSubmitExam(context, prov),
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: const Text('Nộp bài thi'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimer(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
