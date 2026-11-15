import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/quiz_provider.dart';
import 'quiz_play_screen.dart';

class MockExamSetupSheet extends StatefulWidget {
  const MockExamSetupSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MockExamSetupSheet(),
    );
  }

  @override
  State<MockExamSetupSheet> createState() => _MockExamSetupSheetState();
}

class _MockExamSetupSheetState extends State<MockExamSetupSheet> {
  int _selectedGrade = 0; // 0 = All
  String _selectedDifficulty = 'all'; // 'all', 'easy', 'medium', 'hard'
  int _selectedQuestionCount = 50; // Standard 50 questions
  int _selectedDurationMinutes = 60; // Standard 60 minutes
  final TextEditingController _customDurationController = TextEditingController();
  bool _isCustomDuration = false;

  final Map<int, String> _gradeLabels = {
    0: 'Tất cả các khối (Tổng hợp 300 câu)',
    1: 'Khối 1: Ngôn ngữ Dart',
    2: 'Khối 2: Môi trường & Công cụ',
    3: 'Khối 3: Cách Flutter hoạt động',
    4: 'Khối 4: Bố cục & Cuộn',
    5: 'Khối 5: Thiết kế & Theme',
    6: 'Khối 6: Thích ứng Responsive',
    7: 'Khối 7: Tương tác & Biểu mẫu',
    8: 'Khối 8: Tài nguyên & Đa phương tiện',
    9: 'Khối 9: Điều hướng (Navigation)',
    10: 'Khối 10: Hoạt ảnh (Animations)',
    11: 'Khối 11: Trợ năng & Đa ngôn ngữ',
    12: 'Khối 12: Quản lý trạng thái',
    13: 'Khối 13: Dữ liệu & SQLite Backend',
    14: 'Khối 14: Kiến trúc Clean Architecture',
    15: 'Khối 15: Gói & Plugin',
    16: 'Khối 16: Kiểm thử & Gỡ lỗi',
    17: 'Khối 17: Hiệu năng (Performance)',
    18: 'Khối 18: Tích hợp nền tảng',
    19: 'Khối 19: Triển khai (Deployment)',
    20: 'Khối 20: AI trong Flutter',
  };

  @override
  void dispose() {
    _customDurationController.dispose();
    super.dispose();
  }

  void _startExam() {
    int duration = _selectedDurationMinutes;
    if (_isCustomDuration) {
      final custom = int.tryParse(_customDurationController.text.trim());
      if (custom != null && custom > 0) {
        duration = custom;
      }
    }

    final quizProv = context.read<QuizProvider>();
    quizProv.startTimedExam(
      grade: _selectedGrade,
      difficulty: _selectedDifficulty,
      questionCount: _selectedQuestionCount,
      durationMinutes: duration,
    );

    Navigator.of(context).pop(); // Close sheet
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QuizPlayScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.timer_rounded, color: AppColors.warning, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thiết lập Kỳ thi thử tính giờ',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Chuẩn 50 câu / 60 phút • Bộ lọc linh hoạt',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable options
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. KHỐI THI ──────────────────────────────────────────
                  _buildSectionTitle(Icons.school_rounded, 'Khối thi (Chủ đề kiến thức)'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderLight),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedGrade,
                        isExpanded: true,
                        items: _gradeLabels.entries.map((e) {
                          return DropdownMenuItem<int>(
                            value: e.key,
                            child: Text(
                              e.value,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: e.key == 0 ? FontWeight.bold : FontWeight.normal,
                                color: e.key == 0 ? AppColors.primary : null,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedGrade = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ── 2. MỨC ĐỘ ──────────────────────────────────────────
                  _buildSectionTitle(Icons.analytics_outlined, 'Mức độ câu hỏi'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildDifficultyChip('all', '🌟 Tất cả mức độ'),
                      _buildDifficultyChip('easy', '🟢 Cơ bản (Dễ)'),
                      _buildDifficultyChip('medium', '🟡 Thông hiểu (Vừa)'),
                      _buildDifficultyChip('hard', '🔴 Vận dụng cao (Khó)'),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // ── 3. SỐ LƯỢNG CÂU HỎI ────────────────────────────────
                  _buildSectionTitle(Icons.format_list_numbered_rounded, 'Số lượng câu hỏi (Chuẩn: 50 câu)'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildCountChip(50, '50 câu (Chuẩn ⭐)'),
                      _buildCountChip(40, '40 câu'),
                      _buildCountChip(30, '30 câu'),
                      _buildCountChip(20, '20 câu'),
                      _buildCountChip(10, '10 câu (Nhanh)'),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // ── 4. THỜI GIAN LÀM BÀI ───────────────────────────────
                  _buildSectionTitle(Icons.hourglass_bottom_rounded, 'Thời gian làm bài (Chuẩn: 60 phút)'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildDurationChip(60, '60 phút (Chuẩn ⭐)'),
                      _buildDurationChip(45, '45 phút'),
                      _buildDurationChip(30, '30 phút'),
                      _buildDurationChip(20, '20 phút'),
                      _buildDurationChip(15, '15 phút'),
                      _buildCustomDurationChip(),
                    ],
                  ),
                  if (_isCustomDuration) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: _customDurationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Nhập số phút tùy chọn',
                        hintText: 'Ví dụ: 10, 50, 90...',
                        prefixIcon: Icon(Icons.edit_calendar_rounded),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // ── 5. TÓM TẮT ĐỀ THI ──────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.08),
                          AppColors.secondary.withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Thông số bài thi của bạn',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '• Số câu: $_selectedQuestionCount câu hỏi trắc nghiệm khách quan\n'
                          '• Thời gian: ${_isCustomDuration ? (_customDurationController.text.isNotEmpty ? _customDurationController.text : '60') : _selectedDurationMinutes} phút\n'
                          '• Khối thi: ${_gradeLabels[_selectedGrade]}\n'
                          '• Mức độ: ${_getDifficultyLabel(_selectedDifficulty)}\n'
                          '• Chế độ: Đồng hồ đếm ngược, tự động nộp bài khi hết giờ',
                          style: const TextStyle(fontSize: 13, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              border: const Border(top: BorderSide(color: AppColors.borderLight)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 24),
                label: const Text(
                  'BẮT ĐẦU LÀM BÀI THI',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                onPressed: _startExam,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildDifficultyChip(String value, String label) {
    final isSelected = _selectedDifficulty == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: AppColors.primary.withOpacity(0.18),
      onSelected: (selected) {
        if (selected) setState(() => _selectedDifficulty = value);
      },
    );
  }

  Widget _buildCountChip(int count, String label) {
    final isSelected = _selectedQuestionCount == count;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: AppColors.primary.withOpacity(0.18),
      onSelected: (selected) {
        if (selected) setState(() => _selectedQuestionCount = count);
      },
    );
  }

  Widget _buildDurationChip(int minutes, String label) {
    final isSelected = !_isCustomDuration && _selectedDurationMinutes == minutes;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: AppColors.primary.withOpacity(0.18),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _isCustomDuration = false;
            _selectedDurationMinutes = minutes;
          });
        }
      },
    );
  }

  Widget _buildCustomDurationChip() {
    return ChoiceChip(
      label: Text(
        'Tùy chỉnh ⏱️',
        style: TextStyle(fontSize: 12, fontWeight: _isCustomDuration ? FontWeight.bold : FontWeight.normal),
      ),
      selected: _isCustomDuration,
      selectedColor: AppColors.secondary.withOpacity(0.18),
      onSelected: (selected) {
        if (selected) setState(() => _isCustomDuration = true);
      },
    );
  }

  String _getDifficultyLabel(String diff) {
    switch (diff) {
      case 'easy':
        return 'Cơ bản (Dễ)';
      case 'medium':
        return 'Thông hiểu (Vừa)';
      case 'hard':
        return 'Vận dụng cao (Khó)';
      default:
        return 'Tất cả mức độ (Đa dạng)';
    }
  }
}
