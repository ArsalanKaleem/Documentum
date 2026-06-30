import 'package:path/path.dart' as p;

import '../models/source_file.dart';

/// Aggregated, structural information derived purely from the file list.
class ScanResult {
  ScanResult({
    required this.folderTree,
    required this.languageHistogram,
    required this.totalLines,
    required this.fileCount,
  });

  final String folderTree;
  final Map<String, int> languageHistogram; // extension -> file count
  final int totalLines;
  final int fileCount;
}

/// Builds a compact, depth-limited folder tree and lightweight statistics that
/// feed the analyzer and the agent prompts.
class FileScannerService {
  ScanResult scan(List<SourceFile> files, {int maxDepth = 4}) {
    final histogram = <String, int>{};
    var totalLines = 0;

    for (final f in files) {
      totalLines += f.lineCount;
      final ext = f.extension.isEmpty ? '(none)' : f.extension;
      histogram.update(ext, (v) => v + 1, ifAbsent: () => 1);
    }

    return ScanResult(
      folderTree: _buildTree(files, maxDepth),
      languageHistogram: Map.fromEntries(
        histogram.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)),
      ),
      totalLines: totalLines,
      fileCount: files.length,
    );
  }

  /// Produces an ASCII tree such as:
  /// lib/
  ///   models/
  ///     project.dart
  ///   main.dart
  String _buildTree(List<SourceFile> files, int maxDepth) {
    final root = _TreeNode('');
    for (final f in files) {
      final segments = p.split(f.relativePath);
      var node = root;
      for (var i = 0; i < segments.length && i < maxDepth; i++) {
        final isFile = i == segments.length - 1;
        node = node.child(segments[i], isFile: isFile);
      }
    }

    final buffer = StringBuffer();
    _render(root, buffer, 0);
    return buffer.toString().trimRight();
  }

  void _render(_TreeNode node, StringBuffer buffer, int depth) {
    final children = node.children.values.toList()
      ..sort((a, b) {
        if (a.isFile != b.isFile) return a.isFile ? 1 : -1;
        return a.name.compareTo(b.name);
      });
    for (final child in children) {
      buffer.writeln('${'  ' * depth}${child.name}${child.isFile ? '' : '/'}');
      _render(child, buffer, depth + 1);
    }
  }
}

class _TreeNode {
  _TreeNode(this.name, {this.isFile = false});

  final String name;
  final bool isFile;
  final Map<String, _TreeNode> children = {};

  _TreeNode child(String name, {required bool isFile}) =>
      children.putIfAbsent(name, () => _TreeNode(name, isFile: isFile));
}
