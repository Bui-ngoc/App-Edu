import 'dart:io';
import 'package:flutter/material.dart';
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
  final TextEditingController _nameController    = TextEditingController();
  final TextEditingController _groupController   = TextEditingController();
  final TextEditingController _apiKeyController  = TextEditingController();
  final TextEditingController _proxyUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final prov = context.read<ProfileProvider>();
    _nameController.text     = prov.profile.name;
    _groupController.text    = prov.profile.currentGroup;
    _apiKeyController.text   = prov.apiKey;
    _proxyUrlController.text = prov.proxyUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _groupController.dispose();
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
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov    = context.watch<ProfileProvider>();
    final profile = prov.profile;

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
                  CircleAvatar(
                    radius: 54,
                    backgroundColor: AppColors.primary.withAlpha(38),
                    backgroundImage: (profile.localAvatarPath != null &&
                            File(profile.localAvatarPath!).existsSync())
                        ? FileImage(File(profile.localAvatarPath!))
                        : null,
                    child: (profile.localAvatarPath == null ||
                            !File(profile.localAvatarPath!).existsSync())
                        ? const Icon(Icons.person_rounded, size: 54, color: AppColors.primary)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: EdgeInsets.zero,
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _showAvatarOptions,
                        child: const Icon(Icons.camera_alt_rounded, size: 20),
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
            Text(profile.currentGroup,
                style: const TextStyle(color: AppColors.textSecondaryLight)),
            const SizedBox(height: 20),

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
                          const Text('Chuỗi học tập', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Thông tin học viên ──────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thông tin học viên',
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
                    const SizedBox(height: 12),
                    TextField(
                      controller: _groupController,
                      decoration: const InputDecoration(
                        labelText: 'Nhóm học tập',
                        prefixIcon: Icon(Icons.group_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          prov.updateNameAndGroup(
                              _nameController.text, _groupController.text);
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
                      'Đang đăng nhập: ${profile.email}',
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
