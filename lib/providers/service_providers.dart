import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/project_repository.dart';
import '../repositories/settings_repository.dart';
import '../services/ai/ai_provider_factory.dart';
import '../services/embeddings/embedding_service.dart';
import '../services/export/context_file_service.dart';
import '../services/export/export_service.dart';
import '../services/file_scanner_service.dart';
import '../services/orchestrator/ai_orchestrator.dart';
import '../services/project_analyzer_service.dart';
import '../services/project_brain_service.dart';
import '../services/session_tracker_service.dart';
import '../services/zip_service.dart';
import 'settings_providers.dart';

// ---- stateless services ----------------------------------------------------

final zipServiceProvider = Provider<ZipService>((_) => ZipService());

final fileScannerProvider =
    Provider<FileScannerService>((_) => FileScannerService());

final projectAnalyzerProvider = Provider<ProjectAnalyzerService>(
  (ref) => ProjectAnalyzerService(ref.watch(fileScannerProvider)),
);

final aiProviderFactoryProvider =
    Provider<AiProviderFactory>((_) => AiProviderFactory());

final exportServiceProvider = Provider<ExportService>((_) => ExportService());

final projectBrainServiceProvider =
    Provider<ProjectBrainService>((_) => ProjectBrainService());

final contextFileServiceProvider =
    Provider<ContextFileService>((_) => ContextFileService());

final sessionTrackerProvider =
    Provider<SessionTrackerService>((_) => SessionTrackerService());

final embeddingServiceProvider = Provider<EmbeddingService>(
  (ref) => EmbeddingService(ref.watch(aiProviderFactoryProvider)),
);

// ---- repositories ----------------------------------------------------------

final settingsRepositoryProvider =
    Provider<SettingsRepository>((_) => SettingsRepository());

final projectRepositoryProvider =
    Provider<ProjectRepository>((_) => ProjectRepository());

// ---- orchestrator ----------------------------------------------------------

final orchestratorProvider = Provider<AiOrchestrator>((ref) {
  final settings = ref.watch(settingsRepositoryProvider);
  return AiOrchestrator(
    factory: ref.watch(aiProviderFactoryProvider),
    apiKeyReader: settings.getApiKey,
  );
});
