# Architecture — Documentum

This document describes the system design, component responsibilities, and data flow of Documentum v2.0.0.

---

## Overview

Documentum is a **Flutter cross-platform application** (desktop + web) that accepts a zipped codebase, analyses its structure and technology stack, and uses a **multi-agent AI pipeline** to produce seven categories of documentation in parallel. All AI communication is provider-agnostic — the same pipeline works across Gemini, Groq, OpenRouter, NVIDIA NIM, Cerebras, SambaNova, and Hugging Face.

---

## High-Level Data Flow

```
User uploads ZIP
      │
      ▼
ZipService.extract()
      │
      ▼
FileScannerService.scan()     ← language histogram, ignored dirs/extensions
      │
      ▼
ProjectAnalyzerService.analyze()
      │  detects: language, framework, database, auth, build system,
      │           architecture pattern, modules
      ▼
ProjectContext (immutable snapshot)
      │
      ├──────────────────────────────────┐
      ▼                                  ▼
AiOrchestrator.generateAll()     ProjectBrainService
      │                                  │
      │  7 agents in parallel            │  semantic index via embeddings
      ▼                                  ▼
[ReadmeAgent, ApiAgent,          EmbeddingService
 ArchitectureAgent,                     │
 InstallationAgent,                     ▼
 ContributingAgent,              vector store (in-memory)
 ChangelogAgent,
 RecommendationsAgent]
      │
      ▼
Stream<GeneratedDoc>  →  UI (CoordinationScreen, DocumentationScreen)
```

---

## Layer Breakdown

### 1. Core

| Module | Purpose |
|---|---|
| `core/constants/app_constants.dart` | Compile-time constants: app name, version, max file sizes, ignored dirs/extensions, document file names. |
| `core/errors/failures.dart` | Typed failure hierarchy used across the service layer. |
| `core/router/app_router.dart` | `GoRouter` with a `StatefulShellRoute` for 10 indexed destinations. |
| `core/theme/` | Material You tokens: color scheme, typography scale, spacing, radius, component-level overrides. |
| `core/utils/cancellation.dart` | `CancellationToken` for cooperative cancellation across async agents. |
| `core/utils/path_safety.dart` | Guards against path traversal in ZIP extraction. |

### 2. Models (Freezed)

All domain models are immutable, generated with `freezed` + `json_serializable`:

| Model | Description |
|---|---|
| `AiProviderConfig` | Runtime config for a provider (model, temperature, max tokens). API key is **not** stored here — only fetched from secure storage at call time. |
| `AgentProviderConfig` | Maps each `DocType` to a specific `AiProviderType`, supporting per-agent provider routing. |
| `ChatMessage` | A single chat turn with role, content, and timestamp. |
| `GeneratedDoc` | One generated document: type, content, status (`idle / generating / done / failed / cancelled`), assigned provider label. |
| `Project` | A saved project: name, path, timestamps, and metadata. |
| `ProjectBrain` | Semantic memory: file summaries, dependency graph, architecture notes, Q&A pairs. |
| `ProjectContext` | The full analysed snapshot: language, framework, database, auth system, build system, architecture, modules, file count, summary. |
| `SessionRecord` | Historical record of a documentation run: project name, timestamp, list of `GeneratedDoc`. |
| `SourceFile` | A single extracted file: relative path, file name, extension, content (capped at 64 KB). |

### 3. Services

#### AI Layer (`services/ai/`)

```
AiProvider (abstract interface)
    ├── complete()        → AiCompletion
    ├── streamComplete()  → Stream<String>
    └── embed()           → List<List<double>>

Implementations:
    GeminiProvider
    GroqProvider
    OpenAiProvider        ← also used for OpenRouter, NVIDIA, Cerebras, SambaNova
    HuggingFaceProvider
    OpenRouterProvider
    NvidiaProvider
    CerebrasProvider
    SambanovaProvider

AiProviderFactory         ← resolves AiProviderType → AiProvider instance
```

Every implementation handles its own HTTP calls, streaming, error parsing, and rate-limit detection. The interface guarantees that the orchestrator never imports a concrete class.

#### Orchestrator (`services/orchestrator/`)

`AiOrchestrator` is the central coordinator:

- Accepts a `ProjectContext`, a list of `SourceFile`, and a `ConfigResolver` (maps `DocType → AiProviderConfig`).
- Emits an initial `GeneratedDoc(status: generating)` for every agent so the UI renders a full roster immediately.
- Launches all agents **in parallel** with a configurable stagger delay (`staggerMs`, default 350 ms) to smooth bursts against free-tier rate limits.
- Each agent has independent retry logic (`maxRetries`, default 5) with exponential back-off.
- One agent failing never affects others.
- A `CancellationToken` allows the user to abort mid-run; each agent checks it before each retry.

**Agents:**

| Agent | DocType | Document produced |
|---|---|---|
| `ReadmeAgent` | `readme` | Project README |
| `ApiAgent` | `api` | API reference |
| `ArchitectureAgent` | `architecture` | Architecture guide |
| `InstallationAgent` | `installation` | Installation instructions |
| `ContributingAgent` | `contributing` | Contributing guidelines |
| `ChangelogAgent` | `changelog` | Changelog |
| `RecommendationsAgent` | `recommendations` | Improvement recommendations |

`PromptBuilder` constructs the system + user prompt for each agent from the `ProjectContext` and selected source files (capped at `AppConstants.maxFilesPerPrompt = 25`).

#### Project Analysis (`services/project_analyzer_service.dart`)

Stateless analysis run once per project:

- `FileScannerService` scans all `SourceFile`s and builds a language histogram.
- `ProjectAnalyzerService` uses file names, paths, and content heuristics to detect: language, framework, database, API framework, auth system, build system, architecture pattern, and top-level modules.
- Output is an immutable `ProjectContext` shared by all downstream services.

#### Project Brain (`services/project_brain_service.dart`)

- Generates per-file summaries via the active AI provider.
- Builds a dependency graph and architecture notes.
- Feeds the `EmbeddingService` to create a vector index for semantic search.
- Powers the chat screen's context-aware responses.

#### Embeddings (`services/embeddings/embedding_service.dart`)

- Calls the provider's `embed()` method (Gemini `text-embedding-004` by default).
- Stores vectors in memory for the session.
- Falls back to lexical indexing if the provider does not support embeddings.

#### Export (`services/export/`)

- `ExportService` — serialises generated documents to Markdown files, optionally zipped.
- `ContextFileService` — builds a structured context file (all project metadata + source) for external AI tool handoffs.

### 4. Repositories

| Repository | Storage backend | Responsibility |
|---|---|---|
| `SettingsRepository` | `flutter_secure_storage` (API keys) + `shared_preferences` (config) | API keys, active provider, per-provider config, agent routing config, theme mode. |
| `ProjectRepository` | Local file system | Saved project list, session history. |

### 5. Providers (Riverpod)

| Provider | Type | Description |
|---|---|---|
| `settingsProvider` | `AsyncNotifierProvider` | Global settings state; exposes `SettingsState` with `hasActiveKey`, `hasKeyForAgent()`. |
| `projectProvider` | — | Current project and its source files. |
| `chatProvider` | — | Chat history and streaming. |
| `coordinationProvider` | — | Agent run state (list of `GeneratedDoc` with live status). |
| `documentationProvider` | — | Final docs after a completed run. |
| `serviceProviders` | — | Singleton service instances (`ZipService`, `FileScannerService`, etc.) |

### 6. Screens

| Screen | Route | Purpose |
|---|---|---|
| `DashboardScreen` | `/` | Overview: project stats, quick actions. |
| `ProjectsScreen` | `/projects` | Project list, upload new project. |
| `AnalysisScreen` | `/analysis` | Detected stack details, file breakdown. |
| `DocumentationScreen` | `/docs` | View / export all generated documents. |
| `CoordinationScreen` | `/coordination` | Live agent coordination dashboard. |
| `ProjectBrainScreen` | `/brain` | Semantic memory explorer. |
| `ChatScreen` | `/chat` | AI chat with project context. |
| `HistoryScreen` | `/history` | Past session records. |
| `SettingsScreen` | `/settings` | Provider keys, model config, agent routing, theme. |
| `AboutScreen` | `/about` | App info, developer card. |

---

## Key Design Decisions

**Why provider-agnostic AI?**  
Free-tier rate limits are the primary constraint for individual developers. Routing different agents to different providers (all free) multiplies the effective quota.

**Why Freezed models?**  
Deep equality, `copyWith`, and JSON serialisation with zero boilerplate. Essential for Riverpod's `AsyncData` diffing.

**Why `StatefulShellRoute`?**  
Each destination retains its scroll position and widget state independently — required for the coordination screen, which streams live updates that must not be discarded on navigation.

**Why cap source files at 25 and content at 64 KB?**  
Token budgets. Even the most generous free-tier context windows (Gemini 2.5 Flash: 1M tokens) are finite, and sending all files verbatim would produce slow, expensive, and often worse outputs than a well-curated subset.

---

## Supported Platforms

| Platform | Status |
|---|---|
| Windows | ✅ |
| macOS | ✅ |
| Linux | ✅ |
| Web (Chrome) | ✅ |
| Android / iOS | ⚠️ File picker and secure storage work; ZIP extraction has filesystem constraints — not officially tested. |
