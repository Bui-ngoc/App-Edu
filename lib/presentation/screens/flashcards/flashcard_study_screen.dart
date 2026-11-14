import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/state_views.dart';
import '../../providers/flashcard_provider.dart';
import '../../providers/dictionary_provider.dart';

class FlashcardStudyScreen extends StatefulWidget {
  const FlashcardStudyScreen({super.key});

  @override
  State<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends State<FlashcardStudyScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _flip() {
    final prov = context.read<FlashcardProvider>();
    if (prov.isCardFlipped) {
      _animController.reverse();
    } else {
      _animController.forward();
    }
    prov.flipCard();
  }

  void _onRate(int quality) {
    _animController.reset();
    context.read<FlashcardProvider>().submitSM2Rating(quality);
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<FlashcardProvider>();

    if (prov.state == FlashcardUiState.loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ôn tập thẻ')),
        body: const LoadingView(message: 'Đang tải thẻ học...'),
      );
    }

    if (prov.studyQueue.isEmpty || prov.currentStudyIndex >= prov.studyQueue.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hoàn thành')),
        body: EmptyStateView(
          title: '🎉 Hoàn thành phiên ôn tập hôm nay!',
          message: 'Tất cả các thẻ trong bộ đã được tính toán lịch ôn tập ngắt quãng SuperMemo SM-2 tối ưu.',
          icon: Icons.check_circle_outline_rounded,
          actionLabel: 'Quay về danh sách bộ thẻ',
          onAction: () => Navigator.of(context).pop(),
          onBack: () => Navigator.of(context).pop(),
        ),
      );
    }

    final card = prov.studyQueue[prov.currentStudyIndex];
    final total = prov.studyQueue.length;
    final current = prov.currentStudyIndex + 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('Ôn thẻ ($current/$total)'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Progress
              LinearProgressIndicator(
                value: current / total,
                minHeight: 6,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 16),
              // Card container with 3D Flip Animation
              Expanded(
                child: GestureDetector(
                  onTap: _flip,
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      final angle = _animation.value * pi;
                      final isUnder = angle > (pi / 2);

                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001) // 3D perspective
                          ..rotateY(angle),
                        child: isUnder
                            ? Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()..rotateY(pi),
                                child: _buildCardBack(card),
                              )
                            : _buildCardFront(card),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Hint to tap
              Text(
                prov.isCardFlipped ? 'Đánh giá mức độ ghi nhớ của bạn:' : 'Chạm vào thẻ để lật xem đáp án ↻',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 12),
              // SM-2 Rating Buttons (0 to 5)
              if (prov.isCardFlipped)
                Row(
                  children: [
                    Expanded(
                      child: _buildRateButton(
                        label: 'Quên hẳn\n(0 điểm)',
                        color: AppColors.error,
                        onTap: () => _onRate(0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildRateButton(
                        label: 'Khó khăn\n(3 điểm)',
                        color: AppColors.warning,
                        onTap: () => _onRate(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildRateButton(
                        label: 'Nhớ tốt\n(4 điểm)',
                        color: AppColors.primary,
                        onTap: () => _onRate(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildRateButton(
                        label: 'Hoàn hảo\n(5 điểm)',
                        color: AppColors.success,
                        onTap: () => _onRate(5),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _flip,
                    icon: const Icon(Icons.flip_rounded, size: 20),
                    label: const Text('Lật thẻ kiểm tra'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardFront(dynamic card) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).cardTheme.color ?? Colors.white,
              AppColors.primary.withOpacity(0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'MẶT TRƯỚC (CÂU HỎI / THUẬT NGỮ)',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
            const Spacer(),
            Text(
              card.front,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            if (card.phonetic != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    card.phonetic!,
                    style: const TextStyle(fontSize: 16, color: AppColors.textSecondaryLight, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 22),
                    onPressed: () => context.read<DictionaryProvider>().speakWord(card.front),
                    tooltip: 'Phát âm giọng đọc TTS',
                  ),
                ],
              ),
            ],
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.touch_app_outlined, size: 16, color: AppColors.textSecondaryLight),
                const SizedBox(width: 4),
                Text(
                  'EF: ${card.sm2.easeFactor} • Ôn lần ${card.sm2.repetition}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCardBack(dynamic card) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).cardTheme.color ?? Colors.white,
              AppColors.secondary.withOpacity(0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'MẶT SAU (ĐÁP ÁN / GIẢI THÍCH)',
                style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
            const Spacer(),
            Text(
              card.back,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, height: 1.5, fontWeight: FontWeight.w500),
            ),
            if (card.example != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Ví dụ: ${card.example!}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.textSecondaryLight),
                ),
              ),
            ],
            const Spacer(),
            const Text(
              'Thuật toán SM-2 sẽ tự động xếp lịch lặp lại ngắt quãng tiếp theo',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 52, // >= 48dp touch target
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.12),
          foregroundColor: color,
          elevation: 0,
          side: BorderSide(color: color.withOpacity(0.4)),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: onTap,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
