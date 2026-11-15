import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/quiz_question.dart';

class CreateCustomQuestionDialog extends StatefulWidget {
  final int nextId;

  const CreateCustomQuestionDialog({super.key, required this.nextId});

  static Future<QuizQuestion?> show(BuildContext context, int nextId) {
    return showDialog<QuizQuestion>(
      context: context,
      builder: (_) => CreateCustomQuestionDialog(nextId: nextId),
    );
  }

  @override
  State<CreateCustomQuestionDialog> createState() => _CreateCustomQuestionDialogState();
}

class _CreateCustomQuestionDialogState extends State<CreateCustomQuestionDialog> {
  final _questionController = TextEditingController();
  final _optAController = TextEditingController();
  final _optBController = TextEditingController();
  final _optCController = TextEditingController();
  final _optDController = TextEditingController();
  final _explanationController = TextEditingController();
  int _correctIndex = 0; // 0=A, 1=B, 2=C, 3=D
  final int _selectedGrade = 12;

  @override
  void dispose() {
    _questionController.dispose();
    _optAController.dispose();
    _optBController.dispose();
    _optCController.dispose();
    _optDController.dispose();
    _explanationController.dispose();
    super.dispose();
  }

  void _saveQuestion() {
    final qText = _questionController.text.trim();
    final a = _optAController.text.trim();
    final b = _optBController.text.trim();
    final c = _optCController.text.trim();
    final d = _optDController.text.trim();
    final exp = _explanationController.text.trim();

    if (qText.isEmpty || a.isEmpty || b.isEmpty || c.isEmpty || d.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ nội dung câu hỏi và 4 phương án!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final newQuestion = QuizQuestion(
      id: widget.nextId,
      grade: _selectedGrade,
      category: 'Giảng viên tự soạn',
      questionVi: qText,
      questionEn: qText,
      optionsVi: [a, b, c, d],
      optionsEn: [a, b, c, d],
      correctIndex: _correctIndex,
      explanationVi: exp.isNotEmpty ? exp : 'Đáp án chính xác do giảng viên chỉ định.',
      explanationEn: exp.isNotEmpty ? exp : 'Correct answer specified by instructor.',
    );

    Navigator.of(context).pop(newQuestion);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.edit_note_rounded, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Soạn câu hỏi mới', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _questionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Nội dung câu hỏi',
                  hintText: 'Nhập câu hỏi trắc nghiệm...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('4 Phương án trả lời:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              _buildOptionRow('A', _optAController, 0),
              const SizedBox(height: 8),
              _buildOptionRow('B', _optBController, 1),
              const SizedBox(height: 8),
              _buildOptionRow('C', _optCController, 2),
              const SizedBox(height: 8),
              _buildOptionRow('D', _optDController, 3),
              const SizedBox(height: 12),
              TextField(
                controller: _explanationController,
                decoration: const InputDecoration(
                  labelText: 'Lời giải thích chi tiết (Tùy chọn)',
                  hintText: 'Nhập giải thích vì sao đáp án này đúng...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy bỏ'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          onPressed: _saveQuestion,
          child: const Text('Thêm vào đề thi'),
        ),
      ],
    );
  }

  Widget _buildOptionRow(String letter, TextEditingController controller, int index) {
    final isCorrect = _correctIndex == index;

    return Row(
      children: [
        InkWell(
          onTap: () => setState(() => _correctIndex = index),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCorrect ? AppColors.success : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              letter,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isCorrect ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Phương án $letter',
              isDense: true,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            isCorrect ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: isCorrect ? AppColors.success : Colors.grey,
            size: 20,
          ),
          tooltip: 'Chọn làm đáp án đúng',
          onPressed: () => setState(() => _correctIndex = index),
        ),
      ],
    );
  }
}
