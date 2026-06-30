import 'package:flutter_test/flutter_test.dart';
import 'package:smart_docs_generator/core/utils/path_safety.dart';

void main() {
  group('PathSafety.isSafeArchivePath (zip-slip defense)', () {
    const root = '/tmp/extract_root';

    test('accepts ordinary nested paths', () {
      expect(PathSafety.isSafeArchivePath('lib/main.dart', root), isTrue);
      expect(PathSafety.isSafeArchivePath('src/a/b/c.ts', root), isTrue);
      expect(PathSafety.isSafeArchivePath('README.md', root), isTrue);
    });

    test('rejects parent-directory traversal', () {
      expect(PathSafety.isSafeArchivePath('../evil.sh', root), isFalse);
      expect(
        PathSafety.isSafeArchivePath('lib/../../etc/passwd', root),
        isFalse,
      );
      expect(
        PathSafety.isSafeArchivePath('a/b/../../../escape', root),
        isFalse,
      );
    });

    test('rejects absolute and drive/UNC paths', () {
      expect(PathSafety.isSafeArchivePath('/etc/passwd', root), isFalse);
      expect(PathSafety.isSafeArchivePath('C:\\Windows\\system32', root),
          isFalse);
      expect(PathSafety.isSafeArchivePath('\\\\server\\share', root), isFalse);
    });

    test('rejects empty entry', () {
      expect(PathSafety.isSafeArchivePath('', root), isFalse);
    });

    test('normalizes backslash separators before checking', () {
      expect(PathSafety.isSafeArchivePath('lib\\..\\..\\x', root), isFalse);
    });
  });

  group('PathSafety ignored directories & files', () {
    test('detects ignored directories anywhere in the path', () {
      expect(PathSafety.isInIgnoredDirectory('node_modules/lib/x.js'), isTrue);
      expect(PathSafety.isInIgnoredDirectory('app/.git/config'), isTrue);
      expect(PathSafety.isInIgnoredDirectory('build/output.o'), isTrue);
      expect(PathSafety.isInIgnoredDirectory('src/app/main.dart'), isFalse);
    });

    test('detects binary/media files by extension', () {
      expect(PathSafety.isIgnoredFile('logo.png'), isTrue);
      expect(PathSafety.isIgnoredFile('video.mp4'), isTrue);
      expect(PathSafety.isIgnoredFile('lib.so'), isTrue);
      expect(PathSafety.isIgnoredFile('main.dart'), isFalse);
      expect(PathSafety.isIgnoredFile('index.ts'), isFalse);
    });
  });
}
