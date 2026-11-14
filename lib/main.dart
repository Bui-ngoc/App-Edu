import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'data/datasources/quiz_local_datasource.dart';
import 'data/datasources/sm2_storage_datasource.dart';
import 'data/datasources/exam_storage_datasource.dart';
import 'data/datasources/dictionary_sqlite_datasource.dart';
import 'data/datasources/leaderboard_datasource.dart';
import 'data/datasources/gemini_ai_datasource.dart';
import 'data/repositories/quiz_repository_impl.dart';
import 'data/repositories/flashcard_repository_impl.dart';
import 'data/repositories/exam_repository_impl.dart';
import 'data/repositories/dictionary_repository_impl.dart';
import 'data/repositories/leaderboard_repository_impl.dart';
import 'data/repositories/ai_tutor_repository_impl.dart';
import 'presentation/providers/quiz_provider.dart';
import 'presentation/providers/flashcard_provider.dart';
import 'presentation/providers/exam_provider.dart';
import 'presentation/providers/dictionary_provider.dart';
import 'presentation/providers/leaderboard_provider.dart';
import 'presentation/providers/profile_provider.dart';
import 'presentation/providers/ai_tutor_provider.dart';
import 'presentation/screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Instantiate data sources
  final quizLocalDataSource = QuizLocalDataSource();
  final sm2StorageDataSource = Sm2StorageDataSource();
  final examStorageDataSource = ExamStorageDataSource();
  final dictionarySqliteDataSource = DictionarySqliteDataSource();
  final leaderboardDataSource = LeaderboardDataSource();
  final geminiAiDataSource = GeminiAiDataSource();

  // Instantiate repositories (Clean Architecture: Domain interfaces satisfied)
  final quizRepo = QuizRepositoryImpl(dataSource: quizLocalDataSource);
  final flashcardRepo = FlashcardRepositoryImpl(dataSource: sm2StorageDataSource);
  final examRepo = ExamRepositoryImpl(dataSource: examStorageDataSource);
  final dictionaryRepo = DictionaryRepositoryImpl(dataSource: dictionarySqliteDataSource);
  final leaderboardRepo = LeaderboardRepositoryImpl(dataSource: leaderboardDataSource);
  final aiTutorRepo = AiTutorRepositoryImpl(dataSource: geminiAiDataSource);

  runApp(
    MultiProvider(
      providers: [
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
    final profileProv = context.watch<ProfileProvider>();

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: profileProv.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const MainNavigationScreen(),
    );
  }
}
