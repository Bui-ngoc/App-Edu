import '../entities/quiz_question.dart';
import '../entities/flashcard.dart';
import '../entities/exam.dart';
import '../entities/dictionary_word.dart';
import '../entities/leaderboard_entry.dart';
import '../entities/auth_user.dart';

abstract class IAuthRepository {
  Future<bool> isLoggedIn();
  Future<AuthUser?> getCurrentUser();
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
    String role = 'student',
    String group = 'Thành viên EduMaster',
  });
  Future<AuthUser> login({
    required String email,
    required String password,
  });
  Future<void> logout();
}

abstract class IQuizRepository {
  Future<List<QuizQuestion>> getAllQuestions();
  Future<List<QuizQuestion>> getQuestionsByGrade(int grade);
  Future<List<QuizQuestion>> getWrongQuestions();
  Future<void> saveWrongQuestionId(int id);
  Future<void> removeWrongQuestionId(int id);
}

abstract class IFlashcardRepository {
  Future<List<FlashcardDeck>> getDecks();
  Future<void> saveDeck(FlashcardDeck deck);
  Future<List<FlashcardItem>> getCardsInDeck(String deckId);
  Future<void> saveCard(FlashcardItem card);
  Future<void> updateCardSM2(String cardId, FlashcardItem updatedCard);
  Future<int> importCardsFromCsv(String deckId, String csvContent);
}

abstract class IExamRepository {
  Future<List<ExamRoom>> getAvailableRooms();
  Future<ExamRoom?> getRoomById(String roomId);
  Future<void> createRoom(ExamRoom room);
  Future<void> submitResult(ExamSessionResult result);
  Future<List<ExamSessionResult>> getResultsForRoom(String roomId);
  Future<void> addStudentHistory(String userId, StudentExamHistoryEntry entry);
  Future<List<StudentExamHistoryEntry>> getStudentHistory(String userId);
  Future<void> saveLiveSession(LiveStudentSession session);
  Future<List<LiveStudentSession>> getLiveSessions(String roomId);
}

abstract class IDictionaryRepository {
  Future<void> initDatabase();
  Future<List<DictionaryWord>> searchWords(String query);
  Future<void> toggleBookmark(int id, bool isBookmarked);
  Future<List<DictionaryWord>> getBookmarkedWords();
  Future<DictionaryWord?> getWordOfTheDay();
}

abstract class ILeaderboardRepository {
  Stream<List<LeaderboardEntry>> getRealtimeLeaderboard();
  Future<void> updateXp(String userId, int addedXp);
  Future<UserProfile> getUserProfile({String? email});
  Future<void> saveUserProfile(UserProfile profile);
  Future<({UserProfile profile, bool isNewStreak})> checkAndRecordDailyStreak({String? email});
  Future<void> updateUserLeaderboard({
    required String userId,
    String? userName,
    String? groupName,
    int? xp,
  });
  Future<List<String>> getGroups();
  Future<void> createGroup(String groupName);
  Future<void> deleteGroup(String groupName);
  Future<void> renameGroup(String oldName, String newName);
  Future<void> moveStudentToGroup(String studentId, String newGroupName);
  Future<void> addStudentToGroup({
    required String name,
    required String groupName,
    int initialXp = 0,
  });
}

abstract class IAiTutorRepository {
  Future<String> askAi(String prompt);
  Future<String> explainWrongAnswer({
    required QuizQuestion question,
    required int selectedIndex,
    required bool isEnglish,
  });
}
