import 'dart:typed_data';

import 'package:lm_chat/src/features/chat/domain/entities/chat_entity.dart';
import 'package:lm_chat/src/features/chat/domain/entities/message_entity.dart';

// Definicja interfejsu do zarządzania czatami i wiadomościami
abstract class ChatRepository {
  Future<List<ChatEntity>> getChats();
  Future<ChatEntity> createChat(String title);
  Future<void> deleteChat(String id);

  Future<List<MessageEntity>> getMessagesForChat(String chatId);
  Future<MessageEntity> addMessage(
    String chatId,
    String content,
    bool isUser, {
    Uint8List? imageBytes,
  });
}
