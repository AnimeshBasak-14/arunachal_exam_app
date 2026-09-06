import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return StorageService(prefs, secureStorage);
});

final bookmarkedQuestionsProvider =
    StateNotifierProvider<BookmarkedQuestionsNotifier, List<String>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return BookmarkedQuestionsNotifier(storage);
});

class BookmarkedQuestionsNotifier extends StateNotifier<List<String>> {
  final StorageService _storage;
  BookmarkedQuestionsNotifier(this._storage)
      : super(_storage.getBookmarkedQuestions());

  Future<void> toggleBookmark(String questionId) async {
    await _storage.toggleQuestionBookmark(questionId);
    state = _storage.getBookmarkedQuestions();
  }
}
