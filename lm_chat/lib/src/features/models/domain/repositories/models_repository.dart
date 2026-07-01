import '../entities/llm_model_entity.dart';

abstract class ModelsRepository {
  Future<List<LlmModelEntity>> getAvailableModels();
  Future<String?> getSelectedModelName();
  Future<void> saveSelectedModelName(String name);
  Future<void> clearSelectedModelName();
  Future<List<String>> getDownloadedModels();
  Future<void> markModelAsDownloaded(String name);
  Future<void> deleteDownloadedModel(String name);
}
