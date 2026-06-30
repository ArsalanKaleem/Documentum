import '../../../models/generated_doc.dart';
import '../../../models/project_context.dart';
import '../../../models/source_file.dart';
import '../../ai/ai_provider.dart';
import '../prompts/prompt_builder.dart';
import 'doc_agent.dart';

class ReadmeAgent extends DocAgent {
  @override
  DocType get docType => DocType.readme;

  @override
  String get role =>
      'You are a senior technical writer producing a project README.';

  @override
  String get instructions => '''
Generate a complete README.md with these sections, in order:
1. Project title and one-paragraph description
2. Features (bulleted)
3. Technologies (from the shared context)
4. Installation
5. Build
6. Run
7. Environment Variables (table: name | description)
8. Screenshots (a placeholder section with image tags)
9. Roadmap
10. Contributing (brief, link to CONTRIBUTING.md)
11. License
Keep it concise and accurate to the detected stack.''';

  @override
  List<SourceFile> selectFiles(ProjectContext context, List<SourceFile> files) =>
      rankByKeywords(files, [
        'readme',
        'package.json',
        'pubspec',
        '.env',
        'main',
        'index',
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

class ApiAgent extends DocAgent {
  @override
  DocType get docType => DocType.api;

  @override
  String get role =>
      'You document HTTP/RPC APIs precisely for backend consumers.';

  @override
  String get instructions => '''
Generate API.md documenting the project's API surface:
- Endpoints (method, path, purpose) grouped by resource/module
- Request examples (curl + JSON body where relevant)
- Response examples (status codes + JSON)
- Authentication (how to obtain and pass credentials)
- Error handling (error shape and common codes)
Only document endpoints that exist in the provided files. If no API is
present, say so clearly and document any internal service interfaces instead.''';

  @override
  List<SourceFile> selectFiles(ProjectContext context, List<SourceFile> files) =>
      rankByKeywords(files, [
        'route',
        'router',
        'controller',
        'api',
        'endpoint',
        'handler',
        'resolver',
        'view',
        'urls',
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

class ArchitectureAgent extends DocAgent {
  @override
  DocType get docType => DocType.architecture;

  @override
  String get role =>
      'You are a software architect explaining system structure clearly.';

  @override
  String get instructions => '''
Generate ARCHITECTURE.md covering:
- Layers (and responsibilities of each)
- Data flow (how a request/action moves through the system)
- Module relationships
- Design patterns in use (cite where you see them)
- Dependency overview (key external dependencies and why)
Use a Mermaid diagram for the high-level component relationships where helpful.''';

  @override
  List<SourceFile> selectFiles(ProjectContext context, List<SourceFile> files) =>
      rankByKeywords(files, [
        'service',
        'repository',
        'provider',
        'model',
        'domain',
        'core',
        'config',
        'main',
        'app',
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
