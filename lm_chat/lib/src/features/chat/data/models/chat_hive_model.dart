import 'package:hive/hive.dart';

part 'chat_hive_model.g.dart';

// Model Hive do przechowywania danych czatu w bazie Hive.
@HiveType(typeId: 0)
class ChatHiveModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final DateTime updatedAt;

  ChatHiveModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });
}
