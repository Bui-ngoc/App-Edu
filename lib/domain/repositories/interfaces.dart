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
    required String group,
  });
  Future<AuthUser> login({
    required String email,
    required String password,
  });
  Future<AuthUser> quickDemoLogin();
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
  Future<UserProfile> getUserProfile();
  Future<void> saveUserProfile(UserProfile profile);
}

abstract class IAiTutorRepository {
  Future<String> askAi(String prompt);
  Future<String> explainWrongAnswer({
    required QuizQuestion question,
    required int selectedIndex,
    required bool isEnglish,
  });
}
