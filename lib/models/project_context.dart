import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_context.freezed.dart';
part 'project_context.g.dart';

/// The single, centralized description of an analyzed project.
///
/// This object is created ONCE by [ProjectAnalyzerService] and shared with
/// every AI agent. Agents must never re-analyze the project — they read from
/// this context. This is the heart of the "shared context system".
@freezed
class ProjectContext with _$ProjectContext {
  const factory ProjectContext({
    required String name,
    @Default('Unknown') String language,
    @Default('Unknown') String framework,
    @Default('Unknown') String database,
    @Default('Unknown') String packageManager,
    @Default('Unknown') String buildSystem,
    @Default('Unknown') String apiFramework,
    @Default('Unknown') String authSystem,
    @Default('Unknown') String architecture,
    @Default(<String>[]) List<String> modules,
    @Default(<String>[]) List<String> technologies,

    /// Human-readable summary injected into every agent prompt.
    @Default('') String summary,

    /// Compact ASCII folder tree (depth-limited).
    @Default('') String folderStructure,

    @Default(0) int fileCount,
    @Default(0) int totalLines,

    /// Whether a `.git` directory was present (used by the Changelog agent).
    @Default(false) bool hasGitHistory,
  }) = _ProjectContext;

  factory ProjectContext.fromJson(Map<String, dynamic> json) =>
      _$ProjectContextFromJson(json);
}
