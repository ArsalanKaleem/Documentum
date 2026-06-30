import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_docs_generator/models/generated_doc.dart';
import 'package:smart_docs_generator/services/export/export_service.dart';

GeneratedDoc _doc(DocType type, String content) => GeneratedDoc(
      type: type,
      content: content,
      status: DocStatus.completed,
    );

void main() {
  final export = ExportService();

  test('exportZip nests completed docs under docs/', () {
    final bytes = export.exportZip([
      _doc(DocType.readme, '# Readme'),
      _doc(DocType.api, '# API'),
      GeneratedDoc(type: DocType.architecture), // pending, excluded
    ]);

    final archive = ZipDecoder().decodeBytes(bytes);
    final names = archive.files.map((f) => f.name).toSet();

    expect(names, contains('docs/README.md'));
    expect(names, contains('docs/API.md'));
    expect(names, isNot(contains('docs/ARCHITECTURE.md')));

    final readme = archive.files.firstWhere((f) => f.name == 'docs/README.md');
    expect(utf8.decode(readme.content as List<int>), '# Readme');
  });

  test('exportMarkdownFiles returns one file per completed doc', () {
    final files = export.exportMarkdownFiles([
      _doc(DocType.readme, '# Readme'),
      _doc(DocType.changelog, '# Changelog'),
    ]);
    expect(files.length, 2);
    expect(files.map((f) => f.fileName), containsAll(['README.md', 'CHANGELOG.md']));
  });

  test('exportZip throws when there is nothing completed', () {
    expect(
      () => export.exportZip([GeneratedDoc(type: DocType.readme)]),
      throwsA(isA<Exception>()),
    );
  });
}
