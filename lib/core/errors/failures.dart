/// Base type for all recoverable, user-facing failures in the app.
sealed class AppFailure implements Exception {
  const AppFailure(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// ZIP could not be read, was too large, or failed validation.
class ZipFailure extends AppFailure {
  const ZipFailure(super.message, {super.cause});
}

/// A path-traversal or otherwise unsafe entry was detected in the archive.
class SecurityFailure extends AppFailure {
  const SecurityFailure(super.message, {super.cause});
}

/// Project analysis could not complete.
class AnalysisFailure extends AppFailure {
  const AnalysisFailure(super.message, {super.cause});
}

/// An AI provider returned an error, timed out, or was misconfigured.
class AiFailure extends AppFailure {
  const AiFailure(
    super.message, {
    super.cause,
    this.statusCode,
    this.isRateLimit = false,
    this.retryAfterSeconds,
  });

  final int? statusCode;
  final bool isRateLimit;

  /// Seconds to wait before retrying, parsed from a `Retry-After` header when
  /// the provider supplies one.
  final int? retryAfterSeconds;
}

/// Export (ZIP / PDF / Markdown) failed.
class ExportFailure extends AppFailure {
  const ExportFailure(super.message, {super.cause});
}

/// No API key configured for the selected provider.
class ConfigFailure extends AppFailure {
  const ConfigFailure(super.message, {super.cause});
}
