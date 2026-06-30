import 'package:freezed_annotation/freezed_annotation.dart';

import 'generated_doc.dart';
import 'project_context.dart';
import 'source_file.dart';

part 'project.freezed.dart';
part 'project.g.dart';

/// A fully processed project: its shared context, scanned source files, and any
/// generated documentation. Persisted to local storage for "recent projects".
@freezed
class Project with _$Project {
  const factory Project({
    required String id,
    required ProjectContext context,
    @Default(<SourceFile>[]) List<SourceFile> files,
    @Default(<GeneratedDoc>[]) List<GeneratedDoc> docs,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Project;

  factory Project.fromJson(Map<String, dynamic> json) =>
      _$ProjectFromJson(json);
}
