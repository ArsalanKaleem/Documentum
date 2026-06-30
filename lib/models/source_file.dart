import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path/path.dart' as p;

part 'source_file.freezed.dart';
part 'source_file.g.dart';

/// A single text source file extracted from the uploaded project.
@freezed
class SourceFile with _$SourceFile {
  const SourceFile._();

  const factory SourceFile({
    /// Path relative to the project root, always using `/` separators.
    required String relativePath,
    required String content,
    @Default(0) int sizeBytes,
    @Default(0) int lineCount,

    /// Optional embedding vector for RAG. Null until indexed.
    List<double>? embedding,
  }) = _SourceFile;

  factory SourceFile.fromJson(Map<String, dynamic> json) =>
      _$SourceFileFromJson(json);

  String get fileName => p.basename(relativePath);
  String get extension => p.extension(relativePath).toLowerCase();
  String get directory => p.dirname(relativePath);
}
