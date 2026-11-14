import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/profile_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _groupController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>().profile;
    _nameController.text = profile.name;
    _groupController.text = profile.currentGroup;
    _apiKeyController.text = context.read<ProfileProvider>().apiKey;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _groupController.dispose();
    _apiKeyController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProfileProvider>();
    final profile = prov.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ & Cài đặt'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Avatar card with Camera action
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 54,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
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
            Text(
              profile.currentGroup,
              style: const TextStyle(color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 20),

            // Stats row
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

            // Form: Edit info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thông tin học viên',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                          prov.updateNameAndGroup(_nameController.text, _groupController.text);
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

            // Gemini API Key Card (Criteria 6: Safe storage without hardcoding)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.key_rounded, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Text('Cấu hình Google Gemini AI Key',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Nhập API Key cá nhân để sử dụng mô hình Gemini trực tiếp. Nếu để trống, hệ thống tự kích hoạt bộ AI Tutor ngoại tuyến thông minh.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _apiKeyController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Gemini API Key',
                        hintText: 'AIzaSy...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          prov.saveApiKey(_apiKeyController.text);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã lưu cấu hình khóa API an toàn!')),
                          );
                        },
                        child: const Text('Lưu khóa AI'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Security & Storage Transparency (Criteria 6 requirement)
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
                        Text('Chính sách bảo mật & Lưu trữ',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Bộ 300 câu hỏi: Lưu trữ cục bộ trong file JSON assets.\n'
                      '• Thẻ SM-2 & Bảng điểm: Lưu cục bộ SharedPreferences.\n'
                      '• Từ điển IT: Lưu trong SQLite FTS database offline.\n'
                      '• Camera: Chỉ yêu cầu quyền khi quét QR hoặc đổi ảnh đại diện.\n'
                      '• API Key: Tuyệt đối không hardcode trong mã nguồn.',
                      style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
