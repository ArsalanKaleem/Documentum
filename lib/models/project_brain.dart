import 'package:freezed_annotation/freezed_annotation.dart';

import 'project_context.dart';

part 'project_brain.freezed.dart';
part 'project_brain.g.dart';

/// The master memory of a project — a compressed, structured understanding that
/// every agent and every exported context file draws from.
///
/// Built ONCE per project by `ProjectBrainService` from the shared
/// [ProjectContext] plus the scanned files. No agent re-scans the repository.
@freezed
class ProjectBrain with _$ProjectBrain {
  const ProjectBrain._();

  const factory ProjectBrain({
    required String name,
    @Default(<String>[]) List<String> languages,
    @Default(<String>[]) List<String> frameworks,
    @Default(<String>[]) List<String> databases,
    @Default('Unknown') String architecture,
    @Default('') String folderStructure,
    @Default(<String>[]) List<String> modules,

    /// Paths of the most significant files (entry points, configs, routers).
    @Default(<String>[]) List<String> importantFiles,

    /// Detected application entry points (e.g. main.dart, index.ts, server.js).
    @Default(<String>[]) List<String> entryPoints,

    /// Declared dependencies parsed from manifests.
    @Default(<String>[]) List<String> dependencies,

    /// Documentation files already present in the repository.
    @Default(<String>[]) List<String> existingDocumentation,
    @Default(false) bool hasGitHistory,
    @Default(0) int fileCount,
    @Default(0) int totalLines,
    @Default('') String summary,
  }) = _ProjectBrain;

  factory ProjectBrain.fromJson(Map<String, dynamic> json) =>
      _$ProjectBrainFromJson(json);

  /// The original analyzer context distilled into this brain (for callers that
  /// still need the flat view).
  ProjectContext toContext() => ProjectContext(
        name: name,
        language: languages.isNotEmpty ? languages.first : 'Unknown',
        framework: frameworks.isNotEmpty ? frameworks.first : 'Unknown',
        database: databases.isNotEmpty ? databases.first : 'Unknown',
        architecture: architecture,
        modules: modules,
        folderStructure: folderStructure,
        fileCount: fileCount,
        totalLines: totalLines,
        hasGitHistory: hasGitHistory,
        summary: summary,
      );
}
