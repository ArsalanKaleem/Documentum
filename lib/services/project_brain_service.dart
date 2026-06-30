import '../models/project_brain.dart';
import '../models/project_context.dart';
import '../models/source_file.dart';

/// Builds a [ProjectBrain] from the shared [ProjectContext] and scanned files.
///
/// This performs NO additional repository I/O — it only distils information that
/// was already gathered during analysis, so the "analyze once" guarantee holds.
class ProjectBrainService {
  ProjectBrain build({
    required ProjectContext context,
    required List<SourceFile> files,
  }) {
    return ProjectBrain(
      name: context.name,
      languages: _languages(context, files),
      frameworks: _split(context.framework),
      databases: _split(context.database),
      architecture: context.architecture,
      folderStructure: context.folderStructure,
      modules: context.modules,
      importantFiles: _importantFiles(files),
      entryPoints: _entryPoints(files),
      dependencies: _dependencies(files),
      existingDocumentation: _existingDocs(files),
      hasGitHistory: context.hasGitHistory,
      fileCount: context.fileCount,
      totalLines: context.totalLines,
      summary: context.summary,
    );
  }

  List<String> _split(String value) =>
      (value.isEmpty || value == 'Unknown') ? const [] : [value];

  List<String> _languages(ProjectContext context, List<SourceFile> files) {
    final counts = <String, int>{};
    for (final f in files) {
      final ext = f.extension;
      if (ext.isEmpty) continue;
      counts[ext] = (counts[ext] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    const extToLang = {
      '.dart': 'Dart',
      '.ts': 'TypeScript',
      '.tsx': 'TypeScript',
      '.js': 'JavaScript',
      '.jsx': 'JavaScript',
      '.py': 'Python',
      '.go': 'Go',
      '.rs': 'Rust',
      '.java': 'Java',
      '.kt': 'Kotlin',
      '.rb': 'Ruby',
      '.php': 'PHP',
      '.cs': 'C#',
      '.swift': 'Swift',
      '.cpp': 'C++',
      '.c': 'C',
    };
    final langs = <String>[];
    for (final e in sorted) {
      final lang = extToLang[e.key];
      if (lang != null && !langs.contains(lang)) langs.add(lang);
      if (langs.length >= 4) break;
    }
    if (langs.isEmpty && context.language != 'Unknown') {
      langs.add(context.language);
    }
    return langs;
  }

  static const _entryNames = {
    'main.dart',
    'index.ts',
    'index.js',
    'server.ts',
    'server.js',
    'app.ts',
    'app.js',
    'main.py',
    'app.py',
    'main.go',
    'main.rs',
    'program.cs',
  };

  List<String> _entryPoints(List<SourceFile> files) => files
      .where((f) => _entryNames.contains(f.fileName.toLowerCase()))
      .map((f) => f.relativePath)
      .toList();

  static const _importantNames = {
    'package.json',
    'pubspec.yaml',
    'cargo.toml',
    'go.mod',
    'requirements.txt',
    'pyproject.toml',
    'pom.xml',
    'build.gradle',
    'dockerfile',
    'docker-compose.yml',
    'makefile',
    '.env.example',
    'tsconfig.json',
  };

  List<String> _importantFiles(List<SourceFile> files) {
    final result = <String>[];
    for (final f in files) {
      final name = f.fileName.toLowerCase();
      final path = f.relativePath.toLowerCase();
      final looksRouting = path.contains('router') ||
          path.contains('routes') ||
          path.contains('route');
      final looksKeyApp = name == 'main.dart' ||
          name == 'app.dart' ||
          name == 'index.ts' ||
          name == 'index.js' ||
          name == 'app.tsx' ||
          name == 'app.jsx' ||
          name == 'server.ts' ||
          name == 'server.js' ||
          name.startsWith('main.') ||
          path.contains('/config') ||
          path.contains('theme') ||
          name == 'firebase_options.dart';
      final looksConfig = _importantNames.contains(name);
      if (looksConfig || looksRouting || looksKeyApp) {
        result.add(f.relativePath);
      }
    }
    // De-duplicate while preserving order.
    final seen = <String>{};
    return result.where(seen.add).take(40).toList();
  }

  List<String> _existingDocs(List<SourceFile> files) => files
      .where((f) {
        final name = f.fileName.toLowerCase();
        return name.endsWith('.md') ||
            name == 'readme' ||
            name.startsWith('readme.');
      })
      .map((f) => f.relativePath)
      .take(30)
      .toList();

  /// Parses dependency names from the most common manifest formats, falling
  /// back to scanning source imports when no manifest is present (e.g. only a
  /// subfolder was zipped).
  List<String> _dependencies(List<SourceFile> files) {
    final deps = <String>{};

    for (final f in files) {
      final name = f.fileName.toLowerCase();
      if (name == 'package.json') {
        deps.addAll(_jsonDeps(f.content));
      } else if (name == 'pubspec.yaml') {
        deps.addAll(_yamlDeps(f.content));
      } else if (name == 'requirements.txt') {
        for (final line in f.content.split('\n')) {
          final dep = line.split(RegExp(r'[=<>~!\s]')).first.trim();
          if (dep.isNotEmpty && !dep.startsWith('#')) deps.add(dep);
        }
      }
    }

    // Fallback: derive third-party packages from imports.
    if (deps.length < 3) {
      deps.addAll(_importPackages(files));
    }

    final list = deps.toList()..sort();
    return list.take(60).toList();
  }

  /// Extracts external package names from Dart `package:` imports and
  /// JS/TS bare module imports.
  Iterable<String> _importPackages(List<SourceFile> files) {
    final pkgs = <String>{};
    final dartImport = RegExp(r'''import\s+['"]package:([a-zA-Z0-9_]+)/''');
    final jsImport =
        RegExp(r'''(?:import\s+.*?from|require\()\s*['"]([^./][^'"]*)['"]''');

    for (final f in files) {
      final ext = f.extension;
      if (ext == '.dart') {
        for (final m in dartImport.allMatches(f.content)) {
          final pkg = m.group(1);
          // Skip the project's own package and the Flutter SDK itself.
          if (pkg != null && pkg != 'flutter') pkgs.add(pkg);
        }
      } else if (ext == '.ts' || ext == '.tsx' || ext == '.js' || ext == '.jsx') {
        for (final m in jsImport.allMatches(f.content)) {
          var pkg = m.group(1);
          if (pkg == null) continue;
          // Normalize scoped/sub-path imports to the package root.
          if (pkg.startsWith('@')) {
            final parts = pkg.split('/');
            pkg = parts.length >= 2 ? '${parts[0]}/${parts[1]}' : pkg;
          } else {
            pkg = pkg.split('/').first;
          }
          pkgs.add(pkg);
        }
      }
    }
    return pkgs;
  }

  Iterable<String> _jsonDeps(String content) {
    final result = <String>[];
    final blocks = RegExp(
      r'"(?:dependencies|devDependencies)"\s*:\s*\{([^}]*)\}',
      dotAll: true,
    ).allMatches(content);
    for (final b in blocks) {
      final body = b.group(1) ?? '';
      for (final m in RegExp(r'"([^"]+)"\s*:').allMatches(body)) {
        final dep = m.group(1);
        if (dep != null) result.add(dep);
      }
    }
    return result;
  }

  Iterable<String> _yamlDeps(String content) {
    final result = <String>[];
    final lines = content.split('\n');
    var inDeps = false;
    for (final line in lines) {
      final trimmed = line.trimRight();
      if (RegExp(r'^(dependencies|dev_dependencies):').hasMatch(trimmed)) {
        inDeps = true;
        continue;
      }
      if (inDeps) {
        if (trimmed.isNotEmpty && !trimmed.startsWith(' ')) {
          inDeps = false;
          continue;
        }
        final m = RegExp(r'^\s{2}([a-zA-Z0-9_]+):').firstMatch(line);
        final dep = m?.group(1);
        if (dep != null && dep != 'flutter' && dep != 'sdk') result.add(dep);
      }
    }
    return result;
  }
}
