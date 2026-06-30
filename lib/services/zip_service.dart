import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../core/constants/app_constants.dart';
import '../core/errors/failures.dart';
import '../core/utils/path_safety.dart';
import '../models/source_file.dart';

/// Result of extracting an archive: the safe text files plus metadata.
class ZipExtractionResult {
  ZipExtractionResult({
    required this.files,
    required this.rootName,
    required this.hasGit,
    required this.skippedCount,
  });

  final List<SourceFile> files;
  final String rootName;
  final bool hasGit;
  final int skippedCount;
}

/// Extracts uploaded project ZIPs in memory (no disk writes, no code
/// execution) while enforcing size limits and path-traversal protection.
class ZipService {
  /// Validates and extracts [bytes]. CPU-bound work runs in a background
  /// isolate via [compute] so the UI thread stays responsive.
  Future<ZipExtractionResult> extract(Uint8List bytes) async {
    if (bytes.lengthInBytes == 0) {
      throw const ZipFailure('The selected file is empty.');
    }
    if (bytes.lengthInBytes > AppConstants.maxZipBytes) {
      throw const ZipFailure('ZIP exceeds the 100 MB limit.');
    }

    try {
      return await compute(_extractInIsolate, bytes);
    } on SecurityFailure {
      rethrow;
    } catch (e) {
      throw ZipFailure('Could not read the ZIP archive.', cause: e);
    }
  }
}

/// Top-level function executed inside the isolate. Must be top-level (not a
/// closure or instance method) for [compute] to be able to spawn it.
ZipExtractionResult _extractInIsolate(Uint8List bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  final files = <SourceFile>[];
  var skipped = 0;
  var hasGit = false;
  String? rootName;

  for (final entry in archive) {
    if (!entry.isFile) continue;

    final name = entry.name.replaceAll('\\', '/');

    // Track an apparent single root folder for naming.
    final firstSegment = p.split(name).first;
    rootName ??= firstSegment;
    if (rootName != firstSegment) rootName = '';

    // SECURITY: reject anything that would escape the extraction root.
    if (!PathSafety.isSafeArchivePath(name, '/__sandbox__')) {
      throw SecurityFailure('Unsafe path in archive: $name');
    }

    if (name.contains('/.git/') || name.endsWith('/.git')) hasGit = true;

    if (PathSafety.isInIgnoredDirectory(name) ||
        PathSafety.isIgnoredFile(name)) {
      skipped++;
      continue;
    }

    final data = entry.content as List<int>;
    if (data.length > AppConstants.maxFileContentBytes * 8) {
      skipped++;
      continue; // skip very large files entirely
    }

    final String content;
    try {
      content = utf8.decode(data, allowMalformed: false);
    } catch (_) {
      skipped++;
      continue; // not valid UTF-8 → treat as binary, skip
    }

    files.add(
      SourceFile(
        relativePath: name,
        content: content,
        sizeBytes: data.length,
        lineCount: '\n'.allMatches(content).length + 1,
      ),
    );
  }

  if (files.isEmpty) {
    throw const ZipFailure('No readable source files were found in the ZIP.');
  }

  return ZipExtractionResult(
    files: files,
    rootName: (rootName == null || rootName.isEmpty) ? 'project' : rootName,
    hasGit: hasGit,
    skippedCount: skipped,
  );
}
