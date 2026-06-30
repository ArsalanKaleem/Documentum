import 'package:freezed_annotation/freezed_annotation.dart';

import 'ai_provider_config.dart';

part 'generated_doc.freezed.dart';
part 'generated_doc.g.dart';

/// The six documentation artifacts the pipeline can produce.
enum DocType {
  readme('README.md', 'README'),
  api('API.md', 'API'),
  architecture('ARCHITECTURE.md', 'Architecture'),
  installation('INSTALLATION.md', 'Installation'),
  contributing('CONTRIBUTING.md', 'Contributing'),
  changelog('CHANGELOG.md', 'Changelog'),
  recommendations('RECOMMENDATIONS.md', 'Recommendations');

  const DocType(this.fileName, this.label);

  final String fileName;
  final String label;
}

enum DocStatus { pending, generating, completed, failed, cancelled }

/// A single generated documentation file plus its generation metadata.
@freezed
class GeneratedDoc with _$GeneratedDoc {
  const factory GeneratedDoc({
    required DocType type,
    @Default('') String content,
    @Default(DocStatus.pending) DocStatus status,
    String? error,
    String? providerUsed,

    /// The provider assigned to this agent for the current run (set even while
    /// generating, before a result label is available).
    AiProviderType? assignedProvider,

    /// Total tokens reported by the provider, when available.
    int? tokensUsed,

    /// Wall-clock execution time for this agent's call, in milliseconds.
    int? elapsedMs,

    /// Number of retries performed before success/failure.
    @Default(0) int retries,
    DateTime? generatedAt,
  }) = _GeneratedDoc;

  factory GeneratedDoc.fromJson(Map<String, dynamic> json) =>
      _$GeneratedDocFromJson(json);
}
