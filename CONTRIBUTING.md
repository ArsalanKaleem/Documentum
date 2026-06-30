# Contributing to Documentum

Thank you for your interest in contributing! This document explains how to get set up, the coding conventions used in the project, and how to submit changes.

---

## Table of Contents

1. [Getting Started](#1-getting-started)
2. [Project Structure](#2-project-structure)
3. [Coding Conventions](#3-coding-conventions)
4. [Adding a New AI Provider](#4-adding-a-new-ai-provider)
5. [Adding a New Agent / Document Type](#5-adding-a-new-agent--document-type)
6. [Submitting a Pull Request](#6-submitting-a-pull-request)
7. [Reporting Issues](#7-reporting-issues)

---

## 1. Getting Started

Follow the [Installation Guide](INSTALLATION.md) to get the app running locally.

Before you start:

```bash
# Verify your environment
flutter doctor

# Install dependencies
flutter pub get

# Generate Freezed / JSON code
dart run build_runner build --delete-conflicting-outputs

# Run tests
flutter test
```

---

## 2. Project Structure

```
lib/
├── core/         ← constants, errors, router, theme, utils
├── models/       ← immutable Freezed data models
├── providers/    ← Riverpod providers
├── repositories/ ← persistence (settings, projects)
├── screens/      ← one folder per screen
├── services/
│   ├── ai/           ← AiProvider interface + implementations
│   ├── embeddings/
│   ├── export/
│   └── orchestrator/ ← AiOrchestrator + agents + prompt builders
└── widgets/      ← shared widgets
```

See [`ARCHITECTURE.md`](ARCHITECTURE.md) for a full breakdown.

---

## 3. Coding Conventions

### General

- Follow the [Dart style guide](https://dart.dev/guides/language/effective-dart/style).
- Run `dart format .` before committing.
- Run `dart analyze` and resolve all errors and warnings.

### Models

- Use `@freezed` for all data models.
- Never store API keys in a model — they live only in `flutter_secure_storage`.
- After editing a `@freezed` class, re-run `build_runner`:
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```

### State

- All state goes through Riverpod providers.
- Prefer `AsyncNotifierProvider` for async state; avoid bare `StateProvider` for complex state.
- Providers must never import each other's implementation files directly — use the provider reference (`ref.read(...)`) only.

### AI providers

- Never call a provider directly from a screen or widget.
- All AI calls go through `AiOrchestrator` or a service that wraps it.
- API keys are always fetched from `SettingsRepository` at call time — never cached in memory beyond a single call.

### UI

- Use the design tokens from `core/theme/` (e.g. `Spacing.lg`, `AppRadius.md`).
- Do not hardcode hex colours — use `Theme.of(context).colorScheme`.
- Keep screen widgets thin: logic belongs in providers or services.

---

## 4. Adding a New AI Provider

1. Add the new value to the `AiProviderType` enum in `lib/models/ai_provider_config.dart`.

2. Add a `defaults()` case for the new type in the same file.

3. Create `lib/services/ai/<name>_provider.dart` implementing `AiProvider`:

   ```dart
   class MyNewProvider implements AiProvider {
     @override
     AiProviderType get type => AiProviderType.mynew;

     @override
     Future<AiCompletion> complete({ ... }) async { ... }

     @override
     Stream<String> streamComplete({ ... }) async* { ... }

     @override
     Future<List<List<double>>> embed({ ... }) {
       throw UnsupportedError('MyNew does not support embeddings');
     }
   }
   ```

4. Register the new provider in `AiProviderFactory.get()`.

5. Add the provider's UI card in `SettingsScreen` (follow the pattern of an existing card).

6. Run `dart run build_runner build --delete-conflicting-outputs` to regenerate the Freezed files for the updated enum.

---

## 5. Adding a New Agent / Document Type

1. Add the new value to `DocType` in `lib/models/generated_doc.dart`.

2. Create `lib/services/orchestrator/agents/<name>_agent.dart`:

   ```dart
   class MyDocAgent extends DocAgent {
     @override
     DocType get docType => DocType.myDoc;

     @override
     Future<String> generate({ required ProjectContext context, ... }) async {
       final prompt = PromptBuilder.buildFor(docType, context, files);
       final result = await provider.complete(messages: prompt, config: config, apiKey: apiKey);
       return result.text;
     }
   }
   ```

3. Add the agent to `AiOrchestrator.defaultAgents()`.

4. Add the new `DocType` to `AppConstants.documentFileNames` if it should be exported as a Markdown file.

5. Update the Documentation screen to render the new document type.

---

## 6. Submitting a Pull Request

1. **Fork** the repository and create a feature branch:
   ```bash
   git checkout -b feature/my-feature
   ```

2. Make your changes, following the conventions above.

3. Ensure all tests pass:
   ```bash
   flutter test
   dart analyze
   dart format --set-exit-if-changed .
   ```

4. Write a clear PR description explaining:
   - What the change does
   - Why it is needed
   - Any trade-offs or known limitations

5. Open a pull request against the `main` branch.

### Commit message format

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add Cerebras provider
fix: correct rate-limit retry logic in orchestrator
docs: update ARCHITECTURE with embedding service detail
chore: upgrade flutter_secure_storage to 9.2.0
```

---

## 7. Reporting Issues

Please open a [GitHub Issue](https://github.com/ArsalanKaleem/documentum/issues) with:

- A clear title
- Steps to reproduce
- Expected vs. actual behaviour
- Flutter version (`flutter --version`) and platform (Windows / macOS / Linux / Web)
- Any relevant error output or logs

---

Thank you for contributing! 🚀
