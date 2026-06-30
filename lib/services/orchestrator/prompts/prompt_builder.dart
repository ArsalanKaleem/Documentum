import '../../../core/constants/app_constants.dart';
import '../../../models/project_context.dart';
import '../../../models/source_file.dart';
import '../../ai/ai_provider.dart';

/// Builds prompts that always carry the SHARED [ProjectContext] so agents never
/// re-analyze the project. Centralizing prompt construction keeps every agent
/// consistent and token-budget aware.
class PromptBuilder {
  /// The reusable context block prepended to every agent's system prompt.
  static String contextBlock(ProjectContext c) {
    final tech = c.technologies.isEmpty ? 'n/a' : c.technologies.join(', ');
    final modules = c.modules.isEmpty ? 'n/a' : c.modules.join(', ');
    return '''
=== SHARED PROJECT CONTEXT (authoritative — do not contradict) ===
Name: ${c.name}
Summary: ${c.summary}
Language: ${c.language}
Framework: ${c.framework}
Database: ${c.database}
API framework: ${c.apiFramework}
Auth system: ${c.authSystem}
Package manager: ${c.packageManager}
Build system: ${c.buildSystem}
Architecture: ${c.architecture}
Key modules: $modules
Technologies: $tech
File count: ${c.fileCount}  |  Total lines: ${c.totalLines}

--- FOLDER STRUCTURE ---
${c.folderStructure}
=== END SHARED CONTEXT ===
''';
  }

  /// Renders up to [AppConstants.maxFilesPerPrompt] files as fenced blocks,
  /// truncating each to the per-file byte budget and stripping lines that are
  /// pathologically long (e.g. auto-generated table cells) to prevent them
  /// from consuming the entire prompt token budget.
  static String fileExcerpts(List<SourceFile> files) {
    final selected = files.take(AppConstants.maxFilesPerPrompt);
    final buffer = StringBuffer('=== RELEVANT FILES ===\n');
    for (final f in selected) {
      var content = f.content;
      // Strip lines longer than 400 chars — these are almost always
      // minified JS, generated data, or huge table cells that add no value
      // to the agent but consume thousands of tokens.
      content = content.split('\n').map((line) {
        if (line.length > 400) {
          return '${line.substring(0, 200)} ... [line truncated — ${line.length} chars]';
        }
        return line;
      }).join('\n');
      // Hard cap per file.
      if (content.length > AppConstants.maxFileContentBytes) {
        content = '${content.substring(0, AppConstants.maxFileContentBytes)}\n... [truncated]';
      }
      buffer
        ..writeln('FILE: ${f.relativePath}')
        ..writeln('```')
        ..writeln(content)
        ..writeln('```')
        ..writeln();
    }
    return buffer.toString();
  }

  /// Assembles the final message list for an agent.
  static List<AiMessage> assemble({
    required String role,
    required String instructions,
    required ProjectContext context,
    required List<SourceFile> files,
  }) {
    return [
      AiMessage.system(
        '$role\n\n${contextBlock(context)}\n'
            'Write clean, professional GitHub-flavored Markdown. Be accurate to '
            'the context above; never invent technologies that are not present. '
            'Do not wrap the whole document in a code fence.',
      ),
      AiMessage.user('$instructions\n\n${fileExcerpts(files)}'),
    ];
  }
}