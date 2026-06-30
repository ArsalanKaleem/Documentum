# API Reference — Documentum

This document describes the **internal API contracts** of Documentum: the abstract interfaces, key models, and service signatures that form the system's boundaries. This is not an HTTP API — Documentum is a client-side Flutter application that calls third-party AI providers directly.

---

## Table of Contents

1. [AI Provider Interface](#1-ai-provider-interface)
2. [Models](#2-models)
3. [Orchestrator](#3-orchestrator)
4. [Services](#4-services)
5. [Repositories](#5-repositories)
6. [Provider Enums & Constants](#6-provider-enums--constants)

---

## 1. AI Provider Interface

**File:** `lib/services/ai/ai_provider.dart`

All AI back ends implement the same interface. The API key is **never** stored on the provider — it is passed per-call from secure storage.

```dart
abstract interface class AiProvider {
  AiProviderType get type;

  /// One-shot text completion.
  Future<AiCompletion> complete({
    required List<AiMessage> messages,
    required AiProviderConfig config,
    required String apiKey,
  });

  /// Streaming text completion. Yields incremental chunks.
  Stream<String> streamComplete({
    required List<AiMessage> messages,
    required AiProviderConfig config,
    required String apiKey,
  });

  /// Returns embedding vectors for [inputs].
  /// Throws [UnsupportedError] if the provider has no embedding support.
  Future<List<List<double>>> embed({
    required List<String> inputs,
    required AiProviderConfig config,
    required String apiKey,
  });
}
```

### AiMessage

```dart
class AiMessage {
  final String role;    // 'system' | 'user' | 'assistant'
  final String content;

  const AiMessage(this.role, this.content);
  const AiMessage.system(this.content);
  const AiMessage.user(this.content);
  const AiMessage.assistant(this.content);
}
```

### AiCompletion

```dart
class AiCompletion {
  final String text;
  final String providerLabel;
  final int? totalTokens;   // null if the provider does not report usage
}
```

### AiProviderFactory

**File:** `lib/services/ai/ai_provider_factory.dart`

```dart
class AiProviderFactory {
  AiProvider get(AiProviderType type);
}
```

Returns a singleton `AiProvider` instance for the given type. Throws `ArgumentError` for unknown types.

---

## 2. Models

All models are generated with `freezed` + `json_serializable`. Every model exposes `.copyWith()`, `==`, `hashCode`, `.toJson()`, and `.fromJson()`.

### AiProviderConfig

**File:** `lib/models/ai_provider_config.dart`

```dart
@freezed
class AiProviderConfig with _$AiProviderConfig {
  const factory AiProviderConfig({
    required AiProviderType type,
    required String model,
    String? embeddingModel,
    @Default(0.4) double temperature,
    @Default(4096) int maxTokens,
    @Default(true) bool enabled,
  }) = _AiProviderConfig;

  /// Returns tested free-tier defaults for [type].
  static AiProviderConfig defaults(AiProviderType type);
}
```

### AgentProviderConfig

**File:** `lib/models/agent_provider_config.dart`

```dart
@freezed
class AgentProviderConfig with _$AgentProviderConfig {
  const factory AgentProviderConfig({
    @Default({}) Map<String, String> assignments,  // DocType.name → AiProviderType.name
    @Default(false) bool autoMode,
  }) = _AgentProviderConfig;

  /// Returns the [AiProviderType] assigned to [type], or falls back to [fallback].
  AiProviderType providerFor(DocType type, {AiProviderType? fallback});

  /// Returns a new config with [provider] assigned to [type].
  AgentProviderConfig assign(DocType type, AiProviderType provider);
}
```

### ChatMessage

```dart
@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String role,      // 'user' | 'assistant'
    required String content,
    required DateTime timestamp,
  }) = _ChatMessage;
}
```

### GeneratedDoc

```dart
enum GeneratedDocStatus { idle, generating, done, failed, cancelled }

@freezed
class GeneratedDoc with _$GeneratedDoc {
  const factory GeneratedDoc({
    required DocType type,
    @Default(GeneratedDocStatus.idle) GeneratedDocStatus status,
    String? content,
    String? errorMessage,
    String? providerLabel,
    DateTime? completedAt,
  }) = _GeneratedDoc;
}
```

### DocType

```dart
enum DocType {
  readme,
  api,
  architecture,
  installation,
  contributing,
  changelog,
  recommendations,
}
```

### Project

```dart
@freezed
class Project with _$Project {
  const factory Project({
    required String id,
    required String name,
    required String zipPath,
    required DateTime createdAt,
    DateTime? lastAnalysedAt,
    int? fileCount,
    String? detectedLanguage,
    String? detectedFramework,
  }) = _Project;
}
```

### ProjectBrain

```dart
@freezed
class ProjectBrain with _$ProjectBrain {
  const factory ProjectBrain({
    required String projectId,
    @Default([]) List<FileSummary> fileSummaries,
    String? dependencyGraph,
    String? architectureNotes,
    @Default([]) List<QaPair> qaPairs,
    DateTime? builtAt,
  }) = _ProjectBrain;
}
```

### ProjectContext

```dart
@freezed
class ProjectContext with _$ProjectContext {
  const factory ProjectContext({
    required String name,
    required String language,
    required String framework,
    required String database,
    required String apiFramework,
    required String authSystem,
    required String packageManager,
    required String buildSystem,
    required String architecture,
    required List<String> modules,
    required Set<String> technologies,
    required String summary,
    required int fileCount,
    required bool hasGit,
  }) = _ProjectContext;
}
```

### SourceFile

```dart
@freezed
class SourceFile with _$SourceFile {
  const factory SourceFile({
    required String relativePath,
    required String fileName,
    required String extension,
    required String content,    // capped at AppConstants.maxFileContentBytes (64 KB)
  }) = _SourceFile;
}
```

### SessionRecord

```dart
@freezed
class SessionRecord with _$SessionRecord {
  const factory SessionRecord({
    required String id,
    required String projectName,
    required DateTime startedAt,
    DateTime? completedAt,
    @Default([]) List<GeneratedDoc> docs,
  }) = _SessionRecord;
}
```

---

## 3. Orchestrator

**File:** `lib/services/orchestrator/ai_orchestrator.dart`

```dart
typedef ApiKeyReader   = Future<String?> Function(AiProviderType type);
typedef ConfigResolver = AiProviderConfig Function(DocType type);

class AiOrchestrator {
  AiOrchestrator({
    required AiProviderFactory factory,
    required ApiKeyReader apiKeyReader,
    List<DocAgent>? agents,    // defaults to all 7 standard agents
    int maxRetries = 5,
    int staggerMs  = 350,
  });

  List<DocType> get availableDocTypes;

  /// Runs all agents in parallel. Yields a [GeneratedDoc] event as each
  /// agent transitions state. Never throws — failures are embedded in the
  /// stream as [GeneratedDocStatus.failed] events.
  Stream<GeneratedDoc> generateAll({
    required ProjectContext context,
    required List<SourceFile> files,
    required ConfigResolver configFor,
    CancellationToken? cancel,
  });
}
```

### DocAgent interface

```dart
abstract class DocAgent {
  DocType get docType;

  Future<String> generate({
    required ProjectContext context,
    required List<SourceFile> files,
    required AiProvider provider,
    required AiProviderConfig config,
    required String apiKey,
    CancellationToken? cancel,
  });
}
```

---

## 4. Services

### ProjectAnalyzerService

```dart
class ProjectAnalyzerService {
  ProjectAnalyzerService(FileScannerService scanner);

  ProjectContext analyze({
    required String projectName,
    required List<SourceFile> files,
    required bool hasGit,
  });
}
```

### ProjectBrainService

```dart
class ProjectBrainService {
  Future<ProjectBrain> build({
    required ProjectContext context,
    required List<SourceFile> files,
    required AiProvider provider,
    required AiProviderConfig config,
    required String apiKey,
    CancellationToken? cancel,
  });
}
```

### EmbeddingService

```dart
class EmbeddingService {
  Future<void> index({
    required List<SourceFile> files,
    required AiProvider provider,
    required AiProviderConfig config,
    required String apiKey,
  });

  /// Returns the [n] files most semantically similar to [query].
  List<SourceFile> search(String query, {int n = 5});
}
```

### ZipService

```dart
class ZipService {
  /// Extracts [zipBytes] and returns all non-ignored source files.
  /// Throws [FileSizeException] if the archive exceeds [AppConstants.maxZipBytes].
  Future<List<SourceFile>> extract(Uint8List zipBytes, {String? projectName});
}
```

### ExportService

```dart
class ExportService {
  /// Returns the generated document as a UTF-8 Markdown string.
  String toMarkdown(GeneratedDoc doc);

  /// Bundles all [docs] into a ZIP archive and returns the bytes.
  Future<Uint8List> toZip(List<GeneratedDoc> docs, String projectName);
}
```

### ContextFileService

```dart
class ContextFileService {
  /// Builds a structured plain-text context file for use in external AI tools.
  String buildContextFile({
    required ProjectContext context,
    required List<SourceFile> files,
    required List<GeneratedDoc> docs,
  });
}
```

---

## 5. Repositories

### SettingsRepository

```dart
class SettingsRepository {
  Future<AiProviderType>   getActiveProvider();
  Future<void>             setActiveProvider(AiProviderType type);

  Future<AiProviderConfig> getConfig(AiProviderType type);
  Future<void>             saveConfig(AiProviderConfig config);

  Future<bool>             hasApiKey(AiProviderType type);
  Future<void>             setApiKey(AiProviderType type, String key);
  Future<void>             deleteApiKey(AiProviderType type);

  Future<AgentProviderConfig> getAgentConfig();
  Future<void>                saveAgentConfig(AgentProviderConfig config);

  Future<ThemeMode>        getThemeMode();
  Future<void>             saveThemeMode(ThemeMode mode);

  /// Removes stored configs for provider names no longer in [AiProviderType].
  Future<void>             pruneStaleConfigs();
}
```

### ProjectRepository

```dart
class ProjectRepository {
  Future<List<Project>>       listProjects();
  Future<void>                saveProject(Project project);
  Future<void>                deleteProject(String id);

  Future<List<SessionRecord>> listSessions({String? projectId});
  Future<void>                saveSession(SessionRecord record);
  Future<void>                deleteSession(String id);
}
```

---

## 6. Provider Enums & Constants

### AiProviderType

```dart
enum AiProviderType {
  gemini     ('Gemini'),
  groq       ('Groq'),
  openrouter ('OpenRouter'),
  nvidia     ('NVIDIA NIM'),
  cerebras   ('Cerebras'),
  sambanova  ('SambaNova'),
  huggingface('Hugging Face');

  final String label;
}
```

### AppConstants (selected)

```dart
class AppConstants {
  static const String appName    = 'Documentum';
  static const String appVersion = '2.0.0';

  static const int maxZipBytes          = 100 * 1024 * 1024;  // 100 MB
  static const int maxFileContentBytes  = 64  * 1024;          // 64 KB per file
  static const int maxFilesPerPrompt    = 25;

  static const List<String> documentFileNames = [
    'README.md', 'API.md', 'ARCHITECTURE.md',
    'INSTALLATION.md', 'CONTRIBUTING.md', 'CHANGELOG.md',
  ];

  static const Set<String> ignoredDirectories = { 'node_modules', '.git', 'build', ... };
  static const Set<String> ignoredExtensions  = { '.png', '.jpg', '.zip', '.lock', ... };
}
```
