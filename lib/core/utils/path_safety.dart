import 'package:path/path.dart' as p;

import '../constants/app_constants.dart';

/// Security helpers for safely handling untrusted archive contents.
class PathSafety {
  PathSafety._();

  /// Returns true if [entryName] is safe to extract beneath [destRoot].
  ///
  /// Rejects absolute paths, parent-directory escapes (`..`), and any entry
  /// that, once normalized, would resolve outside [destRoot]. This is the
  /// primary defense against "zip slip" path-traversal attacks.
  static bool isSafeArchivePath(String entryName, String destRoot) {
    if (entryName.isEmpty) return false;

    // Normalize separators and reject Windows drive / UNC and absolute paths.
    final normalizedEntry = entryName.replaceAll('\\', '/');
    if (p.isAbsolute(normalizedEntry)) return false;
    if (normalizedEntry.startsWith('/') || normalizedEntry.contains(':')) {
      return false;
    }

    final resolved = p.normalize(p.join(destRoot, normalizedEntry));
    final root = p.normalize(destRoot);

    // The resolved path must live strictly inside the destination root.
    return p.isWithin(root, resolved) || p.equals(root, resolved);
  }

  /// Whether a directory segment should be ignored during extraction/scan.
  static bool isIgnoredDirectory(String segment) =>
      AppConstants.ignoredDirectories.contains(segment);

  /// Whether [relativePath] sits inside any ignored directory.
  static bool isInIgnoredDirectory(String relativePath) {
    final segments = p.split(relativePath.replaceAll('\\', '/'));
    return segments.any(isIgnoredDirectory);
  }

  /// Whether a file should be skipped because it is binary/media.
  static bool isIgnoredFile(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    return AppConstants.ignoredExtensions.contains(ext);
  }
}
