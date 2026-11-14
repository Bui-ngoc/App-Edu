import 'package:flutter/foundation.dart';
import '../../domain/repositories/interfaces.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AiTutorProvider extends ChangeNotifier {
  final IAiTutorRepository _aiRepo;

  AiTutorProvider({required IAiTutorRepository aiRepo}) : _aiRepo = aiRepo {
    _messages.add(
      ChatMessage(
        text: '👋 Xin chào bạn! Mình là Trợ lý Gia sư AI EduMaster. Bạn có thắc mắc gì về thuật ngữ CNTT, thuật toán SM-2, toán học hay trắc nghiệm tiếng Anh không? Hãy hỏi mình nhé!',
        isUser: false,
      ),
    );
  }

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  Future<void> sendMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty || _isGenerating) return;

    _messages.add(ChatMessage(text: clean, isUser: true));
    _isGenerating = true;
    notifyListeners();

    try {
      final answer = await _aiRepo.askAi(clean);
      _messages.add(ChatMessage(text: answer, isUser: false));
    } catch (e) {
      _messages.add(
        ChatMessage(
          text: '⚠️ Không thể kết nối với AI ngay lúc này: ${e.toString()}',
          isUser: false,
        ),
      );
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  void clearHistory() {
    _messages.clear();
    _messages.add(
      ChatMessage(
        text: 'Cuộc trò chuyện đã được làm mới. Hãy đặt câu hỏi cho AI Tutor nhé!',
        isUser: false,
      ),
    );
    notifyListeners();
  }
}
