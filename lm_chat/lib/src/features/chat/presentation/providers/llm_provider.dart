import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/llm_inference_service.dart';

/// Provider inferencji LLM
final llmInferenceServiceProvider = Provider<LlmInferenceService>((ref) {
  final service = LlmInferenceService();
  ref.onDispose(() => service.releaseContext());
  return service;
});

/// Status inferencji LLM
enum LlmStatus { idle, loadingModel, generating, error }

class LlmInferenceState {
  static const _sentinel = Object();

  // Aktualny status inferencji LLM
  final LlmStatus status;
  // Opcjonalna wiadomość błędu, jeśli status to error
  final String? errorMessage;
  // Nazwa aktualnie załadowanego modelu (jeśli jest załadowany)
  final String? loadedModelName;

  const LlmInferenceState({
    this.status = LlmStatus.idle,
    this.errorMessage,
    this.loadedModelName,
  });

  LlmInferenceState copyWith({
    LlmStatus? status,
    // Object? zamiast String?, aby móc jawnie przekazać null jako brak błędu.
    Object? errorMessage = _sentinel,
    // Object? zamiast String?, aby móc jawnie przekazać null jako brak załadowanego modelu.
    Object? loadedModelName = _sentinel,
  }) {
    return LlmInferenceState(
      status: status ?? this.status,
      // Jeśli errorMessage jest przekazane jako _sentinel, zachowujemy istniejącą wartość.
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      // Jeśli loadedModelName jest przekazane jako _sentinel, zachowujemy istniejącą wartość.
      loadedModelName: identical(loadedModelName, _sentinel)
          ? this.loadedModelName
          : loadedModelName as String?,
    );
  }
}

// Provider stanu inferencji LLM.
final llmStatusProvider = StateProvider<LlmInferenceState>(
  (ref) => const LlmInferenceState(),
);
