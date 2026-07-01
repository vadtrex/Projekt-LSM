import '../../domain/entities/llm_model_entity.dart';
import '../../domain/repositories/models_repository.dart';
import '../datasources/models_local_data_source.dart';

// Modele LLM do pobrania
class ModelsRepositoryImpl implements ModelsRepository {
  final ModelsLocalDataSource localDataSource;

  ModelsRepositoryImpl({required this.localDataSource});

  @override
  Future<List<LlmModelEntity>> getAvailableModels() async {
    return [
      LlmModelEntity(
        name: 'Qwen3 0.6B',
        downloadUrl:
            'https://huggingface.co/litert-community/Qwen3-0.6B/resolve/main/Qwen3-0.6B.litertlm',
        description:
            'Qwen3 to 3. generacja dużych modeli językowych z serii Qwen, oferująca kompleksowy zestaw modeli dense oraz modeli typu „mixture-of-experts” (MoE). Dzięki intensywnemu treningowi Qwen3 zapewnia przełomowe postępy w zakresie rozumowania, wykonywania poleceń, zdolności agentów oraz obsługi wielu języków.',
        parameters: '0.6B',
        size: '0.61 GB',
        image: 'assets/qwen.png',
        multimodal: false,
        maxTokens: 1024,
      ),
      LlmModelEntity(
        name: 'Qwen 2.5 1.5B',
        downloadUrl:
            'https://huggingface.co/litert-community/Qwen2.5-1.5B-Instruct/resolve/main/Qwen2.5-1.5B-Instruct_seq128_q8_ekv1280.task',
        description:
            'Qwen 2.5 to 2. generacja dużych modeli językowych Qwen. W ramach Qwen 2.5 udostępniono szereg podstawowych modeli językowych oraz modeli dostosowanych do konkretnych zadań, których liczba parametrów wynosi od 0,5 do 72 miliardów.',
        parameters: '1.5B',
        size: '1.57 GB',
        image: 'assets/qwen.png',
        multimodal: false,
        maxTokens: 1280,
      ),

      LlmModelEntity(
        name: 'Gemma 3 270M',
        downloadUrl:
            'https://huggingface.co/litert-community/gemma-3-270m-it/resolve/main/gemma3-270m-it-q8.task',
        webDownloadUrl:
            'https://huggingface.co/litert-community/gemma-3-270m-it/resolve/main/gemma3-270m-it-q8-web.task',
        description:
            'Gemma to rodzina lekkich, najnowocześniejszych modeli otwartych firmy Google, opartych na tych samych badaniach i technologiach, które wykorzystano do stworzenia modeli Gemini.'
            'Modele Gemma 3 są multimodalne – obsługują dane wejściowe w postaci tekstu i obrazów oraz generują tekstowe wyniki – a ich wagi są otwarte zarówno dla wariantów wstępnie wytrenowanych, jak i wariantów dostrojonych na podstawie instrukcji. Gemma 3 posiada duże okno kontekstowe o rozmiarze 128K, obsługuje ponad 140 języków i jest dostępna w większej liczbie rozmiarów niż poprzednie wersje.',
        parameters: '0.27B',
        size: '0.30 GB',
        requiresHuggingFaceToken: true,
        image: 'assets/gemma.png',
        multimodal: false,
        maxTokens: 1024,
      ),
      LlmModelEntity(
        name: 'Gemma 3 1B',
        downloadUrl:
            'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4.task',
        webDownloadUrl:
            'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4-web.task',
        description:
            'Gemma to rodzina lekkich, najnowocześniejszych modeli otwartych firmy Google, opartych na tych samych badaniach i technologiach, które wykorzystano do stworzenia modeli Gemini.'
            'Modele Gemma 3 są multimodalne – obsługują dane wejściowe w postaci tekstu i obrazów oraz generują tekstowe wyniki – a ich wagi są otwarte zarówno dla wariantów wstępnie wytrenowanych, jak i wariantów dostrojonych na podstawie instrukcji. Gemma 3 posiada duże okno kontekstowe o rozmiarze 128K, obsługuje ponad 140 języków i jest dostępna w większej liczbie rozmiarów niż poprzednie wersje.',
        parameters: '1B',
        size: '0.55 GB',
        requiresHuggingFaceToken: true,
        image: 'assets/gemma.png',
        multimodal: false,
        maxTokens: 1024,
      ),

      LlmModelEntity(
        name: 'Gemma 4 E2B',
        downloadUrl:
            'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm',
        webDownloadUrl:
            'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it-web.task',
        description:
            'Gemma to rodzina otwartych modeli opracowanych przez Google DeepMind. Modele Gemma 4 są multimodalne – przetwarzają dane wejściowe w postaci tekstu i obrazów (a w przypadku mniejszych modeli obsługują również dane audio) oraz generują tekstowe wyniki. Niniejsza wersja zawiera modele o otwartych wagach, zarówno w wersji wstępnie wytrenowanej, jak i dostrojonej pod kątem konkretnych zadań.'
            'Gemma 4 oferuje okno kontekstowe o rozmiarze do 256 tys. tokenów i obsługuje ponad 140 języków. Dzięki architekturze Dense i Mixture-of-Experts (MoE) Gemma 4 doskonale nadaje się do zadań takich jak generowanie tekstu, kodowanie i wnioskowanie. Modele są dostępne w czterech różnych rozmiarach: E2B, E4B, 26B A4B i 31B.',
        parameters: '2B',
        size: '2.0-2.6 GB',
        requiresHuggingFaceToken: true,
        image: 'assets/gemma.png',
        multimodal: true,
        maxTokens: 8192,
      ),
      LlmModelEntity(
        name: 'Gemma 4 E4B',
        downloadUrl:
            'https://huggingface.co/litert-community/gemma-4-E4B-it-litert-lm/resolve/main/gemma-4-E4B-it.litertlm',
        webDownloadUrl:
            'https://huggingface.co/litert-community/gemma-4-E4B-it-litert-lm/resolve/main/gemma-4-E4B-it-web.task',
        description:
            'Gemma to rodzina otwartych modeli opracowanych przez Google DeepMind. Modele Gemma 4 są multimodalne – przetwarzają dane wejściowe w postaci tekstu i obrazów (a w przypadku mniejszych modeli obsługują również dane audio) oraz generują tekstowe wyniki. Niniejsza wersja zawiera modele o otwartych wagach, zarówno w wersji wstępnie wytrenowanej, jak i dostrojonej pod kątem konkretnych zadań.'
            'Gemma 4 oferuje okno kontekstowe o rozmiarze do 256 tys. tokenów i obsługuje ponad 140 języków. Dzięki architekturze Dense i Mixture-of-Experts (MoE) Gemma 4 doskonale nadaje się do zadań takich jak generowanie tekstu, kodowanie i wnioskowanie. Modele są dostępne w czterech różnych rozmiarach: E2B, E4B, 26B A4B i 31B.',
        parameters: '4B',
        size: '3.0-3.5 GB',
        requiresHuggingFaceToken: true,
        image: 'assets/gemma.png',
        multimodal: true,
        maxTokens: 2048,
      ),
    ];
  }

  @override
  Future<String?> getSelectedModelName() =>
      localDataSource.getSelectedModelName();

  @override
  Future<void> saveSelectedModelName(String name) =>
      localDataSource.saveSelectedModelName(name);

  @override
  Future<void> clearSelectedModelName() =>
      localDataSource.clearSelectedModelName();

  @override
  Future<List<String>> getDownloadedModels() =>
      localDataSource.getDownloadedModels();

  @override
  Future<void> markModelAsDownloaded(String name) =>
      localDataSource.markModelAsDownloaded(name);

  @override
  Future<void> deleteDownloadedModel(String name) =>
      localDataSource.deleteDownloadedModel(name);
}
