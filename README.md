# Documentum

> **AI-powered documentation, project memory, and seamless AI handoffs.**

Documentum is a cross-platform Flutter application (desktop + web) that analyses your codebase and generates production-ready documentation automatically — README, API reference, architecture guide, installation instructions, contributing guidelines, changelog, and smart recommendations — all powered by your choice of free-tier AI provider.

---

## ✨ Features

| Feature | Description |
|---|---|
| **Multi-Agent Documentation** | Seven parallel AI agents each produce a dedicated document (README, API, Architecture, Installation, Contributing, Changelog, Recommendations). |
| **AI Provider Agnostic** | Plug in any of 7 free-tier providers: Gemini, Groq, OpenRouter, NVIDIA NIM, Cerebras, SambaNova, or Hugging Face. |
| **Per-Agent Provider Routing** | Assign a different model to each agent — e.g. run the Architecture agent on Gemini and the Changelog agent on Groq. |
| **Project Brain** | Persistent semantic memory of your project that powers context-aware chat. |
| **AI Chat** | Ask anything about your codebase using the built-in streaming chat interface. |
| **Project Analysis** | Automatic stack detection — language, framework, database, auth system, build system, architecture pattern, and more. |
| **AI Coordination** | Visual dashboard of all running agents with live status and retry tracking. |
| **History** | Full session history with timestamps and per-run document snapshots. |
| **Context File Export** | Export the full project context as a structured file for use in external AI tools. |
| **Semantic Embeddings** | Vector-based project indexing for smarter chat responses (via Gemini's `text-embedding-004`). |
| **Dark / Light / System Theme** | Full Material You theming with per-component overrides. |

---

## 🖼️ Screenshots

> _Add screenshots here once the app is running._

---

## 🏗️ Architecture

```
lib/
├── app.dart                    # App root (MaterialApp.router)
├── main.dart                   # Entry point
├── core/
│   ├── constants/              # App-wide compile-time constants
│   ├── errors/                 # Failure types
│   ├── router/                 # go_router configuration & destinations
│   ├── theme/                  # Color scheme, typography, component themes, tokens
│   └── utils/                  # Cancellation tokens, path safety
├── models/                     # Freezed data models (+ generated .freezed/.g files)
├── providers/                  # Riverpod providers (settings, chat, docs, projects…)
├── repositories/               # Settings & project persistence
├── screens/
│   ├── about/
│   ├── analysis/
│   ├── brain/
│   ├── chat/
│   ├── coordination/
│   ├── dashboard/
│   ├── documentation/
│   ├── history/
│   ├── projects/
│   └── settings/
├── services/
│   ├── ai/                     # Provider implementations (Gemini, Groq, OpenRouter…)
│   ├── embeddings/             # Embedding service
│   ├── export/                 # Context file & document export
│   ├── orchestrator/           # Multi-agent pipeline + prompt builders
│   │   └── agents/             # DocAgent, ReadmeAgent, ApiAgent, ArchitectureAgent…
│   ├── file_scanner_service.dart
│   ├── project_analyzer_service.dart
│   ├── project_brain_service.dart
│   ├── session_tracker_service.dart
│   └── zip_service.dart
└── widgets/                    # Shared widgets (AppShell, UploadArea, MarkdownView…)
```

**State management:** Riverpod (`AsyncNotifierProvider`, `StateNotifierProvider`)  
**Navigation:** go_router with `StatefulShellRoute` (indexed stack)  
**Models:** Freezed + json_serializable  
**AI layer:** Provider-agnostic `AiProvider` interface; concrete adapters per service

See [`ARCHITECTURE.md`](ARCHITECTURE.md) for a full deep-dive.

---

## 🚀 Getting Started

See [`INSTALLATION.md`](INSTALLATION.md) for full setup instructions.

**Quick start:**

```bash
git clone https://github.com/ArsalanKaleem/documentum.git
cd documentum
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d windows   # or macos, linux, chrome
```

Then open **Settings → AI Providers** and add at least one free API key.

---

## 🤖 Supported AI Providers

All providers listed below have a **free tier** with no credit card required.

| Provider | Free Models | Sign Up |
|---|---|---|
| **Gemini** | `gemini-2.5-flash`, `text-embedding-004` | [aistudio.google.com](https://aistudio.google.com) |
| **Groq** | `llama-3.3-70b` (and others) | [console.groq.com](https://console.groq.com) |
| **OpenRouter** | `deepseek/deepseek-r1:free` + many others | [openrouter.ai](https://openrouter.ai) |
| **NVIDIA NIM** | `meta/llama-3.3-70b-instruct` | [build.nvidia.com](https://build.nvidia.com) |
| **Cerebras** | `llama-3.3-70b` | [cloud.cerebras.ai](https://cloud.cerebras.ai) |
| **SambaNova** | `Meta-Llama-3.3-70B-Instruct` | [cloud.sambanova.ai](https://cloud.sambanova.ai) |
| **Hugging Face** | `meta-llama/Llama-3.3-70B-Instruct` | [huggingface.co](https://huggingface.co) |

---

## 📄 Documentation

- [`INSTALLATION.md`](INSTALLATION.md) — Detailed setup for Windows, macOS, Linux, and Web
- [`ARCHITECTURE.md`](ARCHITECTURE.md) — System design, data flow, and component breakdown
- [`API.md`](API.md) — Internal API contracts (AI provider interface, models, services)
- [`CONTRIBUTING.md`](CONTRIBUTING.md) — How to contribute
- [`CHANGELOG.md`](CHANGELOG.md) — Version history

---

## 📜 License

MIT — see [`LICENSE`](LICENSE).

---

## 👤 Author

**Arsalan Kaleem (Somi)**  
Flutter & AI Developer  
[github.com/ArsalanKaleem](https://github.com/ArsalanKaleem)
