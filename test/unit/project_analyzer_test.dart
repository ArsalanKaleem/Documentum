import 'package:flutter_test/flutter_test.dart';
import 'package:smart_docs_generator/models/source_file.dart';
import 'package:smart_docs_generator/services/file_scanner_service.dart';
import 'package:smart_docs_generator/services/project_analyzer_service.dart';

SourceFile _f(String path, String content) => SourceFile(
      relativePath: path,
      content: content,
      sizeBytes: content.length,
      lineCount: content.split('\n').length,
    );

void main() {
  final analyzer = ProjectAnalyzerService(FileScannerService());

  test('detects a Flutter project from pubspec.yaml', () {
    final ctx = analyzer.analyze(
      projectName: 'demo_app',
      hasGit: true,
      files: [
        _f('pubspec.yaml', 'name: demo_app\ndependencies:\n  flutter:\n    sdk: flutter'),
        _f('lib/main.dart', 'void main() {}'),
      ],
    );

    expect(ctx.framework, 'Flutter');
    expect(ctx.language, 'Dart');
    expect(ctx.packageManager, 'pub');
    expect(ctx.hasGitHistory, isTrue);
    expect(ctx.name, 'demo_app');
  });

  test('detects an Express + npm project', () {
    final ctx = analyzer.analyze(
      projectName: 'api',
      hasGit: false,
      files: [
        _f('package.json',
            '{"name":"api","dependencies":{"express":"^4.18.0"}}'),
        _f('src/index.ts', 'import express from "express";'),
      ],
    );

    expect(ctx.framework, 'Express');
    expect(ctx.packageManager, 'npm');
    expect(ctx.language, 'TypeScript');
  });

  test('detects Next.js over plain React', () {
    final ctx = analyzer.analyze(
      projectName: 'web',
      hasGit: false,
      files: [
        _f('package.json',
            '{"dependencies":{"next":"14.0.0","react":"18.0.0"}}'),
        _f('pages/index.tsx', 'export default function Home(){return null;}'),
      ],
    );
    expect(ctx.framework, 'Next.js');
  });

  test('produces a non-empty shared summary and technologies list', () {
    final ctx = analyzer.analyze(
      projectName: 'api',
      hasGit: false,
      files: [
        _f('package.json', '{"dependencies":{"express":"^4.0.0"}}'),
        _f('src/index.js', 'const e = require("express");'),
      ],
    );
    expect(ctx.summary, isNotEmpty);
    expect(ctx.technologies, contains('Express'));
    expect(ctx.fileCount, 2);
  });
}
