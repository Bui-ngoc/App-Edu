import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/state_views.dart';
import '../../providers/dictionary_provider.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DictionaryProvider>().init();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showWordDetails(BuildContext context, dynamic word) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          word.word,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          word.phonetic,
                          style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 28),
                    onPressed: () => context.read<DictionaryProvider>().speakWord(word.word),
                    tooltip: 'Phát âm chuẩn tiếng Anh',
                  ),
                  IconButton(
                    icon: Icon(
                      word.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      color: word.isBookmarked ? AppColors.accent : null,
                      size: 28,
                    ),
                    onPressed: () {
                      context.read<DictionaryProvider>().toggleBookmark(word);
                      Navigator.of(ctx).pop();
                    },
                    tooltip: 'Lưu từ vựng yêu thích',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  word.vietnamese,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Định nghĩa:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text(word.definition, style: const TextStyle(fontSize: 14, height: 1.4)),
              const SizedBox(height: 14),
              const Text('Ví dụ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  word.example,
                  style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DictionaryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Từ điển thuật ngữ IT'),
        actions: [
          IconButton(
            icon: Icon(
              prov.showOnlyBookmarks ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
              color: prov.showOnlyBookmarks ? AppColors.accent : null,
            ),
            tooltip: 'Từ đã đánh dấu',
            onPressed: () => prov.toggleBookmarksFilter(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm thuật ngữ IT...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          prov.search('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) => prov.search(val),
            ),
          ),

          // Word of the Day Banner
          if (prov.wordOfTheDay != null && !prov.showOnlyBookmarks && _searchController.text.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Card(
                color: AppColors.primary.withOpacity(0.06),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.primary,
                        radius: 18,
                        child: Icon(Icons.lightbulb_outline_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TỪ CỦA NGÀY',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                            Text(
                              '${prov.wordOfTheDay!.word} - ${prov.wordOfTheDay!.vietnamese}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 20),
                        onPressed: () => prov.speakWord(prov.wordOfTheDay!.word),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Word list or States
          Expanded(
            child: prov.state == DictUiState.loading
                ? const LoadingView(message: 'Đang tra cứu từ điển SQLite...')
                : prov.state == DictUiState.error
                    ? ErrorViewWithRetry(
                        message: prov.errorMessage,
                        onRetry: () => prov.search(_searchController.text),
                      )
                    : prov.state == DictUiState.empty || prov.words.isEmpty
                        ? EmptyStateView(
                            title: prov.showOnlyBookmarks
                                ? 'Chưa có từ nào được đánh dấu'
                                : 'Không tìm thấy thuật ngữ phù hợp',
                            message: prov.showOnlyBookmarks
                                ? 'Hãy chạm vào biểu tượng Bookmark trên từ điển để lưu lại từ cần nhớ.'
                                : 'Thử tìm với từ khóa khác hoặc tra cứu bằng tiếng Việt.',
                            icon: Icons.search_off_rounded,
                            actionLabel: prov.showOnlyBookmarks ? 'Xem tất cả từ' : 'Xóa tìm kiếm',
                            onAction: () {
                              if (prov.showOnlyBookmarks) {
                                prov.toggleBookmarksFilter();
                              } else {
                                _searchController.clear();
                                prov.search('');
                              }
                            },
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: prov.words.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final word = prov.words[index];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                title: Row(
                                  children: [
                                    Text(
                                      word.word,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      word.phonetic,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  '${word.vietnamese} • ${word.definition}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.volume_up_outlined, size: 20),
                                      onPressed: () => prov.speakWord(word.word),
                                      tooltip: 'Phát âm TTS',
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        word.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                        color: word.isBookmarked ? AppColors.accent : null,
                                        size: 20,
                                      ),
                                      onPressed: () => prov.toggleBookmark(word),
                                      tooltip: 'Đánh dấu',
                                    ),
                                  ],
                                ),
                                onTap: () => _showWordDetails(context, word),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
