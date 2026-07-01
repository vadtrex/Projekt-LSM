import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../../domain/entities/chat_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_local_data_source.dart';
import '../models/chat_hive_model.dart';
import '../models/message_hive_model.dart';

// Implementacja ChatRepository, która korzysta z ChatLocalDataSource do zarządzania danymi czatów i wiadomości.
class ChatRepositoryImpl implements ChatRepository {
  final ChatLocalDataSource localDataSource;
  final Uuid uuid = const Uuid();

  ChatRepositoryImpl(this.localDataSource);

  // Pobieranie listy czatów i mapowanie ich na ChatEntity
  @override
  Future<List<ChatEntity>> getChats() async {
    final models = await localDataSource.getChats();
    return models
        .map(
          (m) => ChatEntity(
            id: m.id,
            title: m.title,
            createdAt: m.createdAt,
            updatedAt: m.updatedAt,
          ),
        )
        .toList();
  }

  // Tworzenie nowego czatu, generowanie unikalnego ID i zapisywanie go w bazie danych
  @override
  Future<ChatEntity> createChat(String title) async {
    final id = uuid.v4();
    final now = DateTime.now();
    final model = ChatHiveModel(
      id: id,
      title: title,
      createdAt: now,
      updatedAt: now,
    );
    await localDataSource.saveChat(model);
    return ChatEntity(id: id, title: title, createdAt: now, updatedAt: now);
  }

  // Usuwanie czatu
  @override
  Future<void> deleteChat(String id) async {
    await localDataSource.deleteChat(id);
  }

  // Pobieranie wiadomości dla danego czatu i mapowanie ich na MessageEntity
  @override
  Future<List<MessageEntity>> getMessagesForChat(String chatId) async {
    final models = await localDataSource.getMessages(chatId);
    return models
        .map(
          (m) => MessageEntity(
            id: m.id,
            chatId: m.chatId,
            content: m.content,
            isUser: m.isUser,
            createdAt: m.createdAt,
            imageBytes: m.imageBytes,
          ),
        )
        .toList();
  }

  // Dodawanie wiadomości do czatu, aktualizacja czasu ostatniej aktualizacji czatu i zapisywanie w bazie danych
  @override
  Future<MessageEntity> addMessage(
    String chatId,
    String content,
    bool isUser, {
    Uint8List? imageBytes,
  }) async {
    final id = uuid.v4();
    final now = DateTime.now();
    final model = MessageHiveModel(
      id: id,
      chatId: chatId,
      content: content,
      isUser: isUser,
      createdAt: now,
      imageBytes: imageBytes,
    );
    await localDataSource.saveMessage(model);

    final chat = await localDataSource.getChat(chatId);
    if (chat == null) {
      throw Exception(
        'Nie można zaktualizować czasu czatu: czat o id "$chatId" nie istnieje.',
      );
    }
    final updatedChat = ChatHiveModel(
      id: chat.id,
      title: chat.title,
      createdAt: chat.createdAt,
      updatedAt: now,
    );
    await localDataSource.saveChat(updatedChat);

    return MessageEntity(
      id: id,
      chatId: chatId,
      content: content,
      isUser: isUser,
      createdAt: now,
      imageBytes: imageBytes,
    );
  }
}
