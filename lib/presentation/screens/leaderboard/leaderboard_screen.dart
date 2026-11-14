import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/state_views.dart';
import '../../providers/leaderboard_provider.dart';
import '../../providers/profile_provider.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<LeaderboardProvider>();
    final profile = context.watch<ProfileProvider>().profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng xếp hạng thi đua (#36)'),
      ),
      body: prov.state == LeaderboardUiState.loading
          ? const LoadingView(message: 'Đang đồng bộ bảng xếp hạng thời gian thực...')
          : prov.state == LeaderboardUiState.error
              ? ErrorViewWithRetry(
                  message: prov.errorMessage,
                  onRetry: () {},
                )
              : CustomScrollView(
                  slivers: [
                    // Study Group & Streak Header Card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Card(
                          color: AppColors.primary,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.group_work_rounded, color: Colors.white, size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            profile.currentGroup,
                                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.bolt_rounded, color: AppColors.accent, size: 28),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Thi đua Tích lũy XP & Giữ chuỗi Streak',
                                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Cập nhật trực tiếp theo thời gian thực (Realtime Stream / Firestore)',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Badges Showcase (Topic #36 Extension)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Huy hiệu đạt được (Badges)',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 40,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  _buildBadge('🎖️ Tân binh EduMaster'),
                                  _buildBadge('🔥 7 Ngày Chăm chỉ'),
                                  _buildBadge('🧠 Bậc thầy SM-2'),
                                  _buildBadge('⚡ Thợ săn Điểm 10'),
                                  _buildBadge('🌐 Chuyên gia Song ngữ'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Bảng xếp hạng tổng điểm',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),

                    // Leaderboard list
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final entry = prov.entries[index];
                            final rank = index + 1;
                            final isCurrentUser = entry.id == profile.uid || entry.userName.contains('(Bạn)');

                            Color? rankColor;
                            if (rank == 1) rankColor = const Color(0xFFFFD700); // Gold
                            if (rank == 2) rankColor = const Color(0xFFC0C0C0); // Silver
                            if (rank == 3) rankColor = const Color(0xFFCD7F32); // Bronze

                            return Card(
                              color: isCurrentUser
                                  ? AppColors.primary.withOpacity(0.08)
                                  : null,
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 28,
                                      child: rankColor != null
                                          ? Icon(Icons.emoji_events_rounded, color: rankColor, size: 22)
                                          : Text(
                                              '$rank',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                    ),
                                    const SizedBox(width: 8),
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppColors.primary.withOpacity(0.15),
                                      backgroundImage: (entry.avatarUrl.isNotEmpty && File(entry.avatarUrl).existsSync())
                                          ? FileImage(File(entry.avatarUrl))
                                          : null,
                                      child: (entry.avatarUrl.isEmpty || !File(entry.avatarUrl).existsSync())
                                          ? Text(
                                              entry.userName.isNotEmpty ? entry.userName[0] : 'U',
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                                title: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        entry.userName,
                                        style: TextStyle(
                                          fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isCurrentUser) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text('BẠN', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Text(
                                  '🔥 ${entry.streakDays} ngày chuỗi • ${entry.testsCompleted} bài đã làm',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${entry.xp} XP',
                                    style: const TextStyle(
                                      color: Color(0xFFB45309),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: prov.entries.length,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
    );
  }

  Widget _buildBadge(String title) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
      ),
      child: Center(
        child: Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondary),
        ),
      ),
    );
  }
}
