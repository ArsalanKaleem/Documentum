import '../../../models/generated_doc.dart';
import '../../../models/project_context.dart';
import '../../../models/source_file.dart';
import '../../ai/ai_provider.dart';
import '../prompts/prompt_builder.dart';
import 'doc_agent.dart';

class InstallationAgent extends DocAgent {
  @override
  DocType get docType => DocType.installation;

  @override
  String get role => 'You write precise, reproducible setup guides.';

  @override
  String get instructions => '''
Generate INSTALLATION.md with:
- Prerequisites (runtimes, SDK versions, tools — infer from the stack)
- Setup (clone, install dependencies using the detected package manager)
- Environment Variables (list each required var with a short description)
- Docker Instructions (only if a Dockerfile / compose file is present)
- Build Instructions (commands for the detected build system)
Use fenced shell blocks with the correct package-manager commands.''';

  @override
  List<SourceFile> selectFiles(ProjectContext context, List<SourceFile> files) =>
      rankByKeywords(files, [
        'dockerfile',
        'docker-compose',
        '.env',
        'package.json',
        'pubspec',
        'makefile',
        'requirements',
        'pyproject',
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

class ContributingAgent extends DocAgent {
  @override
  DocType get docType => DocType.contributing;

  @override
  String get role => 'You write clear contributor guidelines.';

  @override
  String get instructions => '''
Generate CONTRIBUTING.md with:
- Branch Strategy (e.g. trunk-based or git-flow — pick a sensible default)
- Commit Convention (recommend Conventional Commits with examples)
- Pull Request Process (steps from fork/branch to review to merge)
- Code Standards (linting/formatting tools detected in the project)
Keep it actionable and friendly to first-time contributors.''';

  @override
  List<SourceFile> selectFiles(ProjectContext context, List<SourceFile> files) =>
      rankByKeywords(files, [
        'contributing',
        '.eslintrc',
        'analysis_options',
        '.prettier',
        'lint',
        '.editorconfig',
        'workflow',
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

class ChangelogAgent extends DocAgent {
  @override
  DocType get docType => DocType.changelog;

  @override
  String get role => 'You produce structured changelogs.';

  @override
  String get instructions => '''
Generate CHANGELOG.md following "Keep a Changelog" conventions and semantic
versioning. Base entries on:
- Existing CHANGELOG/release notes if present
- The project structure and modules from the shared context
If no version history exists, create an initial [Unreleased] and [1.0.0]
section summarizing current capabilities by module. Do not fabricate dates or
version numbers that are not supported by the provided files.''';

  @override
  List<SourceFile> selectFiles(ProjectContext context, List<SourceFile> files) =>
      rankByKeywords(files, [
        'changelog',
        'history',
        'release',
        'version',
        'package.json',
        'pubspec',
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
