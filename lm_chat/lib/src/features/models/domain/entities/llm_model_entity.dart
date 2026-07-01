// Definicja entity reprezentującej model LLM do pobrania
class LlmModelEntity {
  final String name;
  final String downloadUrl;
  final String? webDownloadUrl;

  final String description;
  final String parameters;
  final String size;
  final String image;
  final bool requiresHuggingFaceToken;
  final bool multimodal;
  final int maxTokens;

  LlmModelEntity({
    required this.name,
    required this.downloadUrl,
    this.webDownloadUrl,
    required this.description,
    required this.parameters,
    required this.size,
    required this.image,
    this.requiresHuggingFaceToken = false,
    this.multimodal = false,
    this.maxTokens = 1024,
  });
}
