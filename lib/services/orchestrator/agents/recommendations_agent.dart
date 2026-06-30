import '../../../models/generated_doc.dart';
import '../../../models/project_context.dart';
import '../../../models/source_file.dart';
import '../../ai/ai_provider.dart';
import '../prompts/prompt_builder.dart';
import 'doc_agent.dart';

/// Analyzes the project and proposes concrete, prioritized improvements and
/// features worth adding — acting like a senior engineer doing a code review.
class RecommendationsAgent extends DocAgent {
  @override
  DocType get docType => DocType.recommendations;

  @override
  String get role =>
      'You are a pragmatic senior engineer performing a constructive review, '
      'identifying high-impact improvements and features worth adding.';

  @override
  String get instructions => '''
Generate RECOMMENDATIONS.md — a thoughtful, project-specific review. Base every
point on what you actually observe in the code and stack; do NOT give generic
advice. Use this structure with Markdown headings and GitHub-flavored tables:

## Summary
A 2-3 sentence assessment of the project's current state and biggest opportunity.

## Recommended Improvements
A Markdown table with columns: Area | Recommendation | Why it matters | Effort.
Use Effort values of Low / Medium / High. Cover code quality, architecture,
testing, performance, security, and developer experience where relevant.

## Features Worth Adding
A Markdown table with columns: Feature | Description | User value | Priority.
Use Priority values of High / Medium / Low. Propose features that fit the
project's domain and existing capabilities.

## Quick Wins
A short bulleted list of changes that are low-effort but high-impact.

## Longer-Term Ideas
A short bulleted list of more ambitious directions worth considering.

Be specific, reference real modules/files/patterns you see, and keep tables
clean and valid (header row, separator row, consistent columns).''';

  @override
  List<SourceFile> selectFiles(ProjectContext context, List<SourceFile> files) =>
      rankByKeywords(files, [
        'main',
        'app',
        'service',
        'provider',
        'repository',
        'model',
        'screen',
        'widget',
        'test',
        'config',
      ]);

  @override
  List<AiMessage> buildMessages(ProjectContext c, List<SourceFile> files) =>
      PromptBuilder.assemble(
        role: role,
        instructions: instructions,
        context: c,
        files: selectFiles(c, files),
      );
}
