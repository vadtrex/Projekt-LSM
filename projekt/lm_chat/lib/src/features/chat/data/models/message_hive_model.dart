import 'dart:typed_data';

import 'package:hive/hive.dart';

part 'message_hive_model.g.dart';

// Model Hive do przechowywania danych wiadomości w bazie Hive.
@HiveType(typeId: 1)
class MessageHiveModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String chatId;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final bool isUser;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final Uint8List? imageBytes;

  MessageHiveModel({
    required this.id,
    required this.chatId,
    required this.content,
    required this.isUser,
    required this.createdAt,
    this.imageBytes,
  });
}
