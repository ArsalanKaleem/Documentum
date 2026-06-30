import 'package:flutter_test/flutter_test.dart';
import 'package:smart_docs_generator/models/source_file.dart';
import 'package:smart_docs_generator/services/file_scanner_service.dart';

SourceFile _f(String path, String content) => SourceFile(
      relativePath: path,
      content: content,
      sizeBytes: content.length,
      lineCount: content.split('\n').length,
    );

void main() {
  final scanner = FileScannerService();

  test('builds a language histogram keyed by extension', () {
    final result = scanner.scan([
      _f('lib/a.dart', 'void main() {}'),
      _f('lib/b.dart', 'class B {}'),
      _f('web/index.html', '<html></html>'),
    ]);

    expect(result.languageHistogram['.dart'], 2);
    expect(result.languageHistogram['.html'], 1);
    expect(result.fileCount, 3);
  });

  test('sums total line counts across files', () {
    final result = scanner.scan([
      _f('a.txt', 'one\ntwo\nthree'),
      _f('b.txt', 'single'),
    ]);
    expect(result.totalLines, 4);
  });

  test('renders a non-empty folder tree', () {
    final result = scanner.scan([
      _f('lib/src/main.dart', 'x'),
      _f('lib/src/util.dart', 'y'),
      _f('README.md', 'z'),
    ]);
    expect(result.folderTree, contains('lib'));
    expect(result.folderTree.trim(), isNotEmpty);
  });
}
