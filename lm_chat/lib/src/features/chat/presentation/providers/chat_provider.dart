import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import 'package:lm_chat/src/features/chat/data/datasources/chat_local_data_source.dart';
import 'package:lm_chat/src/features/chat/data/repositories/chat_repository_impl.dart';

// Providery dla ChatLocalDataSource i ChatRepository
final chatLocalDataSourceProvider = Provider<ChatLocalDataSource>((ref) {
  return ChatLocalDataSourceImpl();
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final dataSource = ref.watch(chatLocalDataSourceProvider);
  return ChatRepositoryImpl(dataSource);
});

// StateNotifier dla zarządzania stanem listy czatów
class ChatNotifier extends StateNotifier<AsyncValue<List<ChatEntity>>> {
  final ChatRepository _repository;

  // Konstruktor inicjalizujący stan jako loading i ładujący czaty
  ChatNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadChats();
  }

  // Funkcja do ładowania czatów z repozytorium i aktualizacji stanu
  Future<void> loadChats() async {
    try {
      state = const AsyncValue.loading();
      final chats = await _repository.getChats();
      state = AsyncValue.data(chats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Funkcja do tworzenia nowego czatu (po utworzeniu odświeża listę czatów)
  Future<String> createChat(String title) async {
    final chat = await _repository.createChat(title);
    await loadChats();
    return chat.id;
  }

  // Funkcja do usuwania czatu po ID (po usunięciu odświeża listę czatów)
  Future<void> deleteChat(String id) async {
    await _repository.deleteChat(id);
    await loadChats();
  }
}

// Provider dla ChatNotifier, który udostępnia stan listy czatów jako AsyncValue
final chatNotifierProvider =
    StateNotifierProvider<ChatNotifier, AsyncValue<List<ChatEntity>>>((ref) {
      final repository = ref.watch(chatRepositoryProvider);
      return ChatNotifier(repository);
    });
