import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../models/ai_provider_config.dart';
import '../../models/generated_doc.dart';
import '../../providers/coordination_providers.dart';
import '../../providers/documentation_providers.dart';
import '../../providers/project_providers.dart';
import '../../providers/settings_providers.dart';
import '../../widgets/empty_state.dart';

class CoordinationScreen extends ConsumerWidget {
  const CoordinationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectControllerProvider).valueOrNull;
    final docs = ref.watch(documentationProvider);
    final notifier = ref.read(documentationProvider.notifier);
    final settings = ref.watch(settingsProvider).valueOrNull;

    if (project == null) {
      return Scaffold(
        body: EmptyState(
          icon: Icons.hub_outlined,
          title: 'No project loaded',
          message:
              'Analyze a project to coordinate AI agents across providers.',
          actionLabel: 'Go to Dashboard',
          onAction: () => context.go('/'),
        ),
      );
    }

    final generating = notifier.isGenerating;
    final autoMode = settings?.agentConfig.autoMode ?? false;

    return Scaffold(
      body: ListView(
        padding: Spacing.page,
        children: [
          _Header(
            generating: generating,
            autoMode: autoMode,
            onRun: generating ? null : () => notifier.generateAll(),
            onCancel: notifier.cancel,
          ),
          const SizedBox(height: Spacing.lg),
          _SummaryStrip(docs: docs.values.toList()),
          const SizedBox(height: Spacing.lg),
          _AgentGrid(docs: docs),
          const SizedBox(height: Spacing.xl),
          const _ContextFilesSection(),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.generating,
    required this.autoMode,
    required this.onRun,
    required this.onCancel,
  });
  final bool generating;
  final bool autoMode;
  final VoidCallback? onRun;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AI Coordination Center',
                  style: theme.textTheme.displaySmall),
              const SizedBox(height: 4),
              Text(
                'Multiple providers generate documentation in parallel, each '
                'agent on its assigned model.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: Spacing.md),
        if (autoMode)
          Padding(
            padding: const EdgeInsets.only(right: Spacing.xs),
            child: Chip(
              avatar: const Icon(Icons.auto_mode, size: IconSizes.sm),
              label: const Text('Auto routing'),
            ),
          ),
        if (generating)
          Padding(
            padding: const EdgeInsets.only(right: Spacing.xs),
            child: OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.stop_circle_outlined, size: IconSizes.sm),
              label: const Text('Cancel'),
            ),
          ),
        FilledButton.icon(
          onPressed: onRun,
          icon: generating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_arrow, size: IconSizes.md),
          label: Text(generating ? 'Running…' : 'Run all (parallel)'),
        ),
      ],
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.docs});
  final List<GeneratedDoc> docs;

  @override
  Widget build(BuildContext context) {
    final completed =
        docs.where((d) => d.status == DocStatus.completed).length;
    final failed = docs.where((d) => d.status == DocStatus.failed).length;
    final running =
        docs.where((d) => d.status == DocStatus.generating).length;
    final tokens = docs.fold<int>(0, (s, d) => s + (d.tokensUsed ?? 0));
    final providers = <AiProviderType>{
      for (final d in docs)
        if (d.assignedProvider != null) d.assignedProvider!,
    }.length;

    final items = [
      ('Completed', '$completed/${DocType.values.length}', Icons.check_circle_outline),
      ('Running', '$running', Icons.sync),
      ('Failed', '$failed', Icons.error_outline),
      ('Providers', '$providers', Icons.hub_outlined),
      ('Tokens', tokens > 0 ? _fmt(tokens) : '—', Icons.token_outlined),
    ];

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(child: _StatBox(items[i])),
          if (i < items.length - 1) const SizedBox(width: Spacing.sm),
        ],
      ],
    );
  }

  static String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}

class _StatBox extends StatelessWidget {
  const _StatBox(this.data);
  final (String, String, IconData) data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: Radii.card,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.$3, size: IconSizes.md, color: scheme.primary),
          const SizedBox(height: Spacing.xs),
          Text(data.$2,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          Text(data.$1, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _AgentGrid extends StatelessWidget {
  const _AgentGrid({required this.docs});
  final Map<DocType, GeneratedDoc> docs;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width > 1500 ? 3 : (width > 980 ? 2 : 1);
    final cardWidth =
        (width - Spacing.page.horizontal - (columns - 1) * Spacing.md) /
            columns;

    return Wrap(
      spacing: Spacing.md,
      runSpacing: Spacing.md,
      children: [
        for (final type in DocType.values)
          SizedBox(
            width: columns == 1 ? double.infinity : cardWidth,
            child: _AgentCard(doc: docs[type]!),
          ),
      ],
    );
  }
}

class _AgentCard extends ConsumerWidget {
  const _AgentCard({required this.doc});
  final GeneratedDoc doc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = doc.status;
    final provider = doc.assignedProvider?.label ?? '—';
    final collapsed = status == DocStatus.completed;

    return AnimatedContainer(
      duration: Motion.medium,
      curve: Motion.curve,
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: Radii.card,
        border: Border.all(
          color: status == DocStatus.generating
              ? scheme.primary.withValues(alpha: 0.5)
              : scheme.outlineVariant,
          width: status == DocStatus.generating ? Borders.medium : Borders.thin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.10),
                  borderRadius: Radii.button,
                ),
                alignment: Alignment.center,
                child: Icon(_agentIcon(doc.type),
                    size: IconSizes.md, color: scheme.primary),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${doc.type.label} Agent',
                        style: theme.textTheme.titleSmall),
                    Text(doc.type.fileName,
                        style: AppTypography.mono(
                            size: 11, color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          _ProgressBar(status: status),
          const SizedBox(height: Spacing.sm),
          if (!collapsed)
            Row(
              children: [
                _meta(theme, Icons.smart_toy_outlined, provider),
                const Spacer(),
                _meta(theme, Icons.percent, _completion(status)),
              ],
            ),
          if (!collapsed) const SizedBox(height: Spacing.xs),
          Row(
            children: [
              _meta(theme, Icons.timer_outlined,
                  doc.elapsedMs != null
                      ? '${(doc.elapsedMs! / 1000).toStringAsFixed(1)}s'
                      : '—'),
              const SizedBox(width: Spacing.md),
              _meta(theme, Icons.token_outlined,
                  doc.tokensUsed != null ? '${doc.tokensUsed}' : '—'),
              const SizedBox(width: Spacing.md),
              _meta(theme, Icons.refresh,
                  doc.retries > 0 ? '${doc.retries}×' : '0'),
              const Spacer(),
              if (collapsed)
                _meta(theme, Icons.smart_toy_outlined, provider),
            ],
          ),
          if (status == DocStatus.failed) ...[
            const SizedBox(height: Spacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Spacing.sm),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: Radii.field,
              ),
              child: Text(
                doc.error ?? 'Generation failed.',
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () =>
                    ref.read(documentationProvider.notifier).regenerate(doc.type),
                icon: const Icon(Icons.refresh, size: IconSizes.sm),
                label: const Text('Retry'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _meta(ThemeData theme, IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: IconSizes.xs, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(text, style: theme.textTheme.labelSmall),
        ],
      );

  String _completion(DocStatus s) => switch (s) {
        DocStatus.completed => '100%',
        DocStatus.generating => '…',
        DocStatus.failed => '—',
        DocStatus.cancelled => '—',
        DocStatus.pending => '0%',
      };

  IconData _agentIcon(DocType t) => switch (t) {
        DocType.readme => Icons.menu_book_outlined,
        DocType.api => Icons.api_outlined,
        DocType.architecture => Icons.account_tree_outlined,
        DocType.installation => Icons.download_outlined,
        DocType.contributing => Icons.handshake_outlined,
        DocType.changelog => Icons.history_toggle_off_outlined,
        DocType.recommendations => Icons.lightbulb_outline,
      };
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final DocStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (label, icon) = switch (status) {
      DocStatus.completed => ('Done', Icons.check_circle),
      DocStatus.generating => ('Running', Icons.sync),
      DocStatus.failed => ('Failed', Icons.error_outline),
      DocStatus.cancelled => ('Cancelled', Icons.cancel_outlined),
      DocStatus.pending => ('Idle', Icons.circle_outlined),
    };
    // Failed reads as heavier/filled; others use outline tones. No second hue.
    final emphasized = status == DocStatus.failed;
    final bg = status == DocStatus.completed
        ? scheme.primary.withValues(alpha: 0.12)
        : emphasized
            ? scheme.onSurface.withValues(alpha: 0.10)
            : scheme.surfaceContainerHigh;
    final fg = status == DocStatus.completed ? scheme.primary : scheme.onSurface;

    if (status == DocStatus.generating) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 4),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.10),
          borderRadius: Radii.chip,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 11,
              height: 11,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: scheme.primary),
            ),
            const SizedBox(width: 6),
            Text(label,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: scheme.primary)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: Radii.chip),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: IconSizes.xs, color: fg),
          const SizedBox(width: 4),
          Text(label,
              style: theme.textTheme.labelSmall?.copyWith(color: fg)),
        ],
      ),
    );
  }
}

/// A progress bar that conveys state without a second hue: a solid fill for
/// completed, an animated indeterminate sweep for running, an empty track for
/// idle, and a muted full track for failed/cancelled.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.status});
  final DocStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final track = scheme.primary.withValues(alpha: 0.10);

    Widget bar;
    switch (status) {
      case DocStatus.completed:
        bar = FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: 1,
          child: Container(color: scheme.primary),
        );
      case DocStatus.generating:
        bar = LinearProgressIndicator(
          backgroundColor: track,
          color: scheme.primary,
        );
      case DocStatus.failed:
      case DocStatus.cancelled:
        bar = FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: 1,
          child: Container(color: scheme.onSurface.withValues(alpha: 0.18)),
        );
      case DocStatus.pending:
        bar = const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 6,
        color: track,
        child: bar,
      ),
    );
  }
}

class _ContextFilesSection extends ConsumerWidget {
  const _ContextFilesSection();

  Future<void> _save(BuildContext context, String name, String content) async {
    final path = await FilePicker.platform.saveFile(
      fileName: name,
      bytes: Uint8List.fromList(utf8.encode(content)),
    );
    if (context.mounted && path != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Saved $name')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final coord = ref.watch(coordinationProvider).valueOrNull;
    final files = coord?.contextFiles ?? const {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('AI handoff & memory', style: theme.textTheme.headlineSmall),
            const Spacer(),
            TextButton.icon(
              onPressed: () => ref.read(coordinationProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh, size: IconSizes.sm),
              label: const Text('Rebuild'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Generated from the Project Brain — hand off to any AI without losing '
          'context.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: Spacing.md),
        if (files.isEmpty)
          Container(
            width: double.infinity,
            padding: Spacing.panel,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: Radii.card,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Text(
              'Run the agents to generate AI_CONTEXT.md, PROJECT_BRAIN.md, '
              'SESSION_SUMMARY.md and AI_CONTINUATION_PROMPT.md.',
              style: theme.textTheme.bodyMedium,
            ),
          )
        else
          Wrap(
            spacing: Spacing.md,
            runSpacing: Spacing.md,
            children: [
              for (final entry in files.entries)
                SizedBox(
                  width: 320,
                  child: _FileCard(
                    name: entry.key,
                    content: entry.value,
                    onSave: () => _save(context, entry.key, entry.value),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _FileCard extends StatelessWidget {
  const _FileCard({
    required this.name,
    required this.content,
    required this.onSave,
  });
  final String name;
  final String content;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: Radii.card,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.article_outlined,
                  size: IconSizes.md, color: scheme.primary),
              const SizedBox(width: Spacing.xs),
              Expanded(
                child: Text(name,
                    style: theme.textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          Text('${content.split('\n').length} lines',
              style: theme.textTheme.labelSmall),
          const SizedBox(height: Spacing.sm),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Copied $name')),
                  );
                },
                icon: const Icon(Icons.copy_all_outlined, size: IconSizes.sm),
                label: const Text('Copy'),
              ),
              const SizedBox(width: Spacing.xs),
              OutlinedButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.download_outlined, size: IconSizes.sm),
                label: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
