import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/prompts/system_prompt.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../data/datasources/llm_inference_service.dart';
import 'chat_provider.dart';
import 'llm_provider.dart';
import '../../../models/presentation/providers/models_provider.dart';
import '../../../models/data/utils/model_type_resolver.dart';

// Notifier odpowiedzialny za zarządzanie stanem wiadomości w danym czacie
class MessageNotifier extends StateNotifier<AsyncValue<List<MessageEntity>>> {
  static const _uuid = Uuid();
  // Repozytorium do operacji na wiadomościach
  final ChatRepository _repository;
  // Serwis inferencji LLM
  final LlmInferenceService _llmService;
  // Kontroler stanu dla statusu LLM, pozwala na aktualizację statusu podczas generowania odpowiedzi
  final StateController<LlmInferenceState> _llmStatusController;
  final String chatId;

  final Ref _ref;

  MessageNotifier(
    this._repository,
    this._llmService,
    this._llmStatusController,
    this.chatId,
    this._ref,
  ) : super(const AsyncValue.loading()) {
    loadMessages();
  }

  // Ładowanie wiadomości z repozytorium dla danego czatu
  Future<void> loadMessages() async {
    try {
      state = const AsyncValue.loading();
      final messages = await _repository.getMessagesForChat(chatId);
      state = AsyncValue.data(messages);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Dodawanie nowej wiadomości do czatu
  Future<void> addMessage(
    String content,
    bool isUser, {
    Uint8List? imageBytes,
  }) async {
    final newMessage = await _repository.addMessage(
      chatId,
      content,
      isUser,
      imageBytes: imageBytes,
    );

    state = state.whenData((messages) => [...messages, newMessage]);
  }

  // Wysyłanie wiadomości użytkownika i generowanie odpowiedzi przez LLM
  Future<void> sendMessageAndGenerate({
    required String userMessage,
    required String selectedModelName,
    Uint8List? imageBytes,
  }) async {
    final historyBeforeLatestMessage =
        state.valueOrNull ?? await _repository.getMessagesForChat(chatId);

    // Dodaj wiadomość użytkownika
    await addMessage(userMessage, true, imageBytes: imageBytes);

    final needsContextReload =
        !_llmService.isContextLoaded ||
        _llmService.loadedModelName != selectedModelName ||
        _llmService.loadedChatId != chatId;

    if (needsContextReload) {
      _llmStatusController.state = _llmStatusController.state.copyWith(
        status: LlmStatus.loadingModel,
        errorMessage: null,
      );

      try {
        final modelsState = _ref.read(modelsNotifierProvider);
        final modelEntity = modelsState.models.firstWhere(
          (m) => m.name == selectedModelName,
          orElse: () => throw Exception(
            'Nie znaleziono modelu "$selectedModelName" na liście modeli.',
          ),
        );

        final modelType = resolveModelType(selectedModelName);
        final token = modelsState.huggingFaceToken.trim();
        final downloadUrl = kIsWeb
            ? (modelEntity.webDownloadUrl ?? modelEntity.downloadUrl)
            : modelEntity.downloadUrl;
        final replayHistory = historyBeforeLatestMessage
            .where(
              (message) =>
                  message.content.trim().isNotEmpty ||
                  (message.imageBytes?.isNotEmpty ?? false),
            )
            .map(_toInferenceMessage)
            .toList(growable: false);

        final loaded = await _llmService.initContext(
          selectedModelName,
          chatId: chatId,
          modelType: modelType,
          multimodal: modelEntity.multimodal,
          maxTokens: modelEntity.maxTokens,
          replayHistory: replayHistory,
          systemPrompt: systemPrompt,
          downloadUrl: downloadUrl,
          huggingFaceToken: token.isEmpty ? null : token,
        );

        if (!loaded) {
          _llmStatusController.state = _llmStatusController.state.copyWith(
            status: LlmStatus.error,
            errorMessage:
                'Nie udało się załadować modelu "$selectedModelName".',
          );
          return;
        }
      } catch (e) {
        _llmStatusController.state = _llmStatusController.state.copyWith(
          status: LlmStatus.error,
          errorMessage: 'Błąd ładowania: $e',
        );
        return;
      }
    } else {
      _llmStatusController.state = _llmStatusController.state.copyWith(
        errorMessage: null,
      );
    }

    // Dorzucenie placeholdera dla odpowiedzi asystenta, który będzie aktualizowany na bieżąco podczas generowania odpowiedzi
    final placeholderId = 'streaming_placeholder_${_uuid.v4()}';
    final assistantPlaceholder = MessageEntity(
      id: placeholderId,
      chatId: chatId,
      content: '',
      isUser: false,
      createdAt: DateTime.now(),
    );

    state = state.whenData((messages) => [...messages, assistantPlaceholder]);

    _llmStatusController.state = _llmStatusController.state.copyWith(
      status: LlmStatus.generating,
      loadedModelName: selectedModelName,
    );

    final responseBuffer = StringBuffer();
    // Generowanie odpowiedzi przez LLM z aktualizacją placeholdera na bieżąco
    try {
      await _llmService.generateResponse(
        userMessage: userMessage,
        imageBytes: imageBytes,
        onToken: (token) {
          responseBuffer.write(token);
          final currentContent = responseBuffer.toString();

          state = state.whenData((messages) {
            final updatedMessages = List<MessageEntity>.from(messages);
            final placeholderIndex = updatedMessages.indexWhere(
              (message) => message.id == placeholderId,
            );

            if (placeholderIndex != -1) {
              final placeholderMessage = updatedMessages[placeholderIndex];
              updatedMessages[placeholderIndex] = MessageEntity(
                id: placeholderMessage.id,
                chatId: placeholderMessage.chatId,
                content: currentContent,
                isUser: false,
                createdAt: placeholderMessage.createdAt,
              );
            }
            return updatedMessages;
          });
        },
        // Po zakończeniu generowania, zapisujemy pełną odpowiedź do repozytorium i aktualizujemy placeholder na ostateczną wiadomość
        onComplete: (fullResponse) async {
          final savedMessage = await _repository.addMessage(
            chatId,
            fullResponse,
            false,
          );

          state = state.whenData((messages) {
            final updatedMessages = List<MessageEntity>.from(messages);
            final placeholderIndex = updatedMessages.indexWhere(
              (message) => message.id == placeholderId,
            );

            if (placeholderIndex != -1) {
              updatedMessages[placeholderIndex] = savedMessage;
            } else {
              updatedMessages.add(savedMessage);
            }
            return updatedMessages;
          });

          _llmStatusController.state = _llmStatusController.state.copyWith(
            status: LlmStatus.idle,
          );
        },
      );
      // W przypadku błędu podczas generowania, usuwamy placeholder i aktualizujemy status na błąd
    } catch (error) {
      state = state.whenData((messages) {
        final updatedMessages = List<MessageEntity>.from(messages);
        updatedMessages.removeWhere((message) => message.id == placeholderId);
        return updatedMessages;
      });

      _llmStatusController.state = _llmStatusController.state.copyWith(
        status: LlmStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  // Funkcja do zatrzymania generowania odpowiedzi przez LLM, usuwająca placeholder i aktualizująca status
  Future<void> stopGeneration() async {
    await _llmService.stopGeneration();

    await _llmService.releaseContext();

    state = state.whenData((messages) {
      final updatedMessages = List<MessageEntity>.from(messages);
      updatedMessages.removeWhere(
        (message) => message.id.startsWith('streaming_placeholder_'),
      );
      return updatedMessages;
    });
    _llmStatusController.state = _llmStatusController.state.copyWith(
      status: LlmStatus.idle,
      loadedModelName: null,
    );
  }

  // Konwersja MessageEntity na format zgodny z flutter_gemma
  Message _toInferenceMessage(MessageEntity message) {
    final imageBytes = message.imageBytes;
    final hasImage = imageBytes != null && imageBytes.isNotEmpty;
    final text = message.content;

    if (hasImage) {
      if (text.trim().isEmpty) {
        return Message.imageOnly(
          imageBytes: imageBytes,
          isUser: message.isUser,
        );
      }

      return Message.withImage(
        text: text,
        imageBytes: imageBytes,
        isUser: message.isUser,
      );
    }

    return Message.text(text: text, isUser: message.isUser);
  }
}

final messageNotifierProvider =
    StateNotifierProvider.family<
      MessageNotifier,
      AsyncValue<List<MessageEntity>>,
      String
    >((ref, chatId) {
      final repository = ref.watch(chatRepositoryProvider);
      final llmService = ref.watch(llmInferenceServiceProvider);
      final llmStatusController = ref.watch(llmStatusProvider.notifier);
      return MessageNotifier(
        repository,
        llmService,
        llmStatusController,
        chatId,
        ref,
      );
    });
