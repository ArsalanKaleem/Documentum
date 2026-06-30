import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/generated_doc.dart';
import '../models/project_brain.dart';
import '../models/session_record.dart';
import 'project_providers.dart';
import 'service_providers.dart';

/// Derives the [ProjectBrain] for the active project (built once from the
/// shared context + files; no re-scanning).
final projectBrainProvider = Provider<ProjectBrain?>((ref) {
  final project = ref.watch(projectControllerProvider).valueOrNull;
  if (project == null) return null;
  return ref.watch(projectBrainServiceProvider).build(
        context: project.context,
        files: project.files,
      );
});

/// Immutable snapshot of coordination artifacts.
class CoordinationState {
  const CoordinationState({
    this.contextFiles = const {},
    this.sessions = const [],
  });

  /// fileName → markdown content (AI_CONTEXT.md, PROJECT_BRAIN.md, …).
  final Map<String, String> contextFiles;
  final List<SessionRecord> sessions;

  SessionRecord? get lastSession =>
      sessions.isNotEmpty ? sessions.last : null;

  CoordinationState copyWith({
    Map<String, String>? contextFiles,
    List<SessionRecord>? sessions,
  }) =>
      CoordinationState(
        contextFiles: contextFiles ?? this.contextFiles,
        sessions: sessions ?? this.sessions,
      );
}

/// Owns the generated context files and session history. Rebuilds the context
/// files after each generation cycle and records a development session.
class CoordinationNotifier extends AsyncNotifier<CoordinationState> {
  @override
  Future<CoordinationState> build() async {
    final sessions = await ref.read(sessionTrackerProvider).load();
    final state = CoordinationState(sessions: sessions);
    // Build context files from whatever already exists for the active project.
    return _rebuildContextFiles(state);
  }

  CoordinationState _rebuildContextFiles(CoordinationState base) {
    final brain = ref.read(projectBrainProvider);
    if (brain == null) return base;
    final project = ref.read(projectControllerProvider).valueOrNull;
    final docs = project?.docs ?? const <GeneratedDoc>[];
    final files = ref.read(contextFileServiceProvider).buildAll(
          brain: brain,
          docs: docs,
          sessions: base.sessions,
        );
    return base.copyWith(contextFiles: files);
  }

  /// Records a finished generation cycle: appends a session and regenerates
  /// all context files so they reflect the new state.
  Future<void> recordCycle(List<GeneratedDoc> docs) async {
    final brain = ref.read(projectBrainProvider);
    if (brain == null) return;

    final completed =
        docs.where((d) => d.status == DocStatus.completed).toList();
    final providers = <String>{
      for (final d in completed)
        if (d.providerUsed != null) d.providerUsed!,
    }.toList();

    final now = DateTime.now();
    final record = SessionRecord(
      date: now.toIso8601String().split('T').first,
      timestamp: now,
      generatedDocumentation: completed.map((d) => d.type.fileName).toList(),
      aiProvidersUsed: providers,
      summary: 'Generated ${completed.length} document(s) '
          'across ${providers.length} provider(s).',
      nextTasks: const [
        'Review generated documentation for accuracy.',
        'Regenerate any failed documents.',
      ],
    );

    final tracker = ref.read(sessionTrackerProvider);
    await tracker.add(record);
    final sessions = await tracker.load();

    final files = ref.read(contextFileServiceProvider).buildAll(
          brain: brain,
          docs: docs,
          sessions: sessions,
        );

    state = AsyncData(
      CoordinationState(contextFiles: files, sessions: sessions),
    );
  }

  /// Regenerates context files on demand (e.g. after manual edits).
  void refresh() {
    final current = state.valueOrNull ?? const CoordinationState();
    state = AsyncData(_rebuildContextFiles(current));
  }

  Future<void> clearHistory() async {
    await ref.read(sessionTrackerProvider).clear();
    final current = state.valueOrNull ?? const CoordinationState();
    state = AsyncData(current.copyWith(sessions: const []));
  }
}

final coordinationProvider =
    AsyncNotifierProvider<CoordinationNotifier, CoordinationState>(
  CoordinationNotifier.new,
);

/// Convenience accessor for the AI continuation prompt text.
final continuationPromptProvider = Provider<String?>((ref) {
  final coord = ref.watch(coordinationProvider).valueOrNull;
  return coord?.contextFiles['AI_CONTINUATION_PROMPT.md'];
});
