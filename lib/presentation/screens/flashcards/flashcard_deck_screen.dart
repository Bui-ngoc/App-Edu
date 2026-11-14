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
                  'Định dạng CSV mỗi dòng:\nfront,back,phonetic,example\n\nVí dụ:\nFlutter,UI Toolkit của Google,/ˈflʌt.ər/,Cross-platform framework',
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
                                const SizedBox(height: 16),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => _showCsvImportDialog(context, deck.id),
                                      icon: const Icon(Icons.upload_file_rounded, size: 18),
                                      label: const Text('Nhập CSV'),
                                    ),
                                    const Spacer(),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        await prov.selectDeck(deck);
                                        if (context.mounted) {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(builder: (_) => const FlashcardStudyScreen()),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
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
    );
  }
}
