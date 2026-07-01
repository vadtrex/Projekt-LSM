import 'dart:typed_data';

// Definicja entity pojedynczej wiadomości (id wiadomości, id czatu, treść, czy od użytkownika, data utworzenia i opcjonalne zdjęcie)
class MessageEntity {
  final String id;
  final String chatId;
  final String content;
  final bool isUser;
  final DateTime createdAt;
  final Uint8List? imageBytes;

  MessageEntity({
    required this.id,
    required this.chatId,
    required this.content,
    required this.isUser,
    required this.createdAt,
    this.imageBytes,
  });
}
