import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/exam_provider.dart';
import 'exam_result_screen.dart';

class ExamRoomScreen extends StatelessWidget {
  const ExamRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ExamProvider>();

    if (prov.state == ExamUiState.finished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ExamResultScreen()),
        );
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (prov.activeRoom == null || prov.shuffledQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Phòng thi')),
        body: const Center(child: Text('Chưa có câu hỏi thi trong phòng này.')),
      );
    }

    final room = prov.activeRoom!;
    final questions = prov.shuffledQuestions;
    final currentIndex = prov.currentIndex;
    final currentQ = questions[currentIndex];
    final selectedOption = prov.answers[currentIndex];

    final minutes = prov.secondsLeft ~/ 60;
    final seconds = prov.secondsLeft % 60;
    final timerString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return WillPopScope(
      onWillPop: () async {
        final exit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Rời phòng thi?'),
            content: const Text('Nếu thoát ngay bây giờ, bài thi của bạn sẽ được tự động nộp với điểm hiện tại.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Tiếp tục làm bài')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Nộp bài và Thoát'),
              ),
            ],
          ),
        );
        if (exit == true) {
          await prov.submitExam();
          return true;
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            room.title,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          automaticallyImplyLeading: false,
          actions: [
            // Countdown timer chip
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: prov.secondsLeft < 180 ? AppColors.error : AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    timerString,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Anti-cheat alert banner if student left the app
              if (prov.cheatWarningShown)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: AppColors.error,
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.white),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Cảnh báo gian lận: Bạn vừa rời khỏi ứng dụng! (Số lần: ${prov.appSwitchCount})',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 18),
                        onPressed: () => prov.dismissCheatWarning(),
                      ),
                    ],
                  ),
                ),

              // Progress bar
              LinearProgressIndicator(
                value: (currentIndex + 1) / questions.length,
                minHeight: 4,
              ),

              // Question body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Câu ${currentIndex + 1} / ${questions.length}',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Spacer(),
                          if (prov.appSwitchCount > 0)
                            Text(
                              'Cảnh báo vi phạm: ${prov.appSwitchCount}',
                              style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        currentQ.questionVi,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                            ),
                      ),
                      const SizedBox(height: 20),

                      // Options
                      ...List.generate(currentQ.optionsVi.length, (optIdx) {
                        final isSelected = selectedOption == optIdx;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: InkWell(
                            onTap: () => prov.selectAnswer(optIdx),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 48),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.borderLight,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: isSelected ? AppColors.primary : Colors.grey.shade200,
                                    foregroundColor: isSelected ? Colors.white : Colors.black87,
                                    child: Text(
                                      String.fromCharCode(65 + optIdx),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      currentQ.optionsVi[optIdx],
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Bottom Question Selector & Submit
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  border: const Border(top: BorderSide(color: AppColors.borderLight)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Question jump pills
                    SizedBox(
                      height: 38,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: questions.length,
                        itemBuilder: (context, idx) {
                          final isAnswered = prov.answers.containsKey(idx);
                          final isCurrent = idx == currentIndex;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: ChoiceChip(
                              label: Text('${idx + 1}', style: const TextStyle(fontSize: 12)),
                              selected: isCurrent,
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: isCurrent
                                    ? Colors.white
                                    : (isAnswered ? AppColors.primary : Colors.black87),
                                fontWeight: FontWeight.bold,
                              ),
                              avatar: isAnswered && !isCurrent
                                  ? const Icon(Icons.check, size: 14, color: AppColors.primary)
                                  : null,
                              onSelected: (_) => prov.goToQuestion(idx),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Flexible(
                          child: OutlinedButton(
                            onPressed: currentIndex > 0 ? () => prov.goToQuestion(currentIndex - 1) : null,
                            child: const Text('← Trước', overflow: TextOverflow.ellipsis),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: OutlinedButton(
                            onPressed: currentIndex < questions.length - 1
                                ? () => prov.goToQuestion(currentIndex + 1)
                                : null,
                            child: const Text('Sau →', overflow: TextOverflow.ellipsis),
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Nộp bài thi?'),
                                content: Text(
                                  'Bạn đã trả lời ${prov.answers.length}/${questions.length} câu.\nBạn có chắc chắn muốn nộp bài ngay?',
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Làm tiếp')),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      prov.submitExam();
                                    },
                                    child: const Text('Nộp bài'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: const Text('Nộp bài'),
                        ),
                      ],
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
}
