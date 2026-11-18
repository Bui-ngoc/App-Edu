import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/profile_provider.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProv = context.watch<ProfileProvider>();
    final profile = profileProv.profile;
    final streakDays = profile.streakDays;
    final totalXp = profile.totalXp;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chuỗi ngày & Thành tích'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── STREAK HIGHLIGHT HERO CARD ──────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5722).withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: Colors.white,
                      size: 56,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$streakDays Ngày Chuỗi',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Duy trì thói quen học tập hằng ngày để giữ vững chuỗi Streak!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // WEEKDAY STREAK TRACKER DOTS (Calculated dynamically from user's streakDays)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildDayDot('T2', streakDays >= 1),
                      _buildDayDot('T3', streakDays >= 2),
                      _buildDayDot('T4', streakDays >= 3),
                      _buildDayDot('T5', streakDays >= 4),
                      _buildDayDot('T6', streakDays >= 5),
                      _buildDayDot('T7', streakDays >= 6),
                      _buildDayDot('CN', streakDays >= 7),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── PERSONAL STATS GRID ─────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.bolt_rounded, color: AppColors.accent, size: 22),
                              SizedBox(width: 6),
                              Text('Tích lũy XP', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '$totalXp XP',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          const SizedBox(height: 4),
                          const Text('Điểm thưởng học tập', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.military_tech_rounded, color: AppColors.secondary, size: 22),
                              SizedBox(width: 6),
                              Text('Huy hiệu', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${profile.badges.length} Danh hiệu',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.secondary),
                          ),
                          const SizedBox(height: 4),
                          const Text('Đã hoàn thành', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── HUY HIỆU THÀNH TÍCH (BADGES SHOWCASE) ───────────────────────
            Text(
              'Bộ sưu tập Huy hiệu thành tích',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildBadgeCard('🎖️ Tân binh EduMaster', 'Hoàn thành bài đầu tiên', totalXp > 0 || profile.badges.contains('Tân binh EduMaster')),
                _buildBadgeCard('🔥 7 Ngày Chăm chỉ', 'Duy trì chuỗi 7 ngày', streakDays >= 7 || profile.badges.contains('7 Ngày Chăm chỉ')),
                _buildBadgeCard('🧠 Bậc thầy SM-2', 'Ôn tập xuất sắc Flashcards', totalXp >= 1000 || profile.badges.contains('Bậc thầy SM-2')),
                _buildBadgeCard('⚡ Thợ săn Điểm 10', 'Đạt điểm tuyệt đối bài thi', totalXp >= 1500 || profile.badges.contains('Thợ săn Điểm 10')),
                _buildBadgeCard('🌐 Chuyên gia Song ngữ', 'Hoàn thành ôn tập 2 ngôn ngữ', profile.badges.contains('Chuyên gia Song ngữ') || profile.badges.contains('Ngôi sao Song ngữ')),
                _buildBadgeCard('🏆 Chiến binh Bền bỉ', 'Duy trì chuỗi 30 ngày', streakDays >= 30 || profile.badges.contains('Chiến binh Bền bỉ')),
              ],
            ),
            const SizedBox(height: 24),

            // ── THỬ THÁCH MỐC CHUỖI STREAK (MILESTONE CHALLENGES) ───────────
            Text(
              'Thử thách Mốc chuỗi Streak',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildMilestoneTile(
              title: 'Mốc 3 Ngày — Khởi động Chăm chỉ',
              subtitle: 'Duy trì học 3 ngày liên tục',
              targetDays: 3,
              currentDays: streakDays,
              color: const Color(0xFF4CAF50),
            ),
            const SizedBox(height: 10),
            _buildMilestoneTile(
              title: 'Mốc 7 Ngày — Tuần lễ Bứt phá',
              subtitle: 'Duy trì học 7 ngày liên tục',
              targetDays: 7,
              currentDays: streakDays,
              color: const Color(0xFFFF9800),
            ),
            const SizedBox(height: 10),
            _buildMilestoneTile(
              title: 'Mốc 14 Ngày — Chiến binh Kiên trì',
              subtitle: 'Duy trì học 14 ngày liên tục',
              targetDays: 14,
              currentDays: streakDays,
              color: const Color(0xFF2196F3),
            ),
            const SizedBox(height: 10),
            _buildMilestoneTile(
              title: 'Mốc 30 Ngày — Bậc thầy Học thuật',
              subtitle: 'Duy trì học 30 ngày liên tục',
              targetDays: 30,
              currentDays: streakDays,
              color: const Color(0xFF9C27B0),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDayDot(String dayLabel, bool isDone) {
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isDone ? Colors.white : Colors.white.withOpacity(0.25),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDone ? Icons.local_fire_department_rounded : Icons.check,
            size: 20,
            color: isDone ? const Color(0xFFFF5722) : Colors.white54,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          dayLabel,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeCard(String name, String desc, bool isUnlocked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isUnlocked ? AppColors.secondary.withOpacity(0.12) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked ? AppColors.secondary.withOpacity(0.4) : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: isUnlocked ? 1.0 : 0.4,
            child: Text(name.split(' ')[0], style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name.substring(name.indexOf(' ') + 1),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isUnlocked ? AppColors.secondary : Colors.grey.shade600,
                ),
              ),
              Text(
                desc,
                style: TextStyle(fontSize: 10, color: isUnlocked ? AppColors.textSecondaryLight : Colors.grey),
              ),
            ],
          ),
          const SizedBox(width: 4),
          if (isUnlocked)
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
        ],
      ),
    );
  }

  Widget _buildMilestoneTile({
    required String title,
    required String subtitle,
    required int targetDays,
    required int currentDays,
    required Color color,
  }) {
    final isAchieved = currentDays >= targetDays;
    final progress = (currentDays / targetDays).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isAchieved ? Icons.verified_rounded : Icons.lock_clock_rounded,
                  color: isAchieved ? color : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isAchieved ? color : Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isAchieved ? color : Colors.grey).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isAchieved ? '✅ Đã đạt' : '$currentDays/$targetDays ngày',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isAchieved ? color : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                color: isAchieved ? color : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
