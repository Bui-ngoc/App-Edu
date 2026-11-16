import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/exam.dart';
import '../../providers/exam_provider.dart';

class TeacherRoomDetailScreen extends StatefulWidget {
  final ExamRoom room;

  const TeacherRoomDetailScreen({super.key, required this.room});

  @override
  State<TeacherRoomDetailScreen> createState() => _TeacherRoomDetailScreenState();
}

class _TeacherRoomDetailScreenState extends State<TeacherRoomDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<LiveStudentSession> _liveSessions = [];
  List<ExamSessionResult> _submittedResults = [];
  bool _isLoading = true;
  Timer? _liveTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRoomData();

    // Auto-refresh live monitoring data every 3 seconds
    _liveTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        _fetchLiveSessionsOnly();
      }
    });
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRoomData() async {
    setState(() => _isLoading = true);
    final examProv = context.read<ExamProvider>();
    final live = await examProv.getLiveSessions(widget.room.id);
    final submitted = await examProv.getRoomResults(widget.room.id);

    if (mounted) {
      setState(() {
        _liveSessions = live;
        _submittedResults = submitted;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchLiveSessionsOnly() async {
    final examProv = context.read<ExamProvider>();
    final live = await examProv.getLiveSessions(widget.room.id);
    final submitted = await examProv.getRoomResults(widget.room.id);

    if (mounted) {
      setState(() {
        _liveSessions = live;
        _submittedResults = submitted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(room.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Mã phòng PIN: ${room.id}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.videocam_rounded), text: 'Giám sát thi'),
            Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Thống kê điểm'),
            Tab(icon: Icon(Icons.qr_code_2_rounded), text: 'Mã QR & Đề'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── TAB 1: GIÁM SÁT TRỰC TIẾP (LIVE MONITORING) ───────────────────
          _buildLiveMonitorTab(),

          // ── TAB 2: THỐNG KÊ ĐIỂM SỐ & BIỂU ĐỒ (STATISTICS CHART) ───────────
          _buildStatisticsTab(),

          // ── TAB 3: MÃ QR & THÔNG TIN PHÒNG (QR CODE & ROOM INFO) ──────────
          _buildRoomInfoTab(),
        ],
      ),
    );
  }

  // ── TAB 1: LIVE MONITOR ──────────────────────────────────────────────────
  Widget _buildLiveMonitorTab() {
    final activeCount = _liveSessions.where((s) => !s.isFinished).length;
    final finishedCount = _submittedResults.length;
    final totalViolations = _liveSessions.fold<int>(0, (sum, s) => sum + s.appSwitchViolations);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status bar
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Đang thi',
                  value: '$activeCount',
                  color: AppColors.warning,
                  icon: Icons.timer_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  title: 'Đã nộp bài',
                  value: '$finishedCount',
                  color: AppColors.success,
                  icon: Icons.check_circle_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  title: 'Lượt rời app',
                  value: '$totalViolations',
                  color: AppColors.error,
                  icon: Icons.warning_amber_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              const Icon(Icons.people_alt_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Danh sách sinh viên tham gia (${_liveSessions.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                onPressed: _loadRoomData,
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_liveSessions.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.person_search_rounded, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  const Text(
                    'Chưa có sinh viên nào truy cập phòng thi này.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cho sinh viên nhập mã PIN "${widget.room.id}" hoặc quét QR để vào thi.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                ],
              ),
            )
          else
            ..._liveSessions.map((session) {
              final hasViolations = session.appSwitchViolations > 0;
              final progress = session.progressPercentage;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: hasViolations ? AppColors.error.withOpacity(0.5) : AppColors.borderLight,
                    width: hasViolations ? 1.5 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: session.isFinished
                                ? AppColors.success.withOpacity(0.15)
                                : AppColors.warning.withOpacity(0.15),
                            child: Icon(
                              session.isFinished ? Icons.check : Icons.edit_note_rounded,
                              color: session.isFinished ? AppColors.success : AppColors.warning,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  session.studentName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  session.isFinished
                                      ? '✅ Đã nộp bài'
                                      : '🔴 Đang làm câu ${session.currentIndex + 1}/${session.totalQuestions}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: session.isFinished ? AppColors.success : AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (hasViolations)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Thoát app ${session.appSwitchViolations} lần',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Progress bar
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress / 100.0,
                                minHeight: 6,
                                backgroundColor: Colors.grey.shade200,
                                color: session.isFinished ? AppColors.success : AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${session.answeredCount}/${session.totalQuestions} câu',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),

                      if (hasViolations && session.violationTimestamps.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ...session.violationTimestamps.map((ts) {
                          return Text(
                            '• $ts',
                            style: const TextStyle(fontSize: 11, color: AppColors.error),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // ── TAB 2: STATISTICS TAB ────────────────────────────────────────────────
  Widget _buildStatisticsTab() {
    final totalCount = _submittedResults.length;
    double avgScoreScale10 = 0;
    double maxScoreScale10 = 0;
    int passCount = 0;

    int bandKem = 0; // < 5.0
    int bandTB = 0; // 5.0 - 6.9
    int bandKha = 0; // 7.0 - 8.4
    int bandGioi = 0; // 8.5 - 10.0

    if (totalCount > 0) {
      double sum = 0;
      for (final r in _submittedResults) {
        final score10 = r.scoreOnScale10;
        sum += score10;
        if (score10 > maxScoreScale10) maxScoreScale10 = score10;
        if (score10 >= 5.0) passCount++;

        if (score10 < 5.0) {
          bandKem++;
        } else if (score10 < 7.0) {
          bandTB++;
        } else if (score10 < 8.5) {
          bandKha++;
        } else {
          bandGioi++;
        }
      }
      avgScoreScale10 = sum / totalCount;
    }

    final passPercentage = totalCount > 0 ? (passCount / totalCount) * 100 : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (totalCount == 0)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.bar_chart_rounded, size: 52, color: Colors.grey),
                    SizedBox(height: 10),
                    Text(
                      'Chưa có sinh viên nào nộp bài.',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Biểu đồ thống kê điểm số sẽ hiển thị tự động khi có sinh viên nộp bài.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Metrics row
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    title: 'Bài đã nộp',
                    value: '$totalCount',
                    color: AppColors.primary,
                    icon: Icons.assignment_turned_in_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    title: 'Điểm TB (/10)',
                    value: avgScoreScale10.toStringAsFixed(1),
                    color: AppColors.accent,
                    icon: Icons.grade_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    title: 'Tỉ lệ Đạt',
                    value: '${passPercentage.toStringAsFixed(0)}%',
                    color: AppColors.success,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Histogram Bar Chart
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bar_chart_rounded, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Biểu đồ phân bố điểm số (Thang 10)',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildScoreHistogram(
                      total: totalCount,
                      bandKem: bandKem,
                      bandTB: bandTB,
                      bandKha: bandKha,
                      bandGioi: bandGioi,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Detailed submission table
            Text(
              'Danh sách sinh viên đã nộp bài ($totalCount)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 10),

            ..._submittedResults.map((res) {
              final score10 = res.scoreOnScale10;
              final isPassed = score10 >= 5.0;
              final dateStr = DateFormat('HH:mm - dd/MM/yyyy').format(res.submittedAt);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: isPassed ? AppColors.success.withOpacity(0.15) : AppColors.error.withOpacity(0.15),
                    child: Text(
                      score10.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: isPassed ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ),
                  title: Text(res.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text('Thời gian: ${res.timeSpentSeconds ~/ 60}p ${res.timeSpentSeconds % 60}s • Nộp: $dateStr'),
                  trailing: Text(
                    '${res.score}/${res.totalQuestions} câu',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ── TAB 3: ROOM INFO & QR CODE ───────────────────────────────────────────
  Widget _buildRoomInfoTab() {
    final room = widget.room;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text('Mã QR cho sinh viên vào thi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: QrImageView(
                      data: room.id,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Mã PIN: ${room.id}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Thời lượng: ${room.durationMinutes} phút • Tổng số: ${room.questions.length} câu',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chi tiết cấu trúc bộ đề (${room.questions.length} câu)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const Divider(),
                  ...room.questions.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final q = entry.value;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 12,
                        child: Text('${idx + 1}', style: const TextStyle(fontSize: 10)),
                      ),
                      title: Text(q.questionVi, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('Đáp án đúng: ${String.fromCharCode(65 + q.correctIndex)}'),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreHistogram({
    required int total,
    required int bandKem,
    required int bandTB,
    required int bandKha,
    required int bandGioi,
  }) {
    final maxBand = [bandKem, bandTB, bandKha, bandGioi].reduce((a, b) => a > b ? a : b);
    final maxHeight = 120.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildBar('< 5.0\n(Yếu)', bandKem, total, maxBand > 0 ? maxBand : 1, AppColors.error, maxHeight),
        _buildBar('5.0 - 6.9\n(TB)', bandTB, total, maxBand > 0 ? maxBand : 1, AppColors.warning, maxHeight),
        _buildBar('7.0 - 8.4\n(Khá)', bandKha, total, maxBand > 0 ? maxBand : 1, AppColors.primary, maxHeight),
        _buildBar('8.5 - 10\n(Giỏi)', bandGioi, total, maxBand > 0 ? maxBand : 1, AppColors.success, maxHeight),
      ],
    );
  }

  Widget _buildBar(String label, int count, int total, int maxCount, Color color, double maxHeight) {
    final ratio = count / maxCount;
    final h = (ratio * maxHeight).clamp(14.0, maxHeight);
    final pct = total > 0 ? (count / total) * 100 : 0.0;

    return Column(
      children: [
        Text('$count SV\n(${pct.toStringAsFixed(0)}%)', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Container(
          width: 38,
          height: h,
          decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
        ),
        const SizedBox(height: 6),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight)),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight)),
        ],
      ),
    );
  }
}
