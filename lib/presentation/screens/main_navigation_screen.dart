import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/exam_provider.dart';
import 'quiz/quiz_hub_screen.dart';
import 'flashcards/flashcard_deck_screen.dart';
import 'online_exam/exam_hub_screen.dart';
import 'dictionary/dictionary_screen.dart';
import 'leaderboard/leaderboard_screen.dart';
import 'ai_tutor/ai_chat_screen.dart';
import 'scanner/qr_scanner_screen.dart';
import 'profile/profile_screen.dart';
import 'teacher/teacher_exam_history_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  Future<void> _handleQrScan(BuildContext context, bool isTeacher) async {
    final scannedCode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (scannedCode != null && scannedCode.isNotEmpty && context.mounted) {
      if (!isTeacher) {
        // If student scans QR, switch to Exam tab and join
        setState(() => _currentIndex = 2);
        await context.read<ExamProvider>().joinRoom(scannedCode);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mã QR phòng thi: $scannedCode')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final isTeacher = authProv.currentUser?.isTeacher ?? false;
    final profile = context.watch<ProfileProvider>().profile;

    final List<Widget> screens = isTeacher
        ? const [
            ExamHubScreen(),
            TeacherExamHistoryScreen(),
            LeaderboardScreen(),
          ]
        : const [
            QuizHubScreen(),
            FlashcardDeckScreen(),
            ExamHubScreen(),
            DictionaryScreen(),
            LeaderboardScreen(),
          ];

    final List<NavigationDestination> destinations = isTeacher
        ? const [
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment_rounded, color: AppColors.secondary),
              label: 'Tạo phòng thi',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_edu_outlined),
              selectedIcon: Icon(Icons.history_edu_rounded, color: AppColors.secondary),
              label: 'Lịch sử phòng thi',
            ),
            NavigationDestination(
              icon: Icon(Icons.leaderboard_outlined),
              selectedIcon: Icon(Icons.leaderboard_rounded, color: AppColors.secondary),
              label: 'Xếp hạng',
            ),
          ]
        : const [
            NavigationDestination(
              icon: Icon(Icons.quiz_outlined),
              selectedIcon: Icon(Icons.quiz_rounded, color: AppColors.primary),
              label: 'Trắc nghiệm',
            ),
            NavigationDestination(
              icon: Icon(Icons.style_outlined),
              selectedIcon: Icon(Icons.style_rounded, color: AppColors.primary),
              label: 'Flashcards',
            ),
            NavigationDestination(
              icon: Icon(Icons.timer_outlined),
              selectedIcon: Icon(Icons.timer_rounded, color: AppColors.primary),
              label: 'Phòng thi',
            ),
            NavigationDestination(
              icon: Icon(Icons.book_outlined),
              selectedIcon: Icon(Icons.book_rounded, color: AppColors.primary),
              label: 'Từ điển IT',
            ),
            NavigationDestination(
              icon: Icon(Icons.leaderboard_outlined),
              selectedIcon: Icon(Icons.leaderboard_rounded, color: AppColors.primary),
              label: 'Xếp hạng',
            ),
          ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isTeacher ? AppColors.secondary : AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isTeacher ? Icons.supervisor_account_rounded : Icons.school_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EduMaster',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  isTeacher ? 'Chế độ Giảng viên' : 'Chế độ Sinh viên',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isTeacher ? AppColors.secondary : AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // AI Tutor shortcut
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: AppColors.accent),
            tooltip: 'Gia sư AI 24/7',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AiChatScreen()),
              );
            },
          ),
          // QR Scanner shortcut
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Quét mã QR bằng Camera',
            onPressed: () => _handleQrScan(context, isTeacher),
          ),
          // Profile & Avatar shortcut
          Padding(
            padding: const EdgeInsets.only(right: 12.0, left: 4.0),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: (isTeacher ? AppColors.secondary : AppColors.primary).withOpacity(0.15),
                backgroundImage: (profile.localAvatarPath != null &&
                        File(profile.localAvatarPath!).existsSync())
                    ? FileImage(File(profile.localAvatarPath!))
                    : null,
                child: (profile.localAvatarPath == null ||
                        !File(profile.localAvatarPath!).existsSync())
                    ? Icon(
                        isTeacher ? Icons.supervisor_account_rounded : Icons.person,
                        size: 18,
                        color: isTeacher ? AppColors.secondary : AppColors.primary,
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex < screens.length ? _currentIndex : 0,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex < destinations.length ? _currentIndex : 0,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: destinations,
      ),
    );
  }
}
