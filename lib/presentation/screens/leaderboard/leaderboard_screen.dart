import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../../../domain/entities/leaderboard_entry.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lProv = context.read<LeaderboardProvider>();
      final pProv = context.read<ProfileProvider>();
      // Mặc định chọn đúng nhóm của học viên
      if (pProv.profile.currentGroup.isNotEmpty) {
        lProv.selectGroup(pProv.profile.currentGroup);
      }
      lProv.loadLeaderboard();
    });
  }

  // ── Dialog: Giáo viên tạo nhóm mới ────────────────────────────────────────
  void _showCreateGroupDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.group_add_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Tạo nhóm học mới'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập tên nhóm học mới để sinh viên cùng tham gia và thi đua điểm EXP:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Tên nhóm học',
                hintText: 'Ví dụ: Nhóm 4 - Đồ án Tốt nghiệp',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await context.read<LeaderboardProvider>().createGroup(name);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã tạo nhóm học "$name" thành công!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            child: const Text('Tạo nhóm'),
          ),
        ],
      ),
    );
  }

  // ── Dialog: Giáo viên đổi tên nhóm ────────────────────────────────────────
  void _showRenameGroupDialog(BuildContext context, String oldName) {
    final controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đổi tên nhóm học'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Tên nhóm mới',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != oldName) {
                await context.read<LeaderboardProvider>().renameGroup(oldName, newName);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  // ── Dialog: Giáo viên xóa nhóm ───────────────────────────────────────────
  void _showDeleteGroupDialog(BuildContext context, String groupName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa nhóm'),
        content: Text(
          'Bạn có chắc chắn muốn xóa "$groupName"?\n'
          'Các sinh viên trong nhóm này sẽ được tự động chuyển về nhóm học khác.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await context.read<LeaderboardProvider>().deleteGroup(groupName);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Xóa nhóm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Dialog: Chuyển sinh viên sang nhóm khác ───────────────────────────────
  void _showMoveStudentDialog(BuildContext context, LeaderboardEntry student) {
    final lProv = context.read<LeaderboardProvider>();
    final groups = lProv.availableGroups;
    String targetGroup = groups.firstWhere(
      (g) => g != student.groupName,
      orElse: () => student.groupName,
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: Text('Chuyển nhóm: ${student.userName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nhóm hiện tại: ${student.groupName}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('Chọn nhóm học mới:'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: targetGroup,
                isExpanded: true,
                items: groups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => targetGroup = val);
                  }
                },
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                await lProv.moveStudentToGroup(student.id, targetGroup);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã chuyển ${student.userName} sang "$targetGroup"'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Xác nhận chuyển'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dialog: Giáo viên thêm / phân công sinh viên vào nhóm ──────────────
  void _showAddStudentToGroupDialog(BuildContext context, String targetGroup) {
    final lProv = context.read<LeaderboardProvider>();
    final allEntries = lProv.entries;
    final otherStudents = allEntries.where((e) => e.groupName != targetGroup).toList();

    int mode = 0; // 0: chọn từ danh sách SV khác, 1: thêm SV mới
    LeaderboardEntry? selectedStudent = otherStudents.isNotEmpty ? otherStudents.first : null;
    final nameController = TextEditingController();
    final xpController = TextEditingController(text: '1000');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.person_add_rounded, color: AppColors.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Thêm SV vào $targetGroup',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Từ nhóm khác', style: TextStyle(fontSize: 12))),
                    ButtonSegment(value: 1, label: Text('Tạo SV mới', style: TextStyle(fontSize: 12))),
                  ],
                  selected: {mode},
                  onSelectionChanged: (val) {
                    setDialogState(() => mode = val.first);
                  },
                ),
                const SizedBox(height: 16),
                if (mode == 0) ...[
                  if (otherStudents.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Tất cả sinh viên hiện tại đã thuộc nhóm này!', style: TextStyle(color: Colors.grey)),
                    )
                  else ...[
                    const Text('Chọn sinh viên để chuyển vào nhóm này:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<LeaderboardEntry>(
                      value: selectedStudent,
                      isExpanded: true,
                      items: otherStudents.map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text('${s.userName} (${s.groupName})', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setDialogState(() => selectedStudent = val);
                      },
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                  ],
                ] else ...[
                  const Text('Nhập thông tin sinh viên mới:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên sinh viên',
                      prefixIcon: Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: xpController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Điểm EXP khởi đầu',
                      prefixIcon: Icon(Icons.bolt_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (mode == 0) {
                  if (selectedStudent != null) {
                    await lProv.moveStudentToGroup(selectedStudent!.id, targetGroup);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã chuyển ${selectedStudent!.userName} vào "$targetGroup"'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  }
                } else {
                  final name = nameController.text.trim();
                  final xp = int.tryParse(xpController.text.trim()) ?? 0;
                  if (name.isNotEmpty) {
                    await lProv.addStudentToGroup(name: name, groupName: targetGroup, initialXp: xp);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã thêm sinh viên "$name" vào "$targetGroup"'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = context.select<AuthProvider, bool>((a) => a.currentUser?.isTeacher ?? false);

    return DefaultTabController(
      length: isTeacher ? 3 : 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isTeacher ? 'Quản Lý Nhóm & BXH' : 'Bảng Xếp Hạng Nhóm'),
          bottom: TabBar(
            indicatorColor: isTeacher ? AppColors.secondary : AppColors.primary,
            indicatorWeight: 3,
            labelColor: isTeacher ? AppColors.secondary : AppColors.primary,
            unselectedLabelColor: AppColors.textSecondaryLight,
            tabs: isTeacher
                ? const [
                    Tab(icon: Icon(Icons.groups_rounded, size: 20), text: 'Quản Lý Nhóm'),
                    Tab(icon: Icon(Icons.emoji_events_rounded, size: 20), text: 'BXH Theo Nhóm'),
                    Tab(icon: Icon(Icons.local_fire_department_rounded, size: 20), text: 'Chuỗi & Huy Hiệu'),
                  ]
                : const [
                    Tab(icon: Icon(Icons.emoji_events_rounded, size: 20), text: 'BXH Nhóm Học (EXP)'),
                    Tab(icon: Icon(Icons.local_fire_department_rounded, size: 20), text: 'Chuỗi & Huy Hiệu'),
                  ],
          ),
        ),
        body: TabBarView(
          children: isTeacher
              ? [
                  _buildTeacherGroupManagementTab(context),
                  _buildGroupRankingTab(context, isTeacher: true),
                  _buildStreakAndBadgesTab(context),
                ]
              : [
                  _buildGroupRankingTab(context, isTeacher: false),
                  _buildStreakAndBadgesTab(context),
                ],
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB DÀNH RIÊNG CHO GIÁO VIÊN: QUẢN LÝ CÁC NHÓM HỌC TẬP
  // ==========================================================================
  Widget _buildTeacherGroupManagementTab(BuildContext context) {
    final lProv = context.watch<LeaderboardProvider>();
    final groups = lProv.availableGroups;

    return RefreshIndicator(
      onRefresh: () => lProv.loadLeaderboard(force: true),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thẻ tổng quan Giáo viên
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.secondary, Color(0xFF00B4D8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 28),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Bảng Điều Khiển Nhóm Học',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Tạo nhóm'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.secondary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _showCreateGroupDialog(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Hiện có ${groups.length} nhóm học đang thi đua theo điểm tích lũy EXP.',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Danh sách nhóm học (${groups.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                  label: const Text('Thêm nhóm mới'),
                  onPressed: () => _showCreateGroupDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (groups.isEmpty)
              const Center(child: Text('Chưa có nhóm học nào. Bấm "Tạo nhóm" để bắt đầu!'))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: groups.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, idx) {
                  final grp = groups[idx];
                  final studentCount = lProv.getGroupStudentCount(grp);
                  final avgXp = lProv.getGroupAverageXp(grp);
                  final topStudent = lProv.getGroupTopStudent(grp);

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.secondary.withOpacity(0.12),
                                child: const Icon(Icons.groups_rounded, color: AppColors.secondary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      grp,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(
                                      '$studentCount sinh viên • Trung bình: $avgXp EXP',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (action) {
                                  if (action == 'rename') {
                                    _showRenameGroupDialog(context, grp);
                                  } else if (action == 'delete') {
                                    _showDeleteGroupDialog(context, grp);
                                  } else if (action == 'add_student') {
                                    _showAddStudentToGroupDialog(context, grp);
                                  } else if (action == 'view_bxh') {
                                    lProv.selectGroup(grp);
                                    DefaultTabController.of(context).animateTo(1);
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'view_bxh',
                                    child: Row(
                                      children: [
                                        Icon(Icons.emoji_events_outlined, size: 18),
                                        SizedBox(width: 8),
                                        Text('Xem BXH Nhóm này'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'add_student',
                                    child: const Row(
                                      children: [
                                        Icon(Icons.person_add_rounded, size: 18),
                                        SizedBox(width: 8),
                                        Text('Thêm SV vào nhóm'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'rename',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined, size: 18),
                                        SizedBox(width: 8),
                                        Text('Đổi tên nhóm'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                                        SizedBox(width: 8),
                                        Text('Xóa nhóm', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  topStudent != null
                                      ? 'Thủ khoa nhóm: ${topStudent.userName} (${topStudent.xp} EXP)'
                                      : 'Chưa có sinh viên tích lũy EXP',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.person_add_rounded, size: 14),
                                label: const Text('Thêm SV'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                  foregroundColor: Colors.white,
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => _showAddStudentToGroupDialog(context, grp),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () {
                                  lProv.selectGroup(grp);
                                  DefaultTabController.of(context).animateTo(1);
                                },
                                child: const Text('Xem BXH'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB: BẢNG XẾP HẠNG EXP THEO NHÓM HỌC TẬP (Chỉ so sánh cùng nhóm)
  // ==========================================================================
  Widget _buildGroupRankingTab(BuildContext context, {required bool isTeacher}) {
    final lProv = context.watch<LeaderboardProvider>();
    final pProv = context.watch<ProfileProvider>();
    final userProfile = pProv.profile;

    // Sinh viên chỉ thuộc 1 nhóm duy nhất (userProfile.currentGroup) và chỉ so sánh nội bộ nhóm.
    // Giáo viên có thể duyệt xem BXH của bất kỳ nhóm nào.
    final selectedGroup = isTeacher ? lProv.selectedGroup : userProfile.currentGroup;
    final filteredList = lProv.entries.where((e) => e.groupName == selectedGroup).toList()
      ..sort((a, b) => b.xp.compareTo(a.xp));
    final availableGroups = lProv.availableGroups;

    // Tìm thứ hạng cá nhân trong nhóm
    int myRank = 0;
    LeaderboardEntry? myEntry;
    for (int i = 0; i < filteredList.length; i++) {
      final e = filteredList[i];
      if (e.id == userProfile.uid || e.id == 'user_current' || e.userName.contains(userProfile.name)) {
        myRank = i + 1;
        myEntry = e;
        break;
      }
    }

    String diffExpMessage = '';
    if (myRank > 1 && myRank <= filteredList.length) {
      final personAbove = filteredList[myRank - 2];
      final expDiff = personAbove.xp - (myEntry?.xp ?? userProfile.totalXp);
      diffExpMessage = '⚡ Bạn chỉ còn cách hạng #${myRank - 1} (${personAbove.userName}) +$expDiff EXP!';
    } else if (myRank == 1 && filteredList.isNotEmpty) {
      diffExpMessage = '👑 Chúc mừng! Bạn đang dẫn đầu nhóm về điểm tích lũy EXP!';
    }

    return RefreshIndicator(
      onRefresh: () => lProv.loadLeaderboard(force: true),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── THÔNG TIN NHÓM HỌC ĐANG SO TÀI (KHÔNG CÓ "TOÀN TRƯỜNG") ───
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isTeacher ? AppColors.secondary.withOpacity(0.08) : AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isTeacher ? AppColors.secondary.withOpacity(0.25) : AppColors.primary.withOpacity(0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.groups_rounded,
                    color: isTeacher ? AppColors.secondary : AppColors.primary,
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTeacher ? 'Đang xem BXH nhóm học:' : 'Nhóm học của bạn (1 SV chỉ thuộc 1 nhóm):',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selectedGroup,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isTeacher ? AppColors.secondary : AppColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!isTeacher)
                          const Text(
                            '🔒 Nhóm học do Giáo viên phân công cố định. Sinh viên không được phép tự chuyển nhóm.',
                            style: TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                      ],
                    ),
                  ),
                  if (!isTeacher)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_outline_rounded, size: 14, color: Colors.black54),
                          SizedBox(width: 4),
                          Text(
                            'Cố định',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // CHỈ GIÁO VIÊN MỚI CÓ THỂ CHỌN QUA LẠI GIỮA NHIỀU NHÓM ĐỂ THEO DÕI:
            if (isTeacher) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: availableGroups.map((grp) {
                    final isSelected = selectedGroup == grp;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        selected: isSelected,
                        label: Text(grp),
                        selectedColor: AppColors.secondary,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                        onSelected: (_) => lProv.selectGroup(grp),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── THẺ THỨ HẠNG CỦA HỌC VIÊN TRONG NHÓM NÀY ─────────────────────
            if (!isTeacher)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF6C63FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '👥 $selectedGroup',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          myRank > 0 ? 'Hạng: #$myRank trong ${filteredList.length} bạn' : 'Chưa xếp hạng',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white,
                          child: Text(
                            myRank > 0 ? '#$myRank' : '?',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userProfile.name,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${userProfile.totalXp} EXP tích lũy',
                                style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.military_tech_rounded, color: Colors.amberAccent, size: 36),
                      ],
                    ),
                    if (diffExpMessage.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          diffExpMessage,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            if (!isTeacher) const SizedBox(height: 20),

            // ── BỤC VINH DANH PODIUM TOP 3 TRONG NHÓM ────────────────────────
            if (filteredList.length >= 3) ...[
              Center(
                child: Text(
                  '🏆 BỤC VINH DANH TOP 3 NHÓM $selectedGroup',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: AppColors.textPrimaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 14),
              _buildPodium(filteredList, userProfile.uid),
              const SizedBox(height: 24),
            ],

            // ── DANH SÁCH XẾP HẠNG CHI TIẾT THEO EXP ─────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Xếp hạng thành viên (${filteredList.length} sinh viên)',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Sắp xếp: EXP cao nhất',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (filteredList.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    Icon(Icons.person_search_rounded, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text('Chưa có sinh viên nào trong "$selectedGroup".'),
                    const SizedBox(height: 4),
                    const Text('Hãy tham gia nhóm và bắt đầu tích lũy EXP!', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final entry = filteredList[index];
                  final rank = index + 1;
                  final isMe = !isTeacher &&
                      (entry.id == userProfile.uid || entry.id == 'user_current' || entry.userName.contains(userProfile.name));

                  return _buildLeaderboardTile(
                    rank: rank,
                    entry: entry,
                    isMe: isMe,
                    isTeacher: isTeacher,
                    onMoveGroup: () => _showMoveStudentDialog(context, entry),
                  );
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Podium Top 1, 2, 3 ───────────────────────────────────────────────────
  Widget _buildPodium(List<LeaderboardEntry> list, String myUid) {
    final top1 = list[0];
    final top2 = list[1];
    final top3 = list[2];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _buildPodiumPillar(
            rank: 2,
            entry: top2,
            height: 110,
            medal: '🥈',
            color: const Color(0xFFC0C0C0),
            gradientColors: [const Color(0xFFE0E0E0), const Color(0xFFBDBDBD)],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildPodiumPillar(
            rank: 1,
            entry: top1,
            height: 140,
            medal: '🥇',
            color: const Color(0xFFFFD700),
            gradientColors: [const Color(0xFFFFE082), const Color(0xFFFFB300)],
            isCrown: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildPodiumPillar(
            rank: 3,
            entry: top3,
            height: 90,
            medal: '🥉',
            color: const Color(0xFFCD7F32),
            gradientColors: [const Color(0xFFFFCCBC), const Color(0xFFBCAAA4)],
          ),
        ),
      ],
    );
  }

  Widget _buildPodiumPillar({
    required int rank,
    required LeaderboardEntry entry,
    required double height,
    required String medal,
    required Color color,
    required List<Color> gradientColors,
    bool isCrown = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isCrown)
          const Text('👑', style: TextStyle(fontSize: 22))
        else
          const SizedBox(height: 22),
        Text(medal, style: const TextStyle(fontSize: 26)),
        const SizedBox(height: 4),
        Text(
          entry.userName.split(' ').last,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        Text(
          '${entry.xp} EXP',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
                shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 1))],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Dòng sinh viên trong BXH Nhóm ────────────────────────────────────────
  Widget _buildLeaderboardTile({
    required int rank,
    required LeaderboardEntry entry,
    required bool isMe,
    required bool isTeacher,
    VoidCallback? onMoveGroup,
  }) {
    Color rankColor;
    Widget rankIcon;

    if (rank == 1) {
      rankColor = const Color(0xFFFFD700);
      rankIcon = const Text('🥇', style: TextStyle(fontSize: 22));
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0);
      rankIcon = const Text('🥈', style: TextStyle(fontSize: 22));
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32);
      rankIcon = const Text('🥉', style: TextStyle(fontSize: 22));
    } else {
      rankColor = Colors.grey.shade600;
      rankIcon = Text('#$rank', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe ? AppColors.primary : Colors.grey.shade200,
          width: isMe ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(width: 32, child: Center(child: rankIcon)),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 20,
            backgroundColor: rankColor.withOpacity(0.2),
            child: Text(
              entry.userName.isNotEmpty ? entry.userName[0].toUpperCase() : 'U',
              style: TextStyle(fontWeight: FontWeight.bold, color: rankColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.userName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isMe ? AppColors.primary : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Bạn', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '🔥 ${entry.streakDays} ngày chuỗi • ${entry.testsCompleted} bài thi',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded, size: 14, color: AppColors.accent),
                    Text(
                      '${entry.xp} EXP',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              if (isTeacher)
                InkWell(
                  onTap: onMoveGroup,
                  child: const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Chuyển nhóm',
                      style: TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB: CHUỖI NGÀY & HUY HIỆU CÁ NHÂN (Streaks & Badges Showcase)
  // ==========================================================================
  Widget _buildStreakAndBadgesTab(BuildContext context) {
    final profileProv = context.watch<ProfileProvider>();
    final profile = profileProv.profile;
    final streakDays = profile.streakDays;
    final totalXp = profile.totalXp;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // STREAK HERO CARD
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
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 20),
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

          // PERSONAL STATS GRID
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
                            Text('Tích lũy EXP', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
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

          // HUY HIỆU THÀNH TÍCH
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

          // THỬ THÁCH MỐC CHUỖI
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
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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
              Text(desc, style: TextStyle(fontSize: 10, color: isUnlocked ? AppColors.textSecondaryLight : Colors.grey)),
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
