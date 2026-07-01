import 'package:hive/hive.dart';
import '../models/chat_hive_model.dart';
import '../models/message_hive_model.dart';

abstract class ChatLocalDataSource {
  Future<List<ChatHiveModel>> getChats();
  Future<void> saveChat(ChatHiveModel chat);
  Future<void> deleteChat(String id);
  Future<ChatHiveModel?> getChat(String id);

  Future<List<MessageHiveModel>> getMessages(String chatId);
  Future<void> saveMessage(MessageHiveModel message);
}

// Implementacja bazy danych do zarządzania czatami i wiadomościami
class ChatLocalDataSourceImpl implements ChatLocalDataSource {
  static const String chatBoxName = 'chats';
  static const String messageBoxName = 'messages';

  Box<ChatHiveModel> get _chatBox => Hive.box<ChatHiveModel>(chatBoxName);
  Box<MessageHiveModel> get _messageBox =>
      Hive.box<MessageHiveModel>(messageBoxName);

  // Pobieranie wszystkich czatów, posortowanych według daty aktualizacji
  @override
  Future<List<ChatHiveModel>> getChats() async {
    return _chatBox.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  // Zapis czatu
  @override
  Future<void> saveChat(ChatHiveModel chat) => _chatBox.put(chat.id, chat);

  // Pobieranie konkretnego czatu po ID
  @override
  Future<ChatHiveModel?> getChat(String id) async {
    return _chatBox.get(id);
  }

  // Usuwanie czatu i wszystkich jego wiadomości
  @override
  Future<void> deleteChat(String id) async {
    await _chatBox.delete(id);

    final messagesToDelete = _messageBox.values
        .where((m) => m.chatId == id)
        .map((m) => m.id)
        .toList();
    await _messageBox.deleteAll(messagesToDelete);
  }

  // Pobieranie wszystkich wiadomości dla danego czatu, posortowanych według daty utworzenia
  @override
  Future<List<MessageHiveModel>> getMessages(String chatId) async {
    return _messageBox.values.where((m) => m.chatId == chatId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  // Zapis wiadomości
  @override
  Future<void> saveMessage(MessageHiveModel message) =>
      _messageBox.put(message.id, message);
}
