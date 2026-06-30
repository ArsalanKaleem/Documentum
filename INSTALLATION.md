# Installation — Documentum

## Prerequisites

| Requirement | Version | Notes |
|---|---|---|
| Flutter SDK | ≥ 3.22.0 | Stable channel recommended |
| Dart SDK | ≥ 3.4.0 | Bundled with Flutter |
| Git | any | For cloning the repo |
| A free AI API key | — | At least one provider required — see below |

### Platform-specific requirements

**Windows:** Visual Studio 2022 with the **Desktop development with C++** workload.  
**macOS:** Xcode 15+ with command-line tools (`xcode-select --install`).  
**Linux:** `clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`.  
**Web:** Chrome (or any Chromium browser).

---

## 1. Clone the Repository

```bash
git clone https://github.com/ArsalanKaleem/documentum.git
cd documentum
```

---

## 2. Install Dependencies

```bash
flutter pub get
```

---

## 3. Generate Code

Documentum uses `freezed` and `json_serializable` for its data models. Run the code generator before the first build:

```bash
dart run build_runner build --delete-conflicting-outputs
```

> **Note:** You only need to re-run this if you modify any file annotated with `@freezed` or `@JsonSerializable`.

---

## 4. Run the App

### Desktop (Windows)

```bash
flutter run -d windows
```

### Desktop (macOS)

```bash
flutter run -d macos
```

### Desktop (Linux)

```bash
flutter run -d linux
```

### Web

```bash
flutter run -d chrome
```

### Release Build

```bash
# Windows
flutter build windows

# macOS
flutter build macos

# Linux
flutter build linux

# Web
flutter build web
```

---

## 5. Configure an AI Provider

Documentum ships with **no API keys**. On first launch:

1. Open **Settings** (gear icon in the sidebar).
2. Go to **AI Providers**.
3. Select a provider and paste your API key.
4. Click **Save**.

All keys are stored in the OS secure keychain via `flutter_secure_storage` — they are never written to disk in plain text.

### Getting a free API key

| Provider | URL | Free limit |
|---|---|---|
| Gemini | https://aistudio.google.com/app/apikey | 15 req/min, 1M tokens/min |
| Groq | https://console.groq.com/keys | 30 req/min |
| OpenRouter | https://openrouter.ai/settings/keys | Free models available |
| NVIDIA NIM | https://build.nvidia.com | 1,000 free credits |
| Cerebras | https://cloud.cerebras.ai | 60 req/min |
| SambaNova | https://cloud.sambanova.ai | Free tier |
| Hugging Face | https://huggingface.co/settings/tokens | Free Inference API |

---

## 6. Optional: Configure Per-Agent Provider Routing

By default, all agents use the same active provider. To assign different providers to different document types:

1. Open **Settings → Agent Routing**.
2. For each document type (README, API, Architecture…), select the provider to use.
3. Optionally enable **Auto Mode** to let the app choose the least-loaded provider.

---

## Troubleshooting

### `build_runner` fails with version conflicts

```bash
flutter pub upgrade
dart run build_runner build --delete-conflicting-outputs
```

### Windows: CMake / C++ build errors

Ensure the **Desktop development with C++** workload is installed in Visual Studio. Run:

```bash
flutter doctor
```

and address any reported issues.

### `flutter_secure_storage` errors on Linux

Install the required system library:

```bash
sudo apt-get install libsecret-1-dev
```

### API key not saving

On Linux, `flutter_secure_storage` requires a running keyring daemon (GNOME Keyring or KWallet). If neither is running, the app falls back to plain `shared_preferences` with a warning.

### Large ZIP files hang on extraction

The ZIP is processed entirely in memory. ZIPs larger than **100 MB** are rejected with an error. Split large repositories or exclude `node_modules` / `build` directories before zipping.

---

## Directory Structure After Setup

```
documentum/
├── lib/            ← Flutter source (from the uploaded lib.zip)
├── test/           ← Unit and widget tests
├── windows/        ← Windows runner
├── macos/          ← macOS runner
├── linux/          ← Linux runner
├── web/            ← Web entry point
├── assets/         ← Images, fonts
├── pubspec.yaml    ← Dependencies
└── ...
```
