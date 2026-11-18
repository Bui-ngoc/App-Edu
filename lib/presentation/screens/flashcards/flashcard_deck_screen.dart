import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/state_views.dart';
import '../../providers/flashcard_provider.dart';
import 'flashcard_study_screen.dart';

class FlashcardDeckScreen extends StatefulWidget {
  const FlashcardDeckScreen({super.key});

  @override
  State<FlashcardDeckScreen> createState() => _FlashcardDeckScreenState();
}

class _FlashcardDeckScreenState extends State<FlashcardDeckScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FlashcardProvider>().loadDecks();
    });
  }

  void _showCsvImportDialog(BuildContext context, String deckId) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.file_upload_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Nhập thẻ từ CSV'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cú pháp mỗi dòng: front,back,phonetic,example\nVí dụ: Widget,UI element,/ˈwɪdʒ.ɪt/,Basic building block',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: textController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: 'Dán nội dung CSV vào đây...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                textController.dispose();
                Navigator.of(ctx).pop();
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final content = textController.text;
                textController.dispose();
                Navigator.of(ctx).pop();
                if (content.trim().isNotEmpty) {
                  final count = await context.read<FlashcardProvider>().importCsv(deckId, content);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã nhập thành công $count thẻ mới vào bộ thẻ!')),
                    );
                  }
                }
              },
              child: const Text('Nhập ngay'),
            ),
          ],
        );
      },
    );
  }

  void _showAddCardDialog(BuildContext context, String deckId) {
    final frontCtrl = TextEditingController();
    final backCtrl = TextEditingController();
    final phoneticCtrl = TextEditingController();
    final exampleCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.add_card_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Thêm thẻ ghi nhớ mới'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thẻ sẽ được lưu vĩnh viễn và áp dụng thuật toán lặp lại ngắt quãng SuperMemo SM-2.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: frontCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mặt trước (Từ vựng / Câu hỏi) *',
                    prefixIcon: Icon(Icons.help_outline_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: backCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Mặt sau (Định nghĩa / Đáp án) *',
                    prefixIcon: Icon(Icons.check_circle_outline_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneticCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Phiên âm (Tùy chọn, vd: /ˈwɪdʒ.ɪt/)',
                    prefixIcon: Icon(Icons.record_voice_over_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: exampleCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Ví dụ minh họa (Tùy chọn)',
                    prefixIcon: Icon(Icons.lightbulb_outline_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save_rounded, size: 16),
              label: const Text('Lưu thẻ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final front = frontCtrl.text.trim();
                final back = backCtrl.text.trim();
                if (front.isEmpty || back.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập đầy đủ mặt trước và mặt sau của thẻ!')),
                  );
                  return;
                }
                Navigator.of(ctx).pop();
                await context.read<FlashcardProvider>().addCard(
                  deckId: deckId,
                  front: front,
                  back: back,
                  phonetic: phoneticCtrl.text.trim(),
                  example: exampleCtrl.text.trim(),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã lưu thẻ "$front" thành công vào bộ nhớ máy!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showCreateDeckDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.style_rounded, color: AppColors.secondary),
              SizedBox(width: 8),
              Text('Tạo bộ thẻ mới'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên bộ thẻ học tập *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Mô tả ngắn gọn',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;
                Navigator.of(ctx).pop();
                await context.read<FlashcardProvider>().createDeck(title, descCtrl.text.trim());
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã tạo bộ thẻ "$title"!'), backgroundColor: AppColors.success),
                  );
                }
              },
              child: const Text('Tạo bộ thẻ'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<FlashcardProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thẻ ghi nhớ SM-2'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
            onPressed: () => prov.loadDecks(),
          ),
        ],
      ),
      body: prov.state == FlashcardUiState.loading
          ? const LoadingView(message: 'Đang tải các bộ thẻ...')
          : prov.state == FlashcardUiState.error
              ? ErrorViewWithRetry(
                  message: prov.errorMessage,
                  onRetry: () => prov.loadDecks(),
                )
              : prov.decks.isEmpty
                  ? EmptyStateView(
                      title: 'Chưa có bộ thẻ nào',
                      message: 'Nhấn vào nút bên dưới để tạo hoặc tải lại bộ thẻ mẫu.',
                      actionLabel: 'Tải lại',
                      onAction: () => prov.loadDecks(),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: prov.decks.length,
                      itemBuilder: (context, index) {
                        final deck = prov.decks[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondary.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.style_rounded, color: AppColors.secondary),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            deck.title,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            deck.description,
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '📚 ${prov.getDeckCardCount(deck.id)} thẻ ghi nhớ',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                      onPressed: () => _showAddCardDialog(context, deck.id),
                                      icon: const Icon(Icons.add_rounded, size: 16),
                                      label: const Text('Thêm thẻ'),
                                    ),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                      onPressed: () => _showCsvImportDialog(context, deck.id),
                                      icon: const Icon(Icons.upload_file_rounded, size: 16),
                                      label: const Text('Nhập CSV'),
                                    ),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      ),
                                      onPressed: () async {
                                        await prov.selectDeck(deck);
                                        if (context.mounted) {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(builder: (_) => const FlashcardStudyScreen()),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                                      label: const Text('Bắt đầu ôn tập'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tạo bộ thẻ'),
        onPressed: () => _showCreateDeckDialog(context),
      ),
    );
  }
}
