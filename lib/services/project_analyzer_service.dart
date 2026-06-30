import 'package:path/path.dart' as p;

import '../models/project_context.dart';
import '../models/source_file.dart';
import 'file_scanner_service.dart';

/// Detects the technology stack from marker files and content heuristics and
/// produces the single, shared [ProjectContext]. Runs ONCE per project.
class ProjectAnalyzerService {
  ProjectAnalyzerService(this._scanner);

  final FileScannerService _scanner;

  ProjectContext analyze({
    required String projectName,
    required List<SourceFile> files,
    required bool hasGit,
  }) {
    final scan = _scanner.scan(files);
    final names = files.map((f) => f.fileName.toLowerCase()).toSet();
    final paths = files.map((f) => f.relativePath.toLowerCase()).toList();

    bool has(String fileName) => names.contains(fileName.toLowerCase());
    bool anyPath(bool Function(String) test) => paths.any(test);

    final framework = _detectFramework(files, has);
    final language = _detectLanguage(scan.languageHistogram, framework);
    final packageManager = _detectPackageManager(has, language);
    final database = _detectDatabase(files);
    final apiFramework = _detectApiFramework(files);
    final authSystem = _detectAuth(files);
    final buildSystem = _detectBuildSystem(has, anyPath);
    final architecture = _detectArchitecture(paths);
    final modules = _detectModules(files);

    final technologies = <String>{
      language,
      framework,
      database,
      apiFramework,
      authSystem,
      packageManager,
      buildSystem,
    }..removeWhere((t) => t == 'Unknown' || t == 'None');

    final summary = _buildSummary(
      projectName: projectName,
      language: language,
      framework: framework,
      database: database,
      apiFramework: apiFramework,
      modules: modules,
      fileCount: files.length,
    );

    return ProjectContext(
      name: projectName,
      language: language,
      framework: framework,
      database: database,
      packageManager: packageManager,
      buildSystem: buildSystem,
      apiFramework: apiFramework,
      authSystem: authSystem,
      architecture: architecture,
      modules: modules,
      technologies: technologies.toList(),
      summary: summary,
      folderStructure: scan.folderTree,
      fileCount: files.length,
      totalLines: scan.totalLines,
      hasGitHistory: hasGit,
    );
  }

  String _detectPackageManager(bool Function(String) has, String language) {
    if (has('pubspec.yaml')) return 'pub';
    if (has('pnpm-lock.yaml')) return 'pnpm';
    if (has('yarn.lock')) return 'yarn';
    if (has('package-lock.json') || has('package.json')) return 'npm';
    if (has('requirements.txt') || has('pyproject.toml')) return 'pip';
    if (has('cargo.toml')) return 'cargo';
    if (has('go.mod')) return 'go modules';
    if (has('pom.xml')) return 'maven';
    if (has('build.gradle') || has('build.gradle.kts')) return 'gradle';
    if (has('composer.json')) return 'composer';
    if (has('gemfile')) return 'bundler';
    // Fallback by language when the manifest isn't in the archive (e.g. only a
    // subfolder like lib/ or src/ was zipped).
    return switch (language) {
      'Dart' => 'pub',
      'TypeScript' || 'JavaScript' => 'npm',
      'Python' => 'pip',
      'Rust' => 'cargo',
      'Go' => 'go modules',
      'Java' || 'Kotlin' => 'gradle',
      'PHP' => 'composer',
      'Ruby' => 'bundler',
      _ => 'Unknown',
    };
  }

  String _detectFramework(List<SourceFile> files, bool Function(String) has) {
    final pkg = _readFile(files, 'package.json')?.toLowerCase() ?? '';
    if (has('pubspec.yaml')) {
      final pubspec = _readFile(files, 'pubspec.yaml') ?? '';
      return pubspec.contains('flutter') ? 'Flutter' : 'Dart';
    }
    if (pkg.contains('"next"')) return 'Next.js';
    if (pkg.contains('"nuxt"')) return 'Nuxt';
    if (pkg.contains('"@angular/core"')) return 'Angular';
    if (pkg.contains('"@nestjs/core"')) return 'NestJS';
    if (pkg.contains('"react"')) return 'React';
    if (pkg.contains('"vue"')) return 'Vue';
    if (pkg.contains('"svelte"')) return 'Svelte';
    if (pkg.contains('"express"')) return 'Express';
    if (has('manage.py')) return 'Django';
    if (_anyContains(files, 'from fastapi')) return 'FastAPI';
    if (has('artisan')) return 'Laravel';
    if (_anyContains(files, 'spring-boot') || _anyContains(files, 'org.springframework')) {
      return 'Spring Boot';
    }
    if (has('cargo.toml') && _anyContains(files, 'actix')) return 'Actix';
    if (has('go.mod') && _anyContains(files, 'gin-gonic')) return 'Gin';

    // Content-based fallbacks for when manifests are missing (e.g. only the
    // lib/ or src/ folder was zipped). Detect from the source itself.
    if (_anyContains(files, 'package:flutter/')) return 'Flutter';
    if (_anyContains(files, "from 'react'") ||
        _anyContains(files, 'from "react"')) {
      return 'React';
    }
    if (_anyContains(files, "from 'vue'") || _anyContains(files, 'createapp(')) {
      return 'Vue';
    }
    if (_anyContains(files, 'from fastapi')) return 'FastAPI';
    if (_anyContains(files, 'from django')) return 'Django';
    if (_hasExt(files, '.dart')) return 'Dart';
    return 'Unknown';
  }

  String _detectLanguage(Map<String, int> histogram, String framework) {
    if (framework == 'Flutter' || framework == 'Dart') return 'Dart';
    const extToLang = {
      '.ts': 'TypeScript',
      '.tsx': 'TypeScript',
      '.js': 'JavaScript',
      '.jsx': 'JavaScript',
      '.py': 'Python',
      '.dart': 'Dart',
      '.go': 'Go',
      '.rs': 'Rust',
      '.java': 'Java',
      '.kt': 'Kotlin',
      '.php': 'PHP',
      '.rb': 'Ruby',
      '.cs': 'C#',
      '.cpp': 'C++',
      '.c': 'C',
      '.swift': 'Swift',
    };
    String? best;
    var bestCount = 0;
    for (final entry in histogram.entries) {
      final lang = extToLang[entry.key];
      if (lang != null && entry.value > bestCount) {
        best = lang;
        bestCount = entry.value;
      }
    }
    return best ?? 'Unknown';
  }

  String _detectDatabase(List<SourceFile> files) {
    final blob = _concatLower(files, limit: 200);
    if (blob.contains('postgres') || blob.contains('pg_')) return 'PostgreSQL';
    if (blob.contains('mongodb') || blob.contains('mongoose')) return 'MongoDB';
    if (blob.contains('mysql')) return 'MySQL';
    if (blob.contains('sqlite')) return 'SQLite';
    if (blob.contains('redis')) return 'Redis';
    if (blob.contains('firebase') || blob.contains('firestore')) {
      return 'Firebase';
    }
    if (blob.contains('supabase')) return 'Supabase';
    if (blob.contains('prisma')) return 'Prisma (SQL)';
    return 'Unknown';
  }

  String _detectApiFramework(List<SourceFile> files) {
    final blob = _concatLower(files, limit: 200);
    if (blob.contains('graphql') || blob.contains('apollo')) return 'GraphQL';
    if (blob.contains('@nestjs')) return 'NestJS REST';
    if (blob.contains('express()')) return 'Express REST';
    if (blob.contains('fastapi')) return 'FastAPI REST';
    if (blob.contains('@restcontroller')) return 'Spring REST';
    if (blob.contains('grpc')) return 'gRPC';
    return 'Unknown';
  }

  String _detectAuth(List<SourceFile> files) {
    final blob = _concatLower(files, limit: 200);
    if (blob.contains('next-auth') || blob.contains('authjs')) return 'NextAuth';
    if (blob.contains('passport')) return 'Passport.js';
    if (blob.contains('jsonwebtoken') || blob.contains('jwt')) return 'JWT';
    if (blob.contains('oauth')) return 'OAuth';
    if (blob.contains('clerk')) return 'Clerk';
    if (blob.contains('firebase auth') || blob.contains('firebaseauth')) {
      return 'Firebase Auth';
    }
    if (blob.contains('keycloak')) return 'Keycloak';
    return 'Unknown';
  }

  String _detectBuildSystem(
    bool Function(String) has,
    bool Function(bool Function(String)) anyPath,
  ) {
    if (has('vite.config.ts') || has('vite.config.js')) return 'Vite';
    if (has('webpack.config.js')) return 'Webpack';
    if (has('next.config.js') || has('next.config.mjs')) return 'Next build';
    if (has('build.gradle') || has('build.gradle.kts')) return 'Gradle';
    if (has('pom.xml')) return 'Maven';
    if (has('makefile')) return 'Make';
    if (has('cargo.toml')) return 'Cargo';
    if (has('pubspec.yaml')) return 'Flutter build';
    if (anyPath((path) => path.contains('dockerfile'))) return 'Docker';
    return 'Unknown';
  }

  String _detectArchitecture(List<String> paths) {
    bool dir(String name) => paths.any((path) =>
        path.contains('/$name/') || path.startsWith('$name/'));

    if (dir('domain') && dir('data') && dir('presentation')) {
      return 'Clean Architecture';
    }
    if (dir('controllers') && dir('models') && dir('views')) return 'MVC';
    if (dir('bloc') || dir('blocs') || dir('cubit') || dir('cubits')) {
      return 'BLoC pattern';
    }
    if (dir('features')) return 'Feature-first';
    if (dir('providers') && (dir('repositories') || dir('services'))) {
      return 'Layered (Riverpod/Provider)';
    }
    if (dir('viewmodels') || dir('view_models')) return 'MVVM';
    if (dir('services') && dir('repositories')) return 'Layered';

    // Flutter-style layered: models + a view layer + a logic/widget layer.
    final hasModels = dir('models') || dir('model');
    final hasViews = dir('screens') || dir('views') || dir('pages');
    final hasLogic = dir('services') ||
        dir('controllers') ||
        dir('providers') ||
        dir('widgets');
    if (hasModels && hasViews && hasLogic) return 'Layered (MVVM-style)';

    if (dir('pages') || dir('app')) return 'File-based routing';
    if (dir('services') || dir('repositories')) return 'Service-oriented';
    return 'Unknown';
  }

  /// Treats top-level folders under `src`, `lib`, `app`, or `features` as
  /// candidate modules.
  List<String> _detectModules(List<SourceFile> files) {
    const anchors = ['src/', 'lib/', 'app/', 'features/', 'modules/'];
    final modules = <String>{};
    for (final f in files) {
      final path = f.relativePath.replaceAll('\\', '/').toLowerCase();
      for (final anchor in anchors) {
        final idx = path.indexOf(anchor);
        if (idx == -1) continue;
        final rest = path.substring(idx + anchor.length);
        final segments = p.split(rest);
        if (segments.length >= 2) {
          final candidate = segments.first;
          if (candidate.isNotEmpty && !candidate.contains('.')) {
            modules.add(_titleCase(candidate));
          }
        }
      }
    }
    final list = modules.toList()..sort();
    return list.take(12).toList();
  }

  String _buildSummary({
    required String projectName,
    required String language,
    required String framework,
    required String database,
    required String apiFramework,
    required List<String> modules,
    required int fileCount,
  }) {
    final mods = modules.isEmpty ? 'none detected' : modules.join(', ');
    return '$projectName is a $framework project written primarily in '
        '$language. It uses $database for persistence and exposes a '
        '$apiFramework interface. The codebase contains $fileCount source '
        'files. Key modules: $mods.';
  }

  // ---- helpers -------------------------------------------------------------

  String? _readFile(List<SourceFile> files, String fileName) {
    for (final f in files) {
      if (f.fileName.toLowerCase() == fileName.toLowerCase()) return f.content;
    }
    return null;
  }

  bool _anyContains(List<SourceFile> files, String needle) {
    final lower = needle.toLowerCase();
    return files.any((f) => f.content.toLowerCase().contains(lower));
  }

  bool _hasExt(List<SourceFile> files, String ext) =>
      files.any((f) => f.relativePath.toLowerCase().endsWith(ext));

  String _concatLower(List<SourceFile> files, {required int limit}) {
    final buffer = StringBuffer();
    for (final f in files.take(limit)) {
      buffer.write(f.content.toLowerCase());
      buffer.write('\n');
    }
    return buffer.toString();
  }

  String _titleCase(String input) =>
      input.isEmpty ? input : input[0].toUpperCase() + input.substring(1);
}
