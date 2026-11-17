import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/profile_provider.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController     = TextEditingController();
  final TextEditingController _apiKeyController   = TextEditingController();
  final TextEditingController _proxyUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final prov = context.read<ProfileProvider>();
    _nameController.text     = prov.profile.name;
    _apiKeyController.text   = prov.apiKey;
    _proxyUrlController.text = prov.proxyUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _apiKeyController.dispose();
    _proxyUrlController.dispose();
    super.dispose();
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Chọn ảnh đại diện',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                  title: const Text('Chụp ảnh từ Camera'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    context.read<ProfileProvider>().updateAvatar(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded, color: AppColors.secondary),
                  title: const Text('Chọn từ Thư viện ảnh'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    context.read<ProfileProvider>().updateAvatar(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Đăng xuất tài khoản'),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi phiên làm việc hiện tại không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy bỏ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
              }
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarWidget(String? avatarPath, bool isTeacher) {
    if (avatarPath != null && avatarPath.trim().isNotEmpty) {
      final file = File(avatarPath);
      return ClipOval(
        child: Image.file(
          file,
          width: 108,
          height: 108,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return CircleAvatar(
              radius: 54,
              backgroundColor: (isTeacher ? AppColors.secondary : AppColors.primary).withOpacity(0.15),
              child: Icon(
                isTeacher ? Icons.supervisor_account_rounded : Icons.person_rounded,
                size: 54,
                color: isTeacher ? AppColors.secondary : AppColors.primary,
              ),
            );
          },
        ),
      );
    }

    return CircleAvatar(
      radius: 54,
      backgroundColor: (isTeacher ? AppColors.secondary : AppColors.primary).withOpacity(0.15),
      child: Icon(
        isTeacher ? Icons.supervisor_account_rounded : Icons.person_rounded,
        size: 54,
        color: isTeacher ? AppColors.secondary : AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final user     = authProv.currentUser;
    final prov     = context.watch<ProfileProvider>();
    final profile  = prov.profile;

    final isTeacher = user?.isTeacher ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ & Cài đặt')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ── Avatar ──────────────────────────────────────────────────────
            Center(
              child: Stack(
                children: [
                  _buildAvatarWidget(profile.localAvatarPath, isTeacher),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: EdgeInsets.zero,
                          backgroundColor: isTeacher ? AppColors.secondary : AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _showAvatarOptions,
                        child: const Icon(Icons.camera_alt_rounded, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              profile.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isTeacher ? AppColors.secondary.withOpacity(0.15) : AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isTeacher ? Icons.supervisor_account_rounded : Icons.school_rounded,
                    size: 16,
                    color: isTeacher ? AppColors.secondary : AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isTeacher ? 'Giáo viên (GV)' : 'Sinh viên (SV)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isTeacher ? AppColors.secondary : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ── Mã ID người dùng (SV/GV) ───────────────────────────────
            InkWell(
              onTap: () {
                final id = user?.id ?? profile.uid;
                Clipboard.setData(ClipboardData(text: id));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã sao chép mã ID: $id'),
                    backgroundColor: AppColors.success,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.badge_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Mã ID: ${user?.id ?? profile.uid}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Chuyển đổi Vai trò (Giáo viên ↔ Sinh viên) ────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isTeacher ? Icons.supervisor_account_rounded : Icons.school_rounded,
                          color: isTeacher ? AppColors.secondary : AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Chuyển đổi vai trò tài khoản',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Hiện tại bạn đang ở vai trò: ${isTeacher ? "Giáo viên (GV)" : "Sinh viên (SV)"}.\nBấm nút bên dưới để chuyển nhanh giao diện sử dụng.',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isTeacher ? AppColors.primary : AppColors.secondary,
                          foregroundColor: Colors.white,
                        ),
                        icon: Icon(
                          isTeacher ? Icons.school_rounded : Icons.supervisor_account_rounded,
                          size: 20,
                        ),
                        label: Text(
                          isTeacher ? 'Chuyển sang vai trò SINH VIÊN' : 'Chuyển sang vai trò GIÁO VIÊN',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () async {
                          final targetRole = isTeacher ? 'student' : 'teacher';
                          final success = await context.read<AuthProvider>().switchRole(targetRole);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Đã chuyển sang vai trò ${isTeacher ? "Sinh viên" : "Giáo viên"} thành công!',
                                ),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Stats row ───────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        children: [
                          const Icon(Icons.flash_on_rounded, color: AppColors.accent, size: 28),
                          const SizedBox(height: 4),
                          Text('${profile.totalXp} XP',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const Text('Điểm tích lũy', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        children: [
                          const Icon(Icons.local_fire_department_rounded,
                              color: AppColors.warning, size: 28),
                          const SizedBox(height: 4),
                          Text('${profile.streakDays} Ngày',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const Text('Chuỗi hoạt động', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Thông tin tài khoản ──────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thông tin cá nhân',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          prov.updateNameAndGroup(
                            _nameController.text,
                            isTeacher ? 'Giảng viên' : 'Sinh viên',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã cập nhật thông tin thành công!')),
                          );
                        },
                        child: const Text('Lưu thông tin'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Cấu hình AI (Proxy + Direct Key + Demo Mode) ────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        const Icon(Icons.smart_toy_rounded, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Cấu hình AI Tutor',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Demo Mode toggle
                    Semantics(
                      label: 'Bật tắt chế độ Demo AI',
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: Icon(
                          prov.isDemoMode ? Icons.science_rounded : Icons.science_outlined,
                          color: prov.isDemoMode ? AppColors.accent : AppColors.textSecondaryLight,
                        ),
                        title: const Text('Chế độ Demo',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text(
                          'Sử dụng dữ liệu mẫu offline, không cần key.',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: prov.isDemoMode,
                        onChanged: (v) => prov.setDemoMode(v),
                      ),
                    ),
                    const Divider(height: 20),

                    // Proxy Server URL
                    Text('Proxy Server URL',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _proxyUrlController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Proxy URL',
                        hintText: 'https://my-proxy.example.com/ask',
                        prefixIcon: Icon(Icons.dns_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.save_rounded, size: 18),
                        label: const Text('Lưu Proxy URL'),
                        onPressed: () {
                          prov.saveProxyUrl(_proxyUrlController.text);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã lưu Proxy URL!')),
                          );
                        },
                      ),
                    ),
                    const Divider(height: 20),

                    // Direct Gemini API Key (fallback)
                    Text('Gemini API Key',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _apiKeyController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Gemini API Key',
                        hintText: 'AIzaSy...',
                        prefixIcon: Icon(Icons.key_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.lock_rounded, size: 18),
                        label: const Text('Lưu khóa AI'),
                        onPressed: () {
                          prov.saveApiKey(_apiKeyController.text);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Đã lưu cấu hình khóa API an toàn!')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Chính sách bảo mật ──────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.security_rounded, color: AppColors.secondary),
                        const SizedBox(width: 8),
                        Text('Bảo mật & Quyền riêng tư',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Dữ liệu bài học & từ điển được lưu trữ an toàn trên thiết bị.\n'
                      '• Camera chỉ sử dụng khi quét mã QR hoặc chụp ảnh đại diện.\n'
                      '• Khóa API cá nhân được lưu trữ cục bộ, tuyệt đối bảo mật.',
                      style: TextStyle(fontSize: 12, height: 1.6, color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Tài khoản & Đăng xuất ───────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.manage_accounts_rounded, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Tài khoản & Phiên làm việc',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Đang đăng nhập: ${user?.email ?? profile.email}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 20),
                        label: const Text(
                          'Đăng xuất tài khoản',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => _confirmLogout(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
