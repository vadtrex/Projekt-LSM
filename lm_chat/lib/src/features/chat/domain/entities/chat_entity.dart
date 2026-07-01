// Definicja entity pojedynczego czatu (id, tytuł, data utworzenia i aktualizacji)
class ChatEntity {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatEntity({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });
}
