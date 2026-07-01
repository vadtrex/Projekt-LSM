# LM Chat - Lokalny czat z modelami LLM (PL)

![Demo aplikacji](app_recording.gif)

[▶ Obejrzyj demo w wyższej jakości](app_recording.mp4)

## Opis projektu

Projekt to wieloplatformowa aplikacja mobilna i desktopowa napisana we **Flutterze**, umożliwiająca prowadzenie konwersacji z dużymi modelami językowymi (**LLM**) działającymi w pełni lokalnie na urządzeniu użytkownika. Inferencja odbywa się bez połączenia z internetem dzięki bibliotece **flutter_gemma** (opartej o MediaPipe LLM Inference API). Aplikacja obsługuje **6 modeli** z rodzin Qwen i Gemma, w tym warianty multimodalne (tekst i obraz).

Projekt demonstruje kompletną aplikację oferującą: pobieranie modeli z Hugging Face, lokalną inferencję z akceleracją GPU, zarządzanie historią czatów, obsługę obrazów z kamery lub galerii oraz responsywny interfejs użytkownika.

## Główne funkcje

- Lokalna inferencja LLM na urządzeniu (bez chmury) z akceleracją GPU przez **MediaPipe**
- Obsługa **6 modeli**: Qwen3 0.6B, Qwen 2.5 1.5B, Gemma 3 270M, Gemma 3 1B, Gemma 4 E2B, Gemma 4 E4B
- **Modele multimodalne**: Gemma 4 E2B/E4B obsługują obrazy (zdjęcia z galerii lub aparatu)
- Streamowane generowanie odpowiedzi token po tokenie z możliwością zatrzymania
- Zarządzanie stanem za pomocą **Riverpod**
- Trwała historia czatów i wiadomości w lokalnej bazie **Hive**
- Responsywny layout dostosowany do **telefonów, tabletów i komputerów**
- Architektura **Clean Architecture** z podziałem na warstwy domain, data i presentation
- Pobieranie modeli z Hugging Face z postępem i obsługą tokenów dostępu
- Renderowanie odpowiedzi w **Markdown**

## Elementy aplikacji

### 1. Ekran główny - Czat (`features/home/`)

Główny interfejs konwersacji z modelem LLM. Na urządzeniach mobilnych historia czatów dostępna jest przez menu boczne, a na desktopie wyświetlana jest w stałym panelu bocznym. Ekran zawiera: listę wiadomości z renderowaniem Markdown, pole tekstowe z przyciskami galerii i aparatu, przycisk wysyłania/zatrzymywania generowania oraz pasek błędów inferencji.

### 2. Ekran modeli (`features/models/`)

Strona z listą dostępnych modeli LLM. Każdy model prezentowany jest na karcie z opisem, liczbą parametrów, rozmiarem pliku i oznaczeniami (multimodalność, wymóg tokenu HF, dostępność webowa). Umożliwia pobieranie, usuwanie i wybieranie aktywnego modelu. Zawiera również pole do wprowadzenia tokenu Hugging Face (wymagany dla modeli Gemma).

### 3. Serwis inferencji LLM (`chat/data/datasources/llm_inference_service.dart`)

Warstwa komunikacji z silnikiem MediaPipe LLM Inference. Zarządza cyklem życia modelu (ładowanie, zwalnianie), sesją czatu (system prompt, replay historii) oraz generowaniem odpowiedzi w trybie streamowania. Automatycznie rozpoznaje typ modelu i wybiera backend (GPU/CPU).

### 4. Warstwa danych - Hive (`chat/data/`)

Lokalna baza danych oparta o Hive, przechowująca encje czatów (`ChatHiveModel`) i wiadomości (`MessageHiveModel`) z obsługą zdjęć (bajty zapisywane bezpośrednio). Dane są zachowane między sesjami aplikacji.

### 5. Warstwa domeny (`chat/domain/`, `models/domain/`)

Encje domenowe (`ChatEntity`, `MessageEntity`, `LlmModelEntity`), interfejsy repozytoriów i prompt systemowy definiujący osobowość asystenta AI.

## Architektura

Projekt stosuje **Clean Architecture** z wyraźnym podziałem na trzy warstwy:

```
lib/
├── main.dart                          # Punkt wejścia, inicjalizacja Hive i FlutterGemma
├── src/
│   ├── app.dart                       # Konfiguracja MaterialApp, motyw ciemny
│   ├── core/
│   │   └── routing/app_router.dart    # GoRouter - nawigacja między ekranami
│   └── features/
│       ├── chat/                      # Funkcjonalność czatu z LLM
│       │   ├── data/                  # Hive datasource, modele, implementacja repozytorium
│       │   ├── domain/                # Encje, interfejsy repozytoriów, system prompt
│       │   └── presentation/          # Providery Riverpod (chat, message, llm)
│       ├── home/
│       │   └── presentation/          # MainPage - główny ekran czatu z UI
│       └── models/
│           ├── data/                  # Datasource, repozytorium, resolver typów modeli
│           ├── domain/                # Encja modelu LLM, interfejs repozytorium
│           └── presentation/          # ModelsPage - ekran zarządzania modelami
```

## Technologie i biblioteki

- **Flutter**
- **flutter_gemma** - lokalna inferencja LLM
- **flutter_riverpod**- zarządzanie stanem
- **hive** - lokalna baza danych NoSQL
- **shared_preferences** - przechowywanie wybranego modelu i tokenu HF

## Jak uruchomić

1. Upewnij się, że masz zainstalowane Flutter SDK (^3.11.1):
   ```powershell
   flutter --version
   ```
2. Zainstaluj zależności:
   ```powershell
   cd lm_chat
   flutter pub get
   ```
3. Wygeneruj adaptery Hive:
   ```powershell
   dart run build_runner build
   ```
4. Uruchom aplikację na wybranym urządzeniu:
   ```powershell
   flutter run
   ```

**Uwagi:**
- Przy pierwszym uruchomieniu modele pobierane są z Hugging Face (od ~0.3 GB do ~3.5 GB w zależności od modelu).
- Modele Gemma wymagają tokenu Hugging Face - wprowadź go na ekranie **Modele** przed pobraniem.
- Inferencja GPU (MediaPipe) wymaga urządzenia z obsługą OpenCL/GPU. Na emulatorze lub słabszym sprzęcie używany jest fallback na CPU.
- Aplikacja wspiera platformy: **Android**, **iOS**, **Web**, **Windows**, **macOS**, **Linux**.

<br>

# LM Chat - Local LLM Chat Application (EN)

## Project Description

This project is a cross-platform mobile and desktop application built with **Flutter** that enables conversations with large language models (**LLMs**) running entirely on-device. Inference is performed offline using the **flutter_gemma** library (based on MediaPipe LLM Inference API). The application supports **6 models** from the Qwen and Gemma families, including multimodal variants (text and image).

The project demonstrates a complete application offering: downloading models from Hugging Face, local GPU-accelerated inference, chat history management, camera or gallery image handling, and a responsive user interface.

## Main Features

- Fully local on-device LLM inference (no cloud) with GPU acceleration via **MediaPipe**
- Support for **6 models**: Qwen3 0.6B, Qwen 2.5 1.5B, Gemma 3 270M, Gemma 3 1B, Gemma 4 E2B, Gemma 4 E4B
- **Multimodal models**: Gemma 4 E2B/E4B support images (photos from gallery or camera)
- Streamed token-by-token response generation with the ability to stop mid-generation
- State management with **Riverpod**
- Persistent chat and message history in a local **Hive** database
- Responsive layout adapted for **phones, tablets, and desktops**
- **Clean Architecture** with domain, data, and presentation layers
- Model downloading from Hugging Face with progress tracking and access token support
- **Markdown** response rendering

## Application Components

### 1. Main Screen - Chat (`features/home/`)

The primary conversation interface with the LLM. On mobile devices, chat history is accessible via a side menu, while on desktop it is displayed in a fixed side panel. The screen includes: a message list with Markdown rendering, a text input field with gallery and camera buttons, a send/stop generation button, and an inference error bar.

### 2. Models Screen (`features/models/`)

A page listing available LLM models. Each model is presented on a card with its description, parameter count, file size, and badges (multimodality, HF token requirement, web availability). It allows downloading, deleting, and selecting the active model. It also includes a field for entering a Hugging Face token (required for Gemma models).

### 3. LLM Inference Service (`chat/data/datasources/llm_inference_service.dart`)

The communication layer with the MediaPipe LLM Inference engine. It manages the model lifecycle (loading, releasing), chat sessions (system prompt, history replay), and streamed response generation. It automatically detects the model type and selects the backend (GPU/CPU).

### 4. Data Layer - Hive (`chat/data/`)

A local database built on Hive, storing chat entities (`ChatHiveModel`) and message entities (`MessageHiveModel`) with image support (bytes stored directly). Data is preserved across application sessions.

### 5. Domain Layer (`chat/domain/`, `models/domain/`)

Domain entities (`ChatEntity`, `MessageEntity`, `LlmModelEntity`), repository interfaces, and a system prompt defining the AI assistant's personality.

## Architecture

The project follows **Clean Architecture** with a clear separation into three layers:

```
lib/
├── main.dart                          # Entry point, Hive & FlutterGemma initialization
├── src/
│   ├── app.dart                       # MaterialApp config, dark theme
│   ├── core/
│   │   └── routing/app_router.dart    # GoRouter - screen navigation
│   └── features/
│       ├── chat/                      # LLM chat functionality
│       │   ├── data/                  # Hive datasource, models, repository implementation
│       │   ├── domain/                # Entities, repository interfaces, system prompt
│       │   └── presentation/          # Riverpod providers (chat, message, llm)
│       ├── home/
│       │   └── presentation/          # MainPage - main chat screen with UI
│       └── models/
│           ├── data/                  # Datasource, repository, model type resolver
│           ├── domain/                # LLM model entity, repository interface
│           └── presentation/          # ModelsPage - model management screen
```

## Technologies and Libraries

- **Flutter**
- **flutter_gemma** - local LLM inference
- **flutter_riverpod** - state management
- **hive** - local NoSQL database
- **shared_preferences** - storing selected model and HF token

## How to Run

1. Ensure you have Flutter SDK (^3.11.1) installed:
   ```powershell
   flutter --version
   ```
2. Install dependencies:
   ```powershell
   cd lm_chat
   flutter pub get
   ```
3. Generate Hive adapters:
   ```powershell
   dart run build_runner build
   ```
4. Run the application on your target device:
   ```powershell
   flutter run
   ```

**Notes:**
- On first launch, models are downloaded from Hugging Face (from ~0.3 GB to ~3.5 GB depending on the model).
- Gemma models require a Hugging Face token - enter it on the **Models** screen before downloading.
- GPU inference (MediaPipe) requires a device with OpenCL/GPU support. On emulators or weaker hardware, a CPU fallback is used.
- The application supports the following platforms: **Android**, **iOS**, **Web**, **Windows**, **macOS**, **Linux**.

<br>
