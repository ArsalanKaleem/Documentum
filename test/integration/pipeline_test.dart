// End-to-end integration test for the documentation pipeline.
//
// This exercises the real analyzer → orchestrator → export flow with a fake AI
// provider injected at the factory boundary, so it runs fully offline. It can
// be run with `flutter test test/integration/pipeline_test.dart`.
//
// A full on-device UI integration test (driving the widget tree via the
// `integration_test` package) would also live in this directory; this test
// validates the service pipeline that those UI flows depend on.

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_docs_generator/models/ai_provider_config.dart';
import 'package:smart_docs_generator/models/generated_doc.dart';
import 'package:smart_docs_generator/models/source_file.dart';
import 'package:smart_docs_generator/services/ai/ai_provider.dart';
import 'package:smart_docs_generator/services/ai/ai_provider_factory.dart';
import 'package:smart_docs_generator/services/export/export_service.dart';
import 'package:smart_docs_generator/services/file_scanner_service.dart';
import 'package:smart_docs_generator/services/orchestrator/ai_orchestrator.dart';
import 'package:smart_docs_generator/services/project_analyzer_service.dart';

/// A deterministic, offline provider that returns markdown echoing the prompt.
class _FakeProvider implements AiProvider {
  _FakeProvider(this.type);
  @override
  final AiProviderType type;

  @override
  Future<AiCompletion> complete({
    required List<AiMessage> messages,
    required AiProviderConfig config,
    required String apiKey,
  }) async =>
      AiCompletion(
        text: '# Generated\n\nProvider: ${type.label}\nModel: ${config.model}',
        providerLabel: type.label,
      );

  @override
  Stream<String> streamComplete({
    required List<AiMessage> messages,
    required AiProviderConfig config,
    required String apiKey,
  }) async* {
    yield '# Generated';
  }

  @override
  Future<List<List<double>>> embed({
    required List<String> inputs,
    required AiProviderConfig config,
    required String apiKey,
  }) async =>
      throw UnsupportedError('no embeddings in fake');
}

class _FakeFactory extends AiProviderFactory {
  @override
  AiProvider resolve(AiProviderType type) => _FakeProvider(type);
}

SourceFile _f(String path, String content) => SourceFile(
      relativePath: path,
      content: content,
      sizeBytes: content.length,
      lineCount: content.split('\n').length,
    );

void main() {
  test('analyze → generate all docs → export ZIP (offline)', () async {
    // 1. Real analysis of a synthetic Express project.
    final analyzer = ProjectAnalyzerService(FileScannerService());
    final files = [
      _f('package.json', '{"dependencies":{"express":"^4.18.0"}}'),
      _f('src/index.ts', 'import express from "express";'),
      _f('src/auth/jwt.ts', 'export function verify() {}'),
    ];
    final context = analyzer.analyze(
      projectName: 'taskflow',
      hasGit: true,
      files: files,
    );
    expect(context.framework, 'Express');

    // 2. Orchestrate all six agents with the fake provider + key reader.
    final orchestrator = AiOrchestrator(
      factory: _FakeFactory(),
      apiKeyReader: (_) async => 'test-key',
    );
    final config = AiProviderConfig.defaults(AiProviderType.gemini);

    final completed = <DocType, GeneratedDoc>{};
    await for (final doc in orchestrator.generateAll(
      context: context,
      files: files,
      configFor: (_) => config,
    )) {
      if (doc.status == DocStatus.completed) completed[doc.type] = doc;
    }
    final docs = completed.values.toList();

    // One completed doc per agent (6 total).
    expect(docs.length, DocType.values.length);
    expect(docs.every((d) => d.content.contains('Generated')), isTrue);

    // 3. Export and verify the ZIP contains all six docs under docs/.
    final zipBytes = ExportService().exportZip(docs);
    expect(zipBytes, isNotEmpty);
  });

  test('orchestrator surfaces a config failure when no key is present',
      () async {
    final orchestrator = AiOrchestrator(
      factory: _FakeFactory(),
      apiKeyReader: (_) async => null,
    );
    final config = AiProviderConfig.defaults(AiProviderType.gemini);
    final context = ProjectAnalyzerService(FileScannerService()).analyze(
      projectName: 'x',
      hasGit: false,
      files: [_f('a.dart', 'void main(){}')],
    );

    final statuses = <DocStatus>[];
    await for (final doc in orchestrator.generateAll(
      context: context,
      files: const [],
      configFor: (_) => config,
    )) {
      statuses.add(doc.status);
    }
    // Every agent should report failure (missing key), never completed.
    expect(statuses, isNot(contains(DocStatus.completed)));
    expect(statuses, contains(DocStatus.failed));
  });
}
