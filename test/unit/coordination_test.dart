import 'package:flutter_test/flutter_test.dart';
import 'package:smart_docs_generator/models/generated_doc.dart';
import 'package:smart_docs_generator/models/project_context.dart';
import 'package:smart_docs_generator/models/session_record.dart';
import 'package:smart_docs_generator/models/source_file.dart';
import 'package:smart_docs_generator/services/export/context_file_service.dart';
import 'package:smart_docs_generator/services/project_brain_service.dart';

SourceFile _f(String path, String content) => SourceFile(
      relativePath: path,
      content: content,
      sizeBytes: content.length,
      lineCount: content.split('\n').length,
    );

void main() {
  group('ProjectBrainService', () {
    final service = ProjectBrainService();

    test('extracts entry points, important files and dependencies', () {
      const context = ProjectContext(
        name: 'api',
        language: 'TypeScript',
        framework: 'Express',
        architecture: 'Layered',
        fileCount: 4,
        totalLines: 120,
      );
      final files = [
        _f('package.json',
            '{"dependencies":{"express":"^4.18.0","pg":"^8.0.0"}}'),
        _f('src/index.ts', 'import express from "express";'),
        _f('src/router.ts', 'export const router = 1;'),
        _f('README.md', '# API'),
      ];

      final brain = service.build(context: context, files: files);

      expect(brain.entryPoints, contains('src/index.ts'));
      expect(brain.importantFiles, contains('package.json'));
      expect(brain.importantFiles, contains('src/router.ts'));
      expect(brain.dependencies, containsAll(['express', 'pg']));
      expect(brain.existingDocumentation, contains('README.md'));
      expect(brain.languages, contains('TypeScript'));
    });

    test('parses pubspec dependencies and skips flutter/sdk', () {
      const context = ProjectContext(name: 'app', framework: 'Flutter');
      final files = [
        _f('pubspec.yaml', '''
name: app
dependencies:
  flutter:
    sdk: flutter
  go_router: ^14.0.0
  dio: ^5.0.0
'''),
        _f('lib/main.dart', 'void main() {}'),
      ];
      final brain = service.build(context: context, files: files);
      expect(brain.dependencies, containsAll(['go_router', 'dio']));
      expect(brain.dependencies, isNot(contains('flutter')));
    });
  });

  group('ContextFileService', () {
    final brainService = ProjectBrainService();
    final ctxService = ContextFileService();

    test('produces all four handoff files with real content', () {
      const context = ProjectContext(
        name: 'taskflow',
        language: 'Dart',
        framework: 'Flutter',
        architecture: 'Clean Architecture',
        fileCount: 10,
        totalLines: 500,
      );
      final brain = brainService.build(
        context: context,
        files: [_f('lib/main.dart', 'void main() {}')],
      );
      final docs = [
        const GeneratedDoc(
          type: DocType.readme,
          content: '# TaskFlow\nA task manager.',
          status: DocStatus.completed,
          providerUsed: 'OpenAI gpt-4o-mini',
        ),
      ];
      final sessions = [
        SessionRecord(
          date: '2026-06-26',
          timestamp: DateTime(2026, 6, 26),
          generatedDocumentation: const ['README.md'],
          aiProvidersUsed: const ['OpenAI gpt-4o-mini'],
          nextTasks: const ['Add tests'],
        ),
      ];

      final files = ctxService.buildAll(
        brain: brain,
        docs: docs,
        sessions: sessions,
      );

      expect(files.keys, containsAll([
        'AI_CONTEXT.md',
        'PROJECT_BRAIN.md',
        'SESSION_SUMMARY.md',
        'AI_CONTINUATION_PROMPT.md',
      ]));
      expect(files['AI_CONTEXT.md'], contains('taskflow'));
      expect(files['PROJECT_BRAIN.md'], contains('Clean Architecture'));
      expect(files['AI_CONTINUATION_PROMPT.md'],
          contains('continuing development'));
      expect(files['SESSION_SUMMARY.md'], contains('README.md'));
    });
  });
}
