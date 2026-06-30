import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../models/generated_doc.dart';
import '../../models/project.dart';
import '../../providers/coordination_providers.dart';
import '../../providers/project_providers.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/upload_area.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _process(WidgetRef ref, BuildContext context, Uint8List bytes) async {
    await ref.read(projectControllerProvider.notifier).processZip(bytes);
    if (context.mounted) {
      final state = ref.read(projectControllerProvider);
      if (state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: ${state.error}')),
        );
      } else {
        context.go('/analysis');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectState = ref.watch(projectControllerProvider);
    final recents = ref.watch(recentProjectsProvider);
    final theme = Theme.of(context);
    final busy = projectState.isLoading;
    final project = projectState.valueOrNull;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              AppConstants.appName,
              style: theme.textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Upload a project archive to analyze it and generate professional '
              'documentation with a multi-agent AI pipeline.',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            UploadArea(
              busy: busy,
              onBytes: (bytes) => _process(ref, context, bytes),
            ),
            const SizedBox(height: 32),
            if (project != null) ...[
              Text('Current project',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _ProjectStats(project: project),
              const SizedBox(height: 24),
              const _CoordinationCard(),
              const SizedBox(height: 32),
            ],
            Text('Recent projects',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            recents.when(
              data: (list) => list.isEmpty
                  ? Text(
                      'No projects yet. Your analyzed projects will appear here.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    )
                  : Column(
                      children: [
                        for (final p in list) _RecentTile(project: p),
                      ],
                    ),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Could not load recents: $e'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoordinationCard extends ConsumerWidget {
  const _CoordinationCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brain = ref.watch(projectBrainProvider);
    final coord = ref.watch(coordinationProvider).valueOrNull;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final contextFileCount = coord?.contextFiles.length ?? 0;
    final lastSession = coord?.lastSession;
    final providerUsage = <String, int>{};
    for (final s in coord?.sessions ?? const []) {
      for (final p in s.aiProvidersUsed) {
        providerUsage[p] = (providerUsage[p] ?? 0) + 1;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.hub_outlined, color: scheme.primary),
                const SizedBox(width: 8),
                Text('AI Coordination',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => context.go('/coordination'),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('Open'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _MiniStat(
                  icon: Icons.psychology_outlined,
                  label: 'Project Brain',
                  value: brain != null ? 'Ready' : 'Pending',
                ),
                _MiniStat(
                  icon: Icons.article_outlined,
                  label: 'Context files',
                  value: '$contextFileCount',
                ),
                _MiniStat(
                  icon: Icons.history,
                  label: 'Last session',
                  value: lastSession?.date ?? '—',
                ),
                _MiniStat(
                  icon: Icons.smart_toy_outlined,
                  label: 'Providers used',
                  value: providerUsage.isEmpty
                      ? '—'
                      : '${providerUsage.length}',
                ),
              ],
            ),
            if (brain != null && brain.entryPoints.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Entry points: ${brain.entryPoints.take(3).join(', ')}'
                '${brain.entryPoints.length > 3 ? '…' : ''}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}

class _ProjectStats extends StatelessWidget {
  const _ProjectStats({required this.project});
  final Project project;

  @override
  Widget build(BuildContext context) {
    final ctx = project.context;
    final completedDocs =
        project.docs.where((d) => d.content.isNotEmpty).length;
    return GridView.count(
      crossAxisCount: MediaQuery.sizeOf(context).width > 900 ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        StatCard(
          icon: Icons.insert_drive_file_outlined,
          value: '${ctx.fileCount}',
          label: 'Source files',
        ),
        StatCard(
          icon: Icons.format_list_numbered,
          value: NumberFormat.compact().format(ctx.totalLines),
          label: 'Lines of code',
        ),
        StatCard(
          icon: Icons.code,
          value: ctx.language,
          label: 'Language',
          color: Colors.teal,
        ),
        StatCard(
          icon: Icons.description_outlined,
          value: '$completedDocs/${DocType.values.length}',
          label: 'Docs generated',
          color: Colors.deepPurple,
        ),
      ],
    );
  }
}

class _RecentTile extends ConsumerWidget {
  const _RecentTile({required this.project});
  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctx = project.context;
    final updated = project.updatedAt;
    final subtitle = [
      if (ctx.language != 'Unknown') ctx.language,
      if (ctx.framework != 'Unknown') ctx.framework,
      '${ctx.fileCount} files',
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            ctx.name.isNotEmpty ? ctx.name[0].toUpperCase() : '?',
          ),
        ),
        title: Text(ctx.name),
        subtitle: Text(subtitle),
        trailing: updated != null
            ? Text(
                DateFormat.yMMMd().format(updated),
                style: Theme.of(context).textTheme.bodySmall,
              )
            : null,
        onTap: () {
          ref.read(projectControllerProvider.notifier).setProject(project);
          context.go('/docs');
        },
      ),
    );
  }
}
