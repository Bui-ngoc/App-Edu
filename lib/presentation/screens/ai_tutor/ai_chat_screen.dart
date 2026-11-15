import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/ai_tutor_provider.dart';
import '../../providers/profile_provider.dart';

class AiChatScreen extends StatefulWidget {
  final String? initialPrompt;
  const AiChatScreen({super.key, this.initialPrompt});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      _textController.text = widget.initialPrompt!;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? quickText]) {
    final text = quickText ?? _textController.text;
    if (text.trim().isEmpty) return;
    _textController.clear();
    context.read<AiTutorProvider>().sendMessage(text);
    _scrollToBottom();
  }

  void _showAiConfigModal() {
    final prof = context.read<ProfileProvider>();
    final keyCtrl = TextEditingController(text: prof.apiKey);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final hasKey = prof.apiKey.isNotEmpty;
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.tune_rounded, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Cấu hình Trợ lý AI Tutor',
                        style: Theme.of(ctx)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Status card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: hasKey
                          ? AppColors.success.withAlpha(25)
                          : AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: hasKey
                            ? AppColors.success.withAlpha(80)
                            : AppColors.primary.withAlpha(80),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          hasKey ? Icons.cloud_done_rounded : Icons.psychology_rounded,
                          color: hasKey ? AppColors.success : AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasKey
                                    ? 'Chế độ Trực tuyến: Google Gemini 1.5 Flash'
                                    : 'Chế độ Thông minh: AI Ngoại tuyến Chuyên sâu',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                hasKey
                                    ? 'Đang kết nối API Gemini trực tiếp.'
                                    : 'Tự động giải đáp so sánh, thuật toán, toán học không cần mạng.',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Gemini Key TextField
                  TextField(
                    controller: keyCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Google Gemini API Key',
                      hintText: 'Dán khóa AIzaSy... vào đây',
                      prefixIcon: Icon(Icons.key_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '💡 Lấy khóa miễn phí trong 1 phút tại Google AI Studio (aistudio.google.com). Nếu để trống, app sẽ dùng Bộ não AI Thông minh Ngoại tuyến.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Lưu cấu hình AI'),
                      onPressed: () {
                        prof.saveApiKey(keyCtrl.text);
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã cập nhật cấu hình AI Tutor!')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final aiProv = context.watch<AiTutorProvider>();
    final prof = context.watch<ProfileProvider>();
    final hasKey = prof.apiKey.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, color: AppColors.accent, size: 20),
                SizedBox(width: 6),
                Text('EduMaster AI Tutor', style: TextStyle(fontSize: 16)),
              ],
            ),
            Text(
              hasKey ? 'Gemini 1.5 Flash • Online' : 'AI Thông minh • Offline',
              style: TextStyle(
                fontSize: 11,
                color: hasKey ? AppColors.success : AppColors.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Cài đặt AI',
            onPressed: _showAiConfigModal,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới hội thoại',
            onPressed: () => aiProv.clearHistory(),
          )
        ],
      ),
      body: Column(
        children: [
          // Quick suggestions chips
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildQuickChip('Phân biệt List và Tuple'),
                _buildQuickChip('Thuật toán SM-2 là gì?'),
                _buildQuickChip('So sánh final và const'),
                _buildQuickChip('Clean Architecture trong Flutter'),
                _buildQuickChip('Tính điểm thi: đúng 16/20 câu'),
                _buildQuickChip('Cách dùng SQLite FTS'),
              ],
            ),
          ),
          const Divider(height: 1),
          // Chat messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: aiProv.messages.length,
              itemBuilder: (context, index) {
                final msg = aiProv.messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),
          if (aiProv.isGenerating)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'AI Tutor đang phân tích & tổng hợp câu trả lời...',
                    style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                  ),
                ],
              ),
            ),
          // Input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              border: const Border(top: BorderSide(color: AppColors.borderLight)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Hỏi AI bất kỳ điều gì...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.backgroundDark
                            : AppColors.backgroundLight,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: aiProv.isGenerating ? null : () => _sendMessage(),
                      child: const Icon(Icons.send_rounded, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onPressed: () => _sendMessage(label),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isMe = msg.isUser;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.88),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.primary
              : (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.surfaceDark
                  : Colors.grey.shade100),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isMe ? null : Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.smart_toy_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    const Text(
                      'EduMaster AI Tutor',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const Spacer(),
                    // Copy to clipboard button
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: msg.text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã sao chép câu trả lời vào bộ nhớ tạm!'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: const Icon(Icons.copy_rounded, size: 14, color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
            SelectableText(
              msg.text,
              style: TextStyle(
                color: isMe ? Colors.white : null,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
