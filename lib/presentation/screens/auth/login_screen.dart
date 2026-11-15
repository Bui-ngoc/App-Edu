import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Login controllers
  final _loginEmailController = TextEditingController(text: 'student@edumaster.edu.vn');
  final _loginPasswordController = TextEditingController(text: '123456');
  bool _obscureLoginPassword = true;
  bool _rememberMe = true;

  // Register controllers
  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmPasswordController = TextEditingController();
  bool _obscureRegisterPassword = true;
  String _selectedGroup = 'Khối 12 - Ôn thi KTHP';

  final List<String> _groupOptions = [
    'Khối 12 - Ôn thi KTHP',
    'Khối 11 - Lập trình & Thuật toán',
    'Khối 8 - Tin học cơ sở',
    'Sinh viên CNTT - ĐH & CĐ',
    'Khối chuyên ngữ & Tự do',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ Email và Mật khẩu!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authProv = context.read<AuthProvider>();
    final success = await authProv.login(email: email, password: password);

    if (success && mounted) {
      context.read<ProfileProvider>().loadProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chào mừng ${authProv.currentUser?.name ?? 'bạn'} trở lại!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProv.errorMessage),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleRegister() async {
    final name = _registerNameController.text.trim();
    final email = _registerEmailController.text.trim();
    final password = _registerPasswordController.text.trim();
    final confirm = _registerConfirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đầy đủ các thông tin đăng ký!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu nhập lại không trùng khớp!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authProv = context.read<AuthProvider>();
    final success = await authProv.register(
      name: name,
      email: email,
      password: password,
      group: _selectedGroup,
    );

    if (success && mounted) {
      context.read<ProfileProvider>().loadProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đăng ký tài khoản thành công! Chào mừng $name.'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProv.errorMessage),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleQuickDemoLogin() async {
    final authProv = context.read<AuthProvider>();
    final success = await authProv.quickDemoLogin();
    if (success && mounted) {
      context.read<ProfileProvider>().loadProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã đăng nhập nhanh với tài khoản sinh viên mẫu!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── EduMaster Brand Header ────────────────────────────
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  AppStrings.appName,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Siêu ứng dụng Giáo dục & Ôn tập Song ngữ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 28),

                // ── Tab Bar (Đăng nhập / Đăng ký) ─────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondaryLight,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    tabs: const [
                      Tab(text: 'Đăng nhập'),
                      Tab(text: 'Đăng ký'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Tab Bar Views ─────────────────────────────────────
                SizedBox(
                  height: 440,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // ── TAB 1: FORM ĐĂNG NHẬP ───────────────────────
                      _buildLoginForm(authProv),

                      // ── TAB 2: FORM ĐĂNG KÝ ─────────────────────────
                      _buildRegisterForm(authProv),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(AuthProvider authProv) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _loginEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email học tập',
              hintText: 'student@edumaster.edu.vn',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _loginPasswordController,
            obscureText: _obscureLoginPassword,
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureLoginPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() => _obscureLoginPassword = !_obscureLoginPassword);
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (val) => setState(() => _rememberMe = val ?? true),
                activeColor: AppColors.primary,
              ),
              const Text('Ghi nhớ đăng nhập', style: TextStyle(fontSize: 13)),
              const Spacer(),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tài khoản mẫu mặc định: student@edumaster.edu.vn / 123456'),
                    ),
                  );
                },
                child: const Text('Quên mật khẩu?', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: authProv.isLoading ? null : _handleLogin,
              child: authProv.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      'ĐĂNG NHẬP',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          // Quick demo login
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.bolt_rounded, color: AppColors.accent),
              label: const Text(
                'Dùng thử nhanh (Tài khoản mẫu)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onPressed: authProv.isLoading ? null : _handleQuickDemoLogin,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(AuthProvider authProv) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _registerNameController,
            decoration: const InputDecoration(
              labelText: 'Họ và tên học viên',
              hintText: 'Ví dụ: Nguyễn Văn A',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _registerEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email đăng ký',
              hintText: 'user@gmail.com',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedGroup,
            decoration: const InputDecoration(
              labelText: 'Khối lớp / Chuyên ngành',
              prefixIcon: Icon(Icons.school_outlined),
              border: OutlineInputBorder(),
            ),
            items: _groupOptions.map((opt) {
              return DropdownMenuItem(value: opt, child: Text(opt, style: const TextStyle(fontSize: 13)));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedGroup = val);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _registerPasswordController,
                  obscureText: _obscureRegisterPassword,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureRegisterPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscureRegisterPassword = !_obscureRegisterPassword);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _registerConfirmPasswordController,
                  obscureText: _obscureRegisterPassword,
                  decoration: const InputDecoration(
                    labelText: 'Nhập lại MK',
                    prefixIcon: Icon(Icons.check_circle_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
              ),
              onPressed: authProv.isLoading ? null : _handleRegister,
              child: authProv.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      'TẠO TÀI KHOẢN MỚI',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
