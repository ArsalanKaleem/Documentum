import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/project_context.dart';
import '../../providers/project_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/stat_card.dart';

class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectState = ref.watch(projectControllerProvider);
    final progress = ref.watch(analysisProgressProvider);
    final project = projectState.valueOrNull;

    if (project == null && progress.phase == AnalysisPhase.idle) {
      return Scaffold(
        body: EmptyState(
          icon: Icons.analytics_outlined,
          title: 'No project analyzed yet',
          message: 'Upload a project archive on the Dashboard to see detected '
              'languages, frameworks and modules here.',
          actionLabel: 'Go to Dashboard',
          onAction: () => context.go('/'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _ProgressCard(progress: progress),
          const SizedBox(height: 24),
          if (project != null) ...[
            _StatsGrid(context: project.context),
            const SizedBox(height: 24),
            _DetectionCard(context: project.context),
            const SizedBox(height: 24),
            if (project.context.modules.isNotEmpty)
              _ModulesCard(modules: project.context.modules),
            const SizedBox(height: 24),
            _FolderCard(tree: project.context.folderStructure),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => context.go('/docs'),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate documentation'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress});
  final AnalysisProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = progress.phase == AnalysisPhase.done;
    final error = progress.phase == AnalysisPhase.error;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  error
                      ? Icons.error_outline
                      : done
                          ? Icons.check_circle_outline
                          : Icons.sync,
                  color: error
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    progress.message.isEmpty
                        ? 'Ready'
                        : progress.message,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress.phase == AnalysisPhase.idle ? 0 : progress.fraction,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.context});
  final ProjectContext context;

  @override
  Widget build(BuildContext c) {
    return GridView.count(
      crossAxisCount: MediaQuery.sizeOf(c).width > 900 ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        StatCard(
          icon: Icons.insert_drive_file_outlined,
          value: '${context.fileCount}',
          label: 'Files scanned',
        ),
        StatCard(
          icon: Icons.format_list_numbered,
          value: '${context.totalLines}',
          label: 'Lines of code',
          color: Colors.teal,
        ),
        StatCard(
          icon: Icons.category_outlined,
          value: '${context.modules.length}',
          label: 'Modules',
          color: Colors.deepPurple,
        ),
        StatCard(
          icon: Icons.source_outlined,
          value: context.hasGitHistory ? 'Yes' : 'No',
          label: 'Git history',
          color: Colors.orange,
        ),
      ],
    );
  }
}

class _DetectionCard extends StatelessWidget {
  const _DetectionCard({required this.context});
  final ProjectContext context;

  @override
  Widget build(BuildContext c) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detection',
                style: Theme.of(c)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DetectionRow(
                label: 'Language', value: context.language, icon: Icons.code),
            DetectionRow(
                label: 'Framework',
                value: context.framework,
                icon: Icons.widgets_outlined),
            DetectionRow(
                label: 'Database',
                value: context.database,
                icon: Icons.storage_outlined),
            DetectionRow(
                label: 'Package manager',
                value: context.packageManager,
                icon: Icons.inventory_2_outlined),
            DetectionRow(
                label: 'Build system',
                value: context.buildSystem,
                icon: Icons.build_outlined),
            DetectionRow(
                label: 'API framework',
                value: context.apiFramework,
                icon: Icons.api_outlined),
            DetectionRow(
                label: 'Authentication',
                value: context.authSystem,
                icon: Icons.lock_outline),
            DetectionRow(
                label: 'Architecture',
                value: context.architecture,
                icon: Icons.account_tree_outlined),
          ],
        ),
      ),
    );
  }
}

class _ModulesCard extends StatelessWidget {
  const _ModulesCard({required this.modules});
  final List<String> modules;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Key modules',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in modules) Chip(label: Text(m)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({required this.tree});
  final String tree;

  @override
  Widget build(BuildContext context) {
    if (tree.trim().isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Folder structure',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(
                tree,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
