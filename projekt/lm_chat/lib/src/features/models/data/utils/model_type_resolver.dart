import 'package:flutter_gemma/flutter_gemma.dart';

// Funkcja do mapowania nazwy modelu na ModelType, wymagany przez flutter_gemma.
ModelType resolveModelType(String modelName) {
  final normalized = modelName.toLowerCase();
  if (normalized.contains('gemma 4')) return ModelType.gemma4;
  if (normalized.contains('qwen3') || normalized.contains('qwen 3')) {
    return ModelType.qwen3;
  }
  if (normalized.contains('qwen')) return ModelType.qwen;
  if (normalized.contains('deepseek')) return ModelType.deepSeek;
  if (normalized.contains('functiongemma')) return ModelType.functionGemma;
  return ModelType.gemmaIt;
}
