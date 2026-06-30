# Changelog

All notable changes to Documentum are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Documentum uses [Semantic Versioning](https://semver.org/).

---

## [2.0.0] — 2026-06-29

### Added

- **Multi-agent parallel documentation pipeline** — seven independent agents (README, API, Architecture, Installation, Contributing, Changelog, Recommendations) run concurrently, each on its own provider/model.
- **Per-agent provider routing** — assign different free-tier AI providers to each document type via `AgentProviderConfig`.
- **Five new free-tier AI providers** — NVIDIA NIM, Cerebras, SambaNova, Hugging Face, and OpenRouter added alongside Gemini and Groq (OpenAI and DeepSeek removed as paid-only).
- **Project Brain** — persistent semantic memory of the project, built from per-file AI summaries, dependency graph, and architecture notes.
- **Semantic embeddings** — Gemini `text-embedding-004` integration for vector-based project indexing and context-aware chat.
- **AI Coordination screen** — live dashboard showing each agent's status, assigned provider, and retry count.
- **History screen** — full session history with per-run document snapshots.
- **Context File Export** — generates a structured context file for use in external AI tools (AI handoff).
- **ZIP export** — bundle all generated documents into a single downloadable ZIP.
- **Cancellation support** — users can abort a documentation run mid-generation; each agent checks a `CancellationToken` before each retry.
- **Auto stagger** — 350 ms delay between agent launches to smooth bursts against free-tier rate limits.
- **Pruning of stale provider configs** — on startup, configs stored under removed provider names are automatically cleaned up.
- **Dark / Light / System theme toggle** — persisted via `shared_preferences`.
- **`StatefulShellRoute`** — each of the 10 destinations retains its widget state independently across navigation.
- **`path_safety.dart`** — guards against ZIP path traversal attacks during extraction.
- **`cancellation.dart`** — cooperative cancellation token shared across async services.

### Changed

- App renamed from internal working name to **Documentum** with tagline "AI-powered documentation, project memory, and seamless AI handoffs."
- Version bumped to `2.0.0`.
- Default Gemini model updated to `gemini-2.5-flash`.
- Default Groq model updated to `openai/gpt-oss-20b`.
- `maxTokens` default for Gemini raised to 8,192.
- `AiOrchestrator` rewritten for concurrent agent execution with independent retry/error handling — one agent failing no longer affects others.
- All data models migrated to `freezed` + `json_serializable`.
- Routing migrated from `Navigator` to `go_router` with `StatefulShellRoute.indexedStack`.
- Settings state centralised in `SettingsNotifier` (`AsyncNotifierProvider`).

### Removed

- OpenAI provider (paid-only, no free tier).
- DeepSeek provider (removed from supported backends).
- Legacy `Navigator.push` routing.

---

## [1.0.0] — 2026-03-01

### Added

- Initial release of the documentation generator.
- Single-agent sequential document generation.
- Gemini and Groq provider support.
- ZIP upload and in-memory extraction.
- Basic project analysis (language and framework detection).
- Dashboard, Projects, Documentation, Settings, and About screens.
- `flutter_secure_storage` for API key persistence.
