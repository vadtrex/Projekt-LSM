import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/domain/download_exception.dart';
import 'package:flutter_gemma/core/domain/download_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../domain/entities/llm_model_entity.dart';
import '../../domain/repositories/models_repository.dart';
import '../../data/datasources/models_local_data_source.dart';
import '../../data/repositories/models_repository_impl.dart';
import '../../data/utils/model_type_resolver.dart';

final modelsLocalDataSourceProvider = Provider<ModelsLocalDataSource>((ref) {
  return ModelsLocalDataSourceImpl();
});

final modelsRepositoryProvider = Provider<ModelsRepository>((ref) {
  final dataSource = ref.watch(modelsLocalDataSourceProvider);
  return ModelsRepositoryImpl(localDataSource: dataSource);
});

// Stan przechowujący informacje o dostępnych modelach, wybranym modelu oraz postępach pobierania.
class ModelsState {
  final List<LlmModelEntity> models;
  final String? selectedModelName;
  final List<String> downloadedModels;
  final Map<String, double> downloadProgress;
  final Map<String, bool> isDownloading;
  final String huggingFaceToken;

  ModelsState({
    this.models = const [],
    this.selectedModelName,
    this.downloadedModels = const [],
    this.downloadProgress = const {},
    this.isDownloading = const {},
    this.huggingFaceToken = '',
  });

  ModelsState copyWith({
    List<LlmModelEntity>? models,
    String? Function()? selectedModelName,
    List<String>? downloadedModels,
    Map<String, double>? downloadProgress,
    Map<String, bool>? isDownloading,
    String? huggingFaceToken,
  }) {
    return ModelsState(
      models: models ?? this.models,
      selectedModelName: selectedModelName != null
          ? selectedModelName()
          : this.selectedModelName,
      downloadedModels: downloadedModels ?? this.downloadedModels,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      isDownloading: isDownloading ?? this.isDownloading,
      huggingFaceToken: huggingFaceToken ?? this.huggingFaceToken,
    );
  }
}

// Notifier zarządzający stanem modeli, w tym ich pobieraniem, usuwaniem i wybieraniem.
class ModelsNotifier extends StateNotifier<ModelsState> {
  final ModelsRepository _repository;
  final ModelsLocalDataSource _localDataSource;

  // Aktywne tokeny do anulowania pobierania dla modeli (kluczem jest nazwa modelu).
  final Map<String, CancelToken> _cancelTokens = {};

  ModelsNotifier(this._repository, this._localDataSource)
    : super(ModelsState()) {
    _init();
  }

  Future<void> _init() async {
    // Wczytanie dostępnych modeli, wybranego modelu i tokenu Hugging Face
    final available = await _repository.getAvailableModels();
    final selected = await _repository.getSelectedModelName();
    final huggingFaceToken = await _localDataSource.getHuggingFaceToken();

    // Sprawdzenie, które modele są już zainstalowane i aktualizacja stanu.
    final downloaded = await _detectInstalledModels(available);

    state = state.copyWith(
      models: available,
      selectedModelName: () => selected,
      downloadedModels: downloaded,
      huggingFaceToken: huggingFaceToken ?? '',
    );
  }

  // Funkcja do sprawdzania, które modele są już zainstalowane
  Future<List<String>> _detectInstalledModels(
    List<LlmModelEntity> models,
  ) async {
    final downloaded = <String>[];
    for (final model in models) {
      try {
        final isInstalled = await FlutterGemma.isModelInstalled(
          _modelFileNameFromUrl(model.downloadUrl),
        );
        if (isInstalled) downloaded.add(model.name);
      } catch (_) {
        // Jeśli sprawdzanie nie powiedzie się, to traktujemy jako niezainstalowany.
      }
    }
    // Uzupełniamy o modele zapisane w SharedPreferences
    final savedDownloaded = await _repository.getDownloadedModels();
    return {...downloaded, ...savedDownloaded}.toList();
  }

  // Funkcja zwracająca nazwę pliku modelu (używaną jako identyfikator w flutter_gemma).
  String _modelFileNameFromUrl(String downloadUrl) {
    return p.basename(Uri.parse(downloadUrl).path);
  }

  // Zapisywanie i aktualizacja tokenu Hugging Face
  Future<void> setHuggingFaceToken(String token) async {
    await _localDataSource.saveHuggingFaceToken(token);
    state = state.copyWith(huggingFaceToken: token);
  }

  // Wybór modelu
  Future<void> selectModel(String name) async {
    await _repository.saveSelectedModelName(name);
    state = state.copyWith(selectedModelName: () => name);
  }

  // Usunięcie wyboru modelu
  Future<void> unselectModel() async {
    await _repository.clearSelectedModelName();
    state = state.copyWith(selectedModelName: () => null);
  }

  // Aktualizacja postępu pobierania dla danego modelu
  void updateProgress(String name, double progress) {
    state = state.copyWith(
      downloadProgress: {...state.downloadProgress, name: progress},
    );
  }

  // Funkcja pobierająca model z linku
  Future<void> downloadModel(
    String name,
    String url, {
    bool requiresHuggingFaceToken = false,
    String? webUrl,
  }) async {
    final token = state.huggingFaceToken.trim();
    if (requiresHuggingFaceToken && token.isEmpty) {
      throw Exception(
        'Model $name wymaga tokenu Hugging Face. Uzupełnij pole tokenu i spróbuj ponownie.',
      );
    }

    // Modele bez webDownloadUrl nie są dostępne na Web
    if (kIsWeb && webUrl == null) {
      throw Exception(
        'Model $name nie jest dostępny na platformie Web. '
        'Użyj wersji mobilnej lub desktopowej aplikacji.',
      );
    }

    final downloadUrl = kIsWeb ? webUrl! : url;

    state = state.copyWith(
      isDownloading: {...state.isDownloading, name: true},
      downloadProgress: {...state.downloadProgress, name: 0.0},
    );

    final cancelToken = CancelToken();
    _cancelTokens[name] = cancelToken;

    try {
      await FlutterGemma.installModel(
            modelType: resolveModelType(name),
            fileType: resolveModelFileType(downloadUrl),
          )
          .fromNetwork(
            downloadUrl,
            token: requiresHuggingFaceToken ? token : null,
          )
          .withCancelToken(cancelToken)
          .withProgress((progress) {
            updateProgress(name, progress / 100.0);
          })
          .install();

      // Pobieranie zakończone sukcesem
      await _repository.markModelAsDownloaded(name);
      final downloaded = await _repository.getDownloadedModels();
      state = state.copyWith(
        isDownloading: {...state.isDownloading, name: false},
        downloadedModels: downloaded,
      );
    } catch (e) {
      final finishedProgress = Map<String, double>.from(state.downloadProgress)
        ..remove(name);
      state = state.copyWith(
        isDownloading: {...state.isDownloading, name: false},
        downloadProgress: finishedProgress,
      );

      // Anulowanie przez CancelToken (przez użytkownika)
      if (CancelToken.isCancel(e)) {
        return;
      }
      if (e is DownloadException && e.error is CanceledError) {
        return;
      }
      throw Exception('Pobieranie modelu $name nie powiodło się: $e');
    } finally {
      _cancelTokens.remove(name);
    }
  }

  // Anulowanie trwającego pobierania modelu
  Future<void> cancelDownload(String name) async {
    _cancelTokens[name]?.cancel('Anulowano przez użytkownika');
  }

  // Usunięcie pobranego modelu
  Future<void> deleteModel(String name, String downloadUrl) async {
    Exception? caughtError;
    try {
      await FlutterGemma.uninstallModel(_modelFileNameFromUrl(downloadUrl));
    } catch (e) {
      caughtError = Exception('Nie udało się usunąć pliku modelu "$name": $e');
    }

    await _repository.deleteDownloadedModel(name);

    if (state.selectedModelName == name) {
      await _repository.clearSelectedModelName();
    }

    final downloaded = await _repository.getDownloadedModels();

    state = state.copyWith(
      downloadedModels: downloaded,
      selectedModelName: state.selectedModelName == name ? () => null : null,
    );

    if (caughtError != null) throw caughtError;
  }
}

final modelsNotifierProvider =
    StateNotifierProvider<ModelsNotifier, ModelsState>((ref) {
      final repository = ref.watch(modelsRepositoryProvider);
      final localDataSource = ref.watch(modelsLocalDataSourceProvider);
      return ModelsNotifier(repository, localDataSource);
    });
