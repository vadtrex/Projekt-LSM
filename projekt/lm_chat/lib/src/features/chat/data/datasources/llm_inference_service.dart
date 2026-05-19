import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_gemma/flutter_gemma.dart';

import '../../../models/data/utils/model_type_resolver.dart';

// Serwis inferencji LLM, który zarządza modelem, czatem i kontekstem.
class LlmInferenceService {
  InferenceModel? _inferenceModel;
  InferenceChat? _activeChat;
  String? _loadedModelName;
  String? _loadedSystemPrompt;
  String? _loadedChatId;

  bool get isContextLoaded => _inferenceModel != null && _activeChat != null;
  String? get loadedModelName => _loadedModelName;
  String? get loadedChatId => _loadedChatId;

  // Inicjalizacja kontekstu inferencji LLM dla danego modelu i rozmowy.
  Future<bool> initContext(
    String modelName, {
    required String chatId,
    required String downloadUrl,
    required ModelType modelType,
    required bool multimodal,
    required int maxTokens,
    List<Message> replayHistory = const [],
    String systemPrompt = '',
    String? huggingFaceToken,
  }) async {
    // Jeśli ta sama rozmowa z tym samym modelem i promptem jest już załadowana.
    if (_loadedModelName == modelName &&
        _loadedSystemPrompt == systemPrompt &&
        _loadedChatId == chatId &&
        _inferenceModel != null &&
        _activeChat != null) {
      return true;
    }

    await releaseContext();

    final isMultimodal = multimodal && !kIsWeb;
    final modelFileType = resolveModelFileType(downloadUrl);

    await FlutterGemma.installModel(
      modelType: modelType,
      fileType: modelFileType,
    ).fromNetwork(downloadUrl, token: huggingFaceToken).install();

    // Inicjalizacja modelu
    _inferenceModel = await FlutterGemma.getActiveModel(
      maxTokens: maxTokens,
      preferredBackend: PreferredBackend.gpu,
      supportImage: isMultimodal,
      maxNumImages: isMultimodal ? 1 : null,
    );

    // Tworzenie nowego czatu dla tego modelu
    _activeChat = await _inferenceModel!.createChat(
      temperature: 0.6,
      topK: 32,
      topP: 0.9,
      tokenBuffer: 512,
      supportImage: isMultimodal,
      modelType: modelType,
      systemInstruction: systemPrompt,
    );

    // Dodawanie historii konwersacji do czatu
    for (final message in replayHistory) {
      if (message.text.trim().isNotEmpty ||
          message.hasImage ||
          message.hasAudio) {
        await _activeChat!.addQueryChunk(message);
      }
    }

    _loadedModelName = modelName;
    _loadedSystemPrompt = systemPrompt;
    _loadedChatId = chatId;

    return true;
  }

  // Generowanie odpowiedzi przez LLM
  Future<void> generateResponse({
    required String userMessage,
    Uint8List? imageBytes,
    required void Function(String token) onToken,
    void Function(String fullResponse)? onComplete,
  }) async {
    if (_inferenceModel == null || _activeChat == null) {
      throw Exception('Model nie jest załadowany');
    }

    if (imageBytes != null && !(_activeChat?.supportsImages ?? false)) {
      if (kIsWeb) {
        throw Exception(
          'Analiza obrazów na web nie jest obecnie obsługiwana przez flutter_gemma.',
        );
      } else {
        throw Exception('Wybrany model nie obsługuje obrazów.');
      }
    }

    // Dodanie wiadomości użytkownika do czatu
    if (imageBytes != null) {
      await _activeChat!.addQueryChunk(
        Message.withImage(
          text: userMessage,
          imageBytes: imageBytes,
          isUser: true,
        ),
      );
    } else {
      await _activeChat!.addQueryChunk(
        Message(text: userMessage, isUser: true),
      );
    }

    final responseBuffer = StringBuffer();

    // Odbieranie odpowiedzi token po tokenie
    await for (final response in _activeChat!.generateChatResponseAsync()) {
      if (response is TextResponse && response.token.isNotEmpty) {
        responseBuffer.write(response.token);
        onToken(response.token);
      }
    }

    // Po zakończeniu generowania wywołujemy onComplete z pełną odpowiedzią
    onComplete?.call(responseBuffer.toString());
  }

  // Zatrzymanie generowania odpowiedzi
  Future<void> stopGeneration() async {
    await _activeChat?.stopGeneration();
  }

  // Zwalnianie modelu i czatu z pamięci
  Future<void> releaseContext() async {
    await _activeChat?.close();
    _activeChat = null;

    await _inferenceModel?.close();
    _inferenceModel = null;
    _loadedModelName = null;
    _loadedSystemPrompt = null;
    _loadedChatId = null;
  }
}
