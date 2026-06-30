/// Global, compile-time constants for the application.
class AppConstants {
  AppConstants._();

  static const String appName = 'Documentum';
  static const String appTagline = 'AI-powered documentation, project memory, and seamless AI handoffs.';
  static const String appVersion = '2.0.0';

  /// Maximum accepted ZIP upload size (100 MB).
  static const int maxZipBytes = 100 * 1024 * 1024;

  /// Directories that are never extracted or scanned.
  static const Set<String> ignoredDirectories = {
    'node_modules',
    '.git',
    '.svn',
    '.hg',
    'build',
    'dist',
    'target',
    'out',
    '.dart_tool',
    '.idea',
    '.vscode',
    '__pycache__',
    'venv',
    '.venv',
    'vendor',
    'Pods',
    '.gradle',
    'bin',
    'obj',
  };

  /// File extensions treated as binary / media and skipped during analysis.
  static const Set<String> ignoredExtensions = {
    // images
    '.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp', '.ico', '.svg', '.tiff',
    // audio / video
    '.mp3', '.wav', '.flac', '.ogg', '.mp4', '.mov', '.avi', '.mkv', '.webm',
    // archives & binaries
    '.zip', '.tar', '.gz', '.rar', '.7z', '.exe', '.dll', '.so', '.dylib',
    '.bin', '.o', '.a', '.class', '.jar', '.wasm', '.pdf',
    // fonts
    '.ttf', '.otf', '.woff', '.woff2', '.eot',
    // misc
    '.lock', '.log', '.map',
  };

  /// Maximum number of bytes read from any single source file when building
  /// AI context (keeps prompts within token budgets).
  static const int maxFileContentBytes = 64 * 1024;

  /// Hard cap on the number of files included verbatim in a single agent prompt.
  static const int maxFilesPerPrompt = 25;

  static const List<String> documentFileNames = [
    'README.md',
    'API.md',
    'ARCHITECTURE.md',
    'INSTALLATION.md',
    'CONTRIBUTING.md',
    'CHANGELOG.md',
  ];
}