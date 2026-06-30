import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/project.dart';
import '../models/project_context.dart';
import 'service_providers.dart';

/// Coarse progress phases surfaced to the Analysis page.
enum AnalysisPhase { idle, extracting, scanning, analyzing, done, error }

class AnalysisProgress {
  const AnalysisProgress({
    this.phase = AnalysisPhase.idle,
    this.message = '',
    this.fileCount = 0,
    this.skippedCount = 0,
  });

  final AnalysisPhase phase;
  final String message;
  final int fileCount;
  final int skippedCount;

  double get fraction => switch (phase) {
        AnalysisPhase.idle => 0,
        AnalysisPhase.extracting => 0.25,
        AnalysisPhase.scanning => 0.55,
        AnalysisPhase.analyzing => 0.8,
        AnalysisPhase.done => 1,
        AnalysisPhase.error => 0,
      };
}

/// Live progress for the analysis pipeline.
final analysisProgressProvider =
    StateProvider<AnalysisProgress>((_) => const AnalysisProgress());

/// Holds the currently active [Project] (null until one is processed).
class ProjectController extends AsyncNotifier<Project?> {
  @override
  Future<Project?> build() async => ref.read(projectRepositoryProvider).active;

  /// Full pipeline: validate + extract ZIP → scan → analyze → build Project.
  Future<void> processZip(Uint8List bytes) async {
    state = const AsyncLoading();
    final progress = ref.read(analysisProgressProvider.notifier);
    try {
      progress.state = const AnalysisProgress(
        phase: AnalysisPhase.extracting,
        message: 'Extracting and validating archive…',
      );
      final extraction = await ref.read(zipServiceProvider).extract(bytes);

      progress.state = AnalysisProgress(
        phase: AnalysisPhase.scanning,
        message: 'Scanning ${extraction.files.length} files…',
        fileCount: extraction.files.length,
        skippedCount: extraction.skippedCount,
      );

      progress.state = AnalysisProgress(
        phase: AnalysisPhase.analyzing,
        message: 'Detecting languages, frameworks and modules…',
        fileCount: extraction.files.length,
        skippedCount: extraction.skippedCount,
      );
      final ProjectContext context =
          ref.read(projectAnalyzerProvider).analyze(
                projectName: extraction.rootName,
                files: extraction.files,
                hasGit: extraction.hasGit,
              );

      final project = Project(
        id: const Uuid().v4(),
        context: context,
        files: extraction.files,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final repo = ref.read(projectRepositoryProvider);
      repo.active = project;
      await repo.saveRecent(project);

      progress.state = AnalysisProgress(
        phase: AnalysisPhase.done,
        message: 'Analysis complete.',
        fileCount: extraction.files.length,
        skippedCount: extraction.skippedCount,
      );
      state = AsyncData(project);
    } catch (e, st) {
      progress.state = AnalysisProgress(
        phase: AnalysisPhase.error,
        message: e.toString(),
      );
      state = AsyncError(e, st);
    }
  }

  /// Replaces the active project (e.g. when generated docs are updated).
  ///
  /// Named [setProject] rather than `update` because [AsyncNotifier] already
  /// defines an `update` method with an incompatible signature.
  void setProject(Project project) {
    ref.read(projectRepositoryProvider).active = project;
    state = AsyncData(project);
  }

  void clear() {
    ref.read(projectRepositoryProvider).active = null;
    ref.read(analysisProgressProvider.notifier).state =
        const AnalysisProgress();
    state = const AsyncData(null);
  }
}

final projectControllerProvider =
    AsyncNotifierProvider<ProjectController, Project?>(ProjectController.new);

/// Recent projects for the dashboard.
final recentProjectsProvider = FutureProvider<List<Project>>(
  (ref) => ref.watch(projectRepositoryProvider).getRecents(),
);
