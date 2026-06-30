import '../../../models/generated_doc.dart';
import '../../../models/project_context.dart';
import '../../../models/source_file.dart';
import '../../ai/ai_provider.dart';

/// Contract for a documentation agent. Each agent owns ONE [DocType] and knows
/// which files are relevant and how to instruct the model. Agents are pure:
/// they only build messages — the orchestrator performs the network call.
abstract class DocAgent {
  DocType get docType;

  /// Short role description placed in the system prompt.
  String get role;

  /// The task instructions for this specific document.
  String get instructions;

  /// Selects and orders the files most relevant to this agent. The default
  /// returns all files; agents override to prioritize.
  List<SourceFile> selectFiles(
    ProjectContext context,
    List<SourceFile> files,
  ) =>
      files;

  /// Builds the messages for this agent using the shared context.
  List<AiMessage> buildMessages(
    ProjectContext context,
    List<SourceFile> files,
  );
}

/// Reusable scoring helper for relevance-ranking files by path keywords.
List<SourceFile> rankByKeywords(
  List<SourceFile> files,
  List<String> keywords, {
  int limit = 25,
}) {
  final scored = files.map((f) {
    final path = f.relativePath.toLowerCase();
    var score = 0;
    for (final k in keywords) {
      if (path.contains(k)) score += 2;
      if (f.content.toLowerCase().contains(k)) score += 1;
    }
    return (file: f, score: score);
  }).toList()
    ..sort((a, b) => b.score.compareTo(a.score));

  final ranked = scored.where((s) => s.score > 0).map((s) => s.file).toList();
  if (ranked.length < limit) {
    for (final f in files) {
      if (ranked.length >= limit) break;
      if (!ranked.contains(f)) ranked.add(f);
    }
  }
  return ranked.take(limit).toList();
}
