import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'core/constants/app_colors.dart';
import 'data/datasources/quiz_local_datasource.dart';
import 'data/datasources/sm2_storage_datasource.dart';
import 'data/datasources/exam_storage_datasource.dart';
import 'data/datasources/dictionary_sqlite_datasource.dart';
import 'data/datasources/leaderboard_datasource.dart';
import 'data/datasources/gemini_ai_datasource.dart';
import 'data/datasources/auth_local_datasource.dart';
import 'data/repositories/quiz_repository_impl.dart';
import 'data/repositories/flashcard_repository_impl.dart';
import 'data/repositories/exam_repository_impl.dart';
import 'data/repositories/dictionary_repository_impl.dart';
import 'data/repositories/leaderboard_repository_impl.dart';
import 'data/repositories/ai_tutor_repository_impl.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'presentation/providers/quiz_provider.dart';
import 'presentation/providers/flashcard_provider.dart';
import 'presentation/providers/exam_provider.dart';
import 'presentation/providers/dictionary_provider.dart';
import 'presentation/providers/leaderboard_provider.dart';
import 'presentation/providers/profile_provider.dart';
import 'presentation/providers/ai_tutor_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/main_navigation_screen.dart';

Future<void> _clearLegacyDataOnFirstRun() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    const legacyCleanedFlag = 'edumaster_legacy_cleaned_v10';
    if (!(prefs.getBool(legacyCleanedFlag) ?? false)) {
      final keys = prefs.getKeys().toList();
      for (final k in keys) {
        // Bảo vệ toàn diện dữ liệu tài khoản, hồ sơ sinh viên, nhóm học và BXH
        if (k.contains('registered_users') ||
            k.contains('leaderboard') ||
            k.contains('study_groups') ||
            k.contains('user_profile') ||
            k.contains('session') ||
            k.contains('is_user_logged_in')) {
          continue;
        }
        if (k.startsWith('edumaster_legacy_') || k.startsWith('edumaster_v1_') || k.startsWith('edumaster_v2_')) {
          await prefs.remove(k);
        }
      }
      await prefs.setBool(legacyCleanedFlag, true);
    }
  } catch (_) {}
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _clearLegacyDataOnFirstRun();

  // Instantiate data sources
  final quizLocalDataSource = QuizLocalDataSource();
  final sm2StorageDataSource = Sm2StorageDataSource();
  final examStorageDataSource = ExamStorageDataSource();
  final dictionarySqliteDataSource = DictionarySqliteDataSource();
  final leaderboardDataSource = LeaderboardDataSource();
  final geminiAiDataSource = GeminiAiDataSource();
  final authLocalDataSource = AuthLocalDataSource(leaderboardDataSource: leaderboardDataSource);

  // Instantiate repositories (Clean Architecture)
  final quizRepo = QuizRepositoryImpl(dataSource: quizLocalDataSource);
  final flashcardRepo = FlashcardRepositoryImpl(dataSource: sm2StorageDataSource);
  final examRepo = ExamRepositoryImpl(dataSource: examStorageDataSource);
  final dictionaryRepo = DictionaryRepositoryImpl(dataSource: dictionarySqliteDataSource);
  final leaderboardRepo = LeaderboardRepositoryImpl(dataSource: leaderboardDataSource);
  final aiTutorRepo = AiTutorRepositoryImpl(dataSource: geminiAiDataSource);
  final authRepo = AuthRepositoryImpl(dataSource: authLocalDataSource);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authRepo: authRepo,
            quizDataSource: quizLocalDataSource,
            sm2DataSource: sm2StorageDataSource,
            examDataSource: examStorageDataSource,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => QuizProvider(quizRepo: quizRepo, aiRepo: aiTutorRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => FlashcardProvider(repo: flashcardRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => ExamProvider(examRepo: examRepo, leaderboardRepo: leaderboardRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => DictionaryProvider(repo: dictionaryRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => LeaderboardProvider(repo: leaderboardRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(repo: leaderboardRepo, aiDataSource: geminiAiDataSource),
        ),
        ChangeNotifierProvider(
          create: (_) => AiTutorProvider(aiRepo: aiTutorRepo),
        ),
      ],
      child: const EduMasterApp(),
    ),
  );
}

class EduMasterApp extends StatelessWidget {
  const EduMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Select ONLY isDarkMode so MaterialApp is NEVER rebuilt on profile/XP/avatar updates
    final isDarkMode = context.select<ProfileProvider, bool>((p) => p.isDarkMode);

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.15,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();

    if (authProv.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (authProv.isLoggedIn) {
      return const MainNavigationScreen();
    }

    return const LoginScreen();
  }
}
