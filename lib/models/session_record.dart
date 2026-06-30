import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_record.freezed.dart';
part 'session_record.g.dart';

/// One development session entry, persisted to `session_history.json`.
///
/// A session is recorded after each generation cycle: which docs were produced,
/// which providers ran, and what should happen next. Free-form fields
/// ([featuresCompleted], [bugsFixed], [nextTasks]) can be enriched by the user
/// or future automation; the generation-derived fields are filled automatically.
@freezed
class SessionRecord with _$SessionRecord {
  const factory SessionRecord({
    required String date, // YYYY-MM-DD
    required DateTime timestamp,
    @Default(<String>[]) List<String> filesModified,
    @Default(<String>[]) List<String> featuresCompleted,
    @Default(<String>[]) List<String> bugsFixed,
    @Default(<String>[]) List<String> generatedDocumentation,
    @Default(<String>[]) List<String> aiProvidersUsed,
    @Default(<String>[]) List<String> nextTasks,
    @Default('') String summary,
  }) = _SessionRecord;

  factory SessionRecord.fromJson(Map<String, dynamic> json) =>
      _$SessionRecordFromJson(json);
}
