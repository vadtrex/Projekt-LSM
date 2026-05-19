import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/models_provider.dart';

// Strona z modelami LLM do pobrania i wyboru
class ModelsPage extends ConsumerStatefulWidget {
  const ModelsPage({super.key});

  @override
  ConsumerState<ModelsPage> createState() => _ModelsPageState();
}

class _ModelsPageState extends ConsumerState<ModelsPage> {
  late final TextEditingController _hfTokenController;

  @override
  void initState() {
    super.initState();
    final initialToken = ref.read(modelsNotifierProvider).huggingFaceToken;
    _hfTokenController = TextEditingController(text: initialToken);
  }

  @override
  void dispose() {
    _hfTokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(modelsNotifierProvider);
    final notifier = ref.read(modelsNotifierProvider.notifier);

    ref.listen(
      modelsNotifierProvider.select((state) => state.huggingFaceToken),
      (previous, next) {
        if (_hfTokenController.text != next) {
          _hfTokenController.text = next;
        }
      },
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Modele')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: state.models.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Token Hugging Face',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _hfTokenController,
                          autocorrect: false,
                          enableSuggestions: false,
                          obscureText: true,
                          decoration: const InputDecoration(
                            hintText: 'hf_... (opcjonalnie)',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: notifier.setHuggingFaceToken,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Token jest używany do pobierania modeli wymagających uzyskania dostępu, np. Gemma 4 E4B.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          }

          final modelIndex = index - 1;
          final model = state.models[modelIndex];
          final name = model.name;
          final downloadUrl = model.downloadUrl;
          final description = model.description;
          final parameters = model.parameters;
          final size = model.size;
          final image = model.image;
          final requiresHuggingFaceToken = model.requiresHuggingFaceToken;

          final isDownloaded = state.downloadedModels.contains(name);
          final isSelected = state.selectedModelName == name;
          final isDownloading = state.isDownloading[name] == true;
          final progress = state.downloadProgress[name] ?? 0.0;
          final isWebUnavailable = kIsWeb && model.webDownloadUrl == null;

          return Card(
            clipBehavior: Clip.antiAlias,
            elevation: isSelected ? 4 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: Image.asset(
                            image,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            isAntiAlias: true,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.smart_toy, size: 30),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isDownloaded
                                  ? 'Pobrany'
                                  : isDownloading
                                  ? 'Pobieranie... ${(progress * 100).toStringAsFixed(1)}%'
                                  : 'Do pobrania',
                              style: TextStyle(
                                color: isDownloaded
                                    ? Colors.green.shade700
                                    : isDownloading
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.outline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (isDownloading) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: progress > 0 ? progress : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.memory, size: 16),
                        label: Text('$parameters parametrów'),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        side: BorderSide.none,
                      ),
                      Chip(
                        avatar: const Icon(Icons.storage, size: 16),
                        label: Text(size),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        side: BorderSide.none,
                      ),
                      if (requiresHuggingFaceToken)
                        Chip(
                          avatar: const Icon(Icons.lock_outline, size: 16),
                          label: const Text('Wymaga tokenu Hugging Face'),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          side: BorderSide.none,
                        ),
                      if (isWebUnavailable)
                        Chip(
                          avatar: const Icon(Icons.public_off, size: 16),
                          label: const Text('Niedostępny w wersji webowej'),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          side: BorderSide.none,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isDownloaded) ...[
                        IconButton(
                          onPressed: () async {
                            try {
                              await ref
                                  .read(modelsNotifierProvider.notifier)
                                  .deleteModel(name, downloadUrl);
                            } catch (error) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error.toString())),
                              );
                            }
                          },
                          icon: Icon(
                            Icons.delete_outline,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          tooltip: 'Usuń model',
                        ),
                        const SizedBox(width: 8),
                        if (isSelected)
                          FilledButton.icon(
                            onPressed: () {
                              ref
                                  .read(modelsNotifierProvider.notifier)
                                  .unselectModel();
                            },
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Wybrany'),
                          )
                        else
                          OutlinedButton(
                            onPressed: () {
                              ref
                                  .read(modelsNotifierProvider.notifier)
                                  .selectModel(name);
                            },
                            child: const Text('Wybierz'),
                          ),
                      ] else if (isDownloading)
                        FilledButton.tonalIcon(
                          onPressed: () {
                            ref
                                .read(modelsNotifierProvider.notifier)
                                .cancelDownload(name);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.errorContainer,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                          icon: const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          label: const Text('Anuluj'),
                        )
                      else
                        FilledButton.tonalIcon(
                          onPressed: isWebUnavailable
                              ? null
                              : () async {
                                  try {
                                    await ref
                                        .read(modelsNotifierProvider.notifier)
                                        .downloadModel(
                                          name,
                                          downloadUrl,
                                          requiresHuggingFaceToken:
                                              requiresHuggingFaceToken,
                                          webUrl: model.webDownloadUrl,
                                        );
                                  } catch (error) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(error.toString())),
                                    );
                                  }
                                },
                          icon: const Icon(Icons.download),
                          label: Text(
                            isWebUnavailable ? 'Niedostępny' : 'Pobierz',
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
