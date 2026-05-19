import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lm_chat/src/features/chat/presentation/providers/chat_provider.dart';
import 'package:lm_chat/src/features/chat/presentation/providers/message_provider.dart';
import 'package:lm_chat/src/features/chat/presentation/providers/llm_provider.dart';
import 'package:lm_chat/src/features/models/presentation/providers/models_provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  // Kontroler do inputa wiadomości
  final TextEditingController _inputController = TextEditingController();
  // Kontroler do automatycznego scrollowania do najnowszej wiadomości
  final ScrollController _scrollController = ScrollController();
  // ImagePicker do wybierania zdjęć z galerii lub aparatu
  final ImagePicker _imagePicker = ImagePicker();

  // Id aktualnie wybranego czatu (null jeśli nie wybrano żadnego)
  String? _activeChatId;
  // Tymczasowe przechowywanie wybranego zdjęcia przed wysłaniem wiadomości
  Uint8List? _selectedImageBytes;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Funkcja obsługująca wysyłanie wiadomości wraz z ewentualnym zdjęciem
  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    final selectedImageBytes = _selectedImageBytes;

    if (text.isEmpty && selectedImageBytes == null) return;

    final llmStatus = ref.read(llmStatusProvider);
    if (llmStatus.status == LlmStatus.generating ||
        llmStatus.status == LlmStatus.loadingModel) {
      return;
    }

    // Sprawdź wybrany model
    final modelsState = ref.read(modelsNotifierProvider);
    final selectedModel = modelsState.selectedModelName;
    if (selectedModel == null || selectedModel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Najpierw wybierz model w zakładce Modele'),
        ),
      );
      return;
    }

    // Sprawdź czy wybrany model jest pobrany
    if (!modelsState.downloadedModels.contains(selectedModel)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wybrany model nie jest jeszcze pobrany')),
      );
      return;
    }

    // Jeśli nie ma aktywnego czatu, utwórz nowy
    if (_activeChatId == null) {
      final chatNotifier = ref.read(chatNotifierProvider.notifier);
      String title = text.isNotEmpty ? text : 'Zdjęcie';
      title = title.length > 30 ? '${title.substring(0, 30)}...' : title;
      final newChatId = await chatNotifier.createChat(title);
      if (!mounted) return;
      setState(() {
        _activeChatId = newChatId;
      });
    }

    // Wyczyść pole input i zresetuj wybrane zdjęcie
    _inputController.clear();
    _clearSelectedImage();

    // Wyślij wiadomość i rozpocznij generowanie odpowiedzi
    final msgNotifier = ref.read(
      messageNotifierProvider(_activeChatId!).notifier,
    );
    await msgNotifier.sendMessageAndGenerate(
      userMessage: text,
      selectedModelName: selectedModel,
      imageBytes: selectedImageBytes,
    );

    if (!mounted) return;
    _scrollToBottom();
  }

  // Funkcja do wyboru zdjęcia z galerii lub aparatu
  Future<void> _pickImage({
    required ImageSource source,
    required String sourceLabel,
  }) async {
    try {
      // Kompresja zdjęcia
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );

      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      setState(() {
        _selectedImageBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nie udało się dodać zdjęcia ($sourceLabel): $e'),
        ),
      );
    }
  }

  // Funkcja wywołująca galerię do wyboru zdjęcia
  Future<void> _pickImageFromGallery() {
    return _pickImage(source: ImageSource.gallery, sourceLabel: 'galeria');
  }

  // Funkcja wywołująca aparat do zrobienia zdjęcia
  Future<void> _pickImageFromCamera() {
    return _pickImage(source: ImageSource.camera, sourceLabel: 'aparat');
  }

  void _clearSelectedImage() {
    if (!mounted) return;
    setState(() {
      _selectedImageBytes = null;
    });
  }

  void _startNewChat() {
    setState(() {
      _activeChatId = null;
      _inputController.clear();
    });
  }

  void _openChat(String chatId) {
    setState(() {
      _activeChatId = chatId;
    });
  }

  // Funkcja zatrzymująca generowanie odpowiedzi przez LLM
  void _stopGeneration() {
    if (_activeChatId != null) {
      ref
          .read(messageNotifierProvider(_activeChatId!).notifier)
          .stopGeneration();
    }
  }

  // Funkcja do automatycznego scrollowania do najnowszej wiadomości
  void _scrollToBottom() {
    scheduleMicrotask(() {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final llmState = ref.watch(llmStatusProvider);
    final modelsState = ref.watch(modelsNotifierProvider);

    // Automatycznie scrolluj na dół po wygenerowaniu nowych tokenów
    if (_activeChatId != null) {
      ref.listen(messageNotifierProvider(_activeChatId!), (prev, next) {
        _scrollToBottom();
      });
    }

    return Scaffold(
      drawer: isDesktop
          ? null
          : Drawer(
              child: SafeArea(
                child: _ChatHistoryPanel(
                  colorScheme: colorScheme,
                  onChatSelected: _openChat,
                  activeChatId: _activeChatId,
                ),
              ),
            ),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              (modelsState.selectedModelName != null &&
                      modelsState.selectedModelName!.isNotEmpty)
                  ? modelsState.selectedModelName!
                  : 'LM Chat',
            ),
          ],
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          ElevatedButton(
            onPressed: _startNewChat,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Row(
              children: const [
                Icon(Icons.add, size: 18),
                SizedBox(width: 4),
                Text('Nowy czat'),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              if (isDesktop)
                SizedBox(
                  width: 270,
                  child: _ChatHistoryPanel(
                    colorScheme: colorScheme,
                    onChatSelected: _openChat,
                    activeChatId: _activeChatId,
                  ),
                ),
              Expanded(
                child: Column(
                  children: [
                    // Czat
                    Expanded(
                      child: _activeChatId == null
                          ? _EmptyChatView(colorScheme: colorScheme)
                          : _ChatMessagesView(
                              chatId: _activeChatId!,
                              scrollController: _scrollController,
                              llmStatus: llmState.status,
                            ),
                    ),

                    // Błąd inferencji
                    if (llmState.status == LlmStatus.error &&
                        llmState.errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: colorScheme.errorContainer,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 860),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 16,
                                  color: colorScheme.onErrorContainer,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    llmState.errorMessage!,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: colorScheme.onErrorContainer,
                                        ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  onPressed: () {
                                    ref.read(llmStatusProvider.notifier).state =
                                        const LlmInferenceState();
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Pole wprowadzania
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        border: Border(
                          top: BorderSide(color: colorScheme.outlineVariant),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 860),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_selectedImageBytes != null)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: SizedBox(
                                        width: 88,
                                        height: 88,
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Positioned.fill(
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: colorScheme
                                                        .outlineVariant,
                                                  ),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  child: Image.memory(
                                                    _selectedImageBytes!,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              top: -6,
                                              right: -6,
                                              child: Material(
                                                color: colorScheme
                                                    .surfaceContainer,
                                                shape: const CircleBorder(),
                                                elevation: 1,
                                                child: InkWell(
                                                  customBorder:
                                                      const CircleBorder(),
                                                  onTap: _clearSelectedImage,
                                                  child: const Padding(
                                                    padding: EdgeInsets.all(4),
                                                    child: Icon(
                                                      Icons.close_rounded,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        onPressed:
                                            llmState.status ==
                                                LlmStatus.loadingModel
                                            ? null
                                            : _pickImageFromGallery,
                                        icon: const Icon(
                                          Icons.photo_library_outlined,
                                        ),
                                        tooltip: 'Dodaj zdjęcie z galerii',
                                      ),
                                      IconButton(
                                        onPressed:
                                            llmState.status ==
                                                LlmStatus.loadingModel
                                            ? null
                                            : _pickImageFromCamera,
                                        icon: const Icon(
                                          Icons.photo_camera_outlined,
                                        ),
                                        tooltip: 'Zrób zdjęcie aparatem',
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: TextField(
                                          controller: _inputController,
                                          minLines: 1,
                                          maxLines: 6,
                                          textInputAction: TextInputAction.send,
                                          onSubmitted: (_) => _sendMessage(),
                                          enabled:
                                              llmState.status !=
                                              LlmStatus.loadingModel,
                                          decoration: InputDecoration(
                                            hintText: 'Wpisz wiadomość...',
                                            filled: true,
                                            fillColor: colorScheme
                                                .surfaceContainerHigh,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 18,
                                                  vertical: 14,
                                                ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      if (llmState.status ==
                                          LlmStatus.generating)
                                        FloatingActionButton(
                                          onPressed: _stopGeneration,
                                          backgroundColor: colorScheme.error,
                                          foregroundColor: colorScheme.onError,
                                          child: const Icon(Icons.stop_rounded),
                                        )
                                      else
                                        FloatingActionButton(
                                          onPressed: _sendMessage,
                                          child: const Icon(Icons.send_rounded),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Tło pustego czatu
class _EmptyChatView extends StatelessWidget {
  const _EmptyChatView({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Rozpocznij nową rozmowę',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Wpisz wiadomość aby rozpocząć czat z modelem LLM',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

// Widok wiadomości czatu
class _ChatMessagesView extends ConsumerWidget {
  const _ChatMessagesView({
    required this.chatId,
    required this.scrollController,
    required this.llmStatus,
  });

  final String chatId;
  final ScrollController scrollController;
  final LlmStatus llmStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(messageNotifierProvider(chatId));

    return messagesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Błąd: $e')),
      data: (messages) {
        final itemCount =
            messages.length + (llmStatus == LlmStatus.loadingModel ? 1 : 0);

        if (messages.isEmpty && llmStatus != LlmStatus.loadingModel) {
          return const SizedBox.shrink();
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                if (index == messages.length &&
                    llmStatus == LlmStatus.loadingModel) {
                  return const _InfoMessage(text: 'Ładowanie modelu...');
                }

                final msg = messages[index];
                return _Message(
                  isUser: msg.isUser,
                  content: msg.content,
                  imageBytes: msg.imageBytes,
                  isStreaming:
                      !msg.isUser &&
                      index == messages.length - 1 &&
                      llmStatus == LlmStatus.generating,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// Boczny panel z historią czatów i zakładką do wyboru modelu
class _ChatHistoryPanel extends ConsumerWidget {
  const _ChatHistoryPanel({
    required this.colorScheme,
    required this.onChatSelected,
    this.activeChatId,
  });

  final ColorScheme colorScheme;
  final void Function(String chatId) onChatSelected;
  final String? activeChatId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(chatNotifierProvider);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Historia czatów',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          Expanded(
            child: chatsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Błąd: $e')),
              data: (chats) {
                if (chats.isEmpty) {
                  return Center(
                    child: Text(
                      'Brak czatów',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    final isActive = chat.id == activeChatId;
                    return _HistoryTile(
                      title: chat.title,
                      isActive: isActive,
                      onTap: () {
                        onChatSelected(chat.id);
                        // Zamknij drawer na urządzeniach mobilnych
                        Scaffold.maybeOf(context)?.closeDrawer();
                      },
                      onDelete: () {
                        ref
                            .read(chatNotifierProvider.notifier)
                            .deleteChat(chat.id);
                      },
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                ListTile(
                  dense: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: Icon(Icons.smart_toy_outlined),
                  title: Text('Modele'),
                  onTap: () => context.push('/models'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Wiadomości czatu ze streamowaniem i renderowaniem Markdowna
class _Message extends StatelessWidget {
  const _Message({
    required this.isUser,
    required this.content,
    this.imageBytes,
    this.isStreaming = false,
  });
  // Czy wiadomość użytkownika
  final bool isUser;
  // Zawartość wiadomości
  final String content;
  // Ewentualne zdjęcie dołączone do wiadomości
  final Uint8List? imageBytes;
  // Status streamowania wiadomości
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    // Jeśli brak treści i wiadomość jest aktualnie generowana, pokaż wiadomość z informacją o generowaniu
    if (content.isEmpty && isStreaming) {
      return const _InfoMessage(text: 'Generowanie odpowiedzi...');
    }

    final colorScheme = Theme.of(context).colorScheme;
    final hasImage = imageBytes != null && imageBytes!.isNotEmpty;
    final hasText = content.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isUser
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 260,
                          maxHeight: 220,
                        ),
                        child: Image.memory(
                          imageBytes!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  if (hasImage && hasText) const SizedBox(height: 8),
                  if (hasText || isStreaming)
                    isStreaming
                        ? _StreamingMarkdownContent(content: content)
                        : _MarkdownContent(content: content),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Zawartość wiadomości w formacie Markdown
class _MarkdownContent extends StatelessWidget {
  const _MarkdownContent({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    // MarkdownBody z biblioteki flutter_markdown
    return MarkdownBody(
      data: content,
      selectable: true,
      extensionSet: md.ExtensionSet.gitHubFlavored,
      // Obsługa kliknięć w linki poprzez otwieranie w przeglądarce
      onTapLink: (text, href, title) async {
        if (href == null) return;
        final uri = Uri.tryParse(href);
        if (uri == null) return;
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
    );
  }
}

// Wyświetlanie wiadomości z gotowym Markdownem oraz aktualnie generowanym tekstem
class _StreamingMarkdownContent extends StatelessWidget {
  const _StreamingMarkdownContent({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    // Podział treści na już gotowy Markdown oraz aktualnie generowany tekst
    final segments = _StreamingMarkdownSegments.fromContent(content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Renderowanie gotowego Markdowna
        if (segments.renderedMarkdown.isNotEmpty)
          _MarkdownContent(content: segments.renderedMarkdown),
        // Wyświetlanie aktualnie generowanego tekstu wraz z migającym kursorem
        if (segments.pendingText.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: SelectableText(
                  segments.pendingText,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(width: 4),
              const _BlinkingCursor(),
            ],
          )
        // Wyświetlanie samego migającego kursora jeśli nie ma jeszcze żadnego tekstu
        else
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: _BlinkingCursor(),
          ),
      ],
    );
  }
}

// Funkcja do obliczania segmentów Markdowna, które są już gotowe oraz tych, które są aktualnie generowane
class _StreamingMarkdownSegments {
  const _StreamingMarkdownSegments({
    required this.renderedMarkdown,
    required this.pendingText,
  });

  final String renderedMarkdown;
  final String pendingText;

  static _StreamingMarkdownSegments fromContent(String content) {
    if (content.isEmpty) {
      return const _StreamingMarkdownSegments(
        renderedMarkdown: '',
        pendingText: '',
      );
    }

    final normalized = content.replaceAll('\r\n', '\n');
    final lines = normalized.split('\n');

    var inCodeFence = false;
    var renderedLineCount = 0;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('```') || trimmed.startsWith('~~~')) {
        inCodeFence = !inCodeFence;
      }

      final isLastLine = i == lines.length - 1;
      final lineIsComplete = !isLastLine || normalized.endsWith('\n');
      if (lineIsComplete && !inCodeFence) {
        renderedLineCount = i + 1;
      }
    }

    if (renderedLineCount == 0) {
      return _StreamingMarkdownSegments(
        renderedMarkdown: '',
        pendingText: normalized,
      );
    }

    final renderedMarkdown = lines.take(renderedLineCount).join('\n');
    final pendingText = lines.skip(renderedLineCount).join('\n');

    return _StreamingMarkdownSegments(
      renderedMarkdown: renderedMarkdown,
      pendingText: pendingText,
    );
  }
}

// Migający kursor wyświetlany podczas generowania odpowiedzi
class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 2,
        height: 16,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

// Wiadomość z informacją o ładowaniu modelu lub rozpoczęciu generowania odpowiedzi
class _InfoMessage extends StatelessWidget {
  const _InfoMessage({this.text = 'Generowanie odpowiedzi...'});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Text(text),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Kafelek czatu w historii czatów
class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.title,
    required this.onTap,
    required this.onDelete,
    this.isActive = false,
  });

  final String title;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 16, right: 8),
      selected: isActive,
      selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: PopupMenuButton<String>(
        tooltip: '',
        onSelected: (value) {
          if (value == 'delete') {
            onDelete();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Icon(
            Icons.more_vert,
            size: 18,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 18, color: colorScheme.error),
                const SizedBox(width: 8),
                Text('Usuń', style: TextStyle(color: colorScheme.error)),
              ],
            ),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
