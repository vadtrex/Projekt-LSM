import 'package:shared_preferences/shared_preferences.dart';

abstract class ModelsLocalDataSource {
  Future<String?> getSelectedModelName();
  Future<void> saveSelectedModelName(String name);
  Future<void> clearSelectedModelName();
  Future<List<String>> getDownloadedModels();
  Future<void> markModelAsDownloaded(String name);
  Future<void> deleteDownloadedModel(String name);
  Future<String?> getHuggingFaceToken();
  Future<void> saveHuggingFaceToken(String token);
}

// Implementacja przechowywania informacji o pobranych modelach w SharedPreferences
class ModelsLocalDataSourceImpl implements ModelsLocalDataSource {
  static SharedPreferences? _prefs;

  Future<SharedPreferences> get _getInstance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<String?> getSelectedModelName() async {
    final prefs = await _getInstance;
    return prefs.getString('selected_model');
  }

  @override
  Future<void> saveSelectedModelName(String name) async {
    final prefs = await _getInstance;
    await prefs.setString('selected_model', name);
  }

  @override
  Future<void> clearSelectedModelName() async {
    final prefs = await _getInstance;
    await prefs.remove('selected_model');
  }

  @override
  Future<List<String>> getDownloadedModels() async {
    final prefs = await _getInstance;
    return prefs.getStringList('downloaded_models') ?? [];
  }

  @override
  Future<void> markModelAsDownloaded(String name) async {
    final prefs = await _getInstance;
    final downloaded = await getDownloadedModels();
    if (!downloaded.contains(name)) {
      downloaded.add(name);
      await prefs.setStringList('downloaded_models', downloaded);
    }
  }

  @override
  Future<void> deleteDownloadedModel(String name) async {
    final prefs = await _getInstance;
    final downloaded = await getDownloadedModels();
    if (downloaded.contains(name)) {
      downloaded.remove(name);
      await prefs.setStringList('downloaded_models', downloaded);
    }
  }

  @override
  Future<String?> getHuggingFaceToken() async {
    final prefs = await _getInstance;
    return prefs.getString('huggingface_token');
  }

  @override
  Future<void> saveHuggingFaceToken(String token) async {
    final prefs = await _getInstance;
    if (token.isEmpty) {
      await prefs.remove('huggingface_token');
      return;
    }
    await prefs.setString('huggingface_token', token);
  }
}
