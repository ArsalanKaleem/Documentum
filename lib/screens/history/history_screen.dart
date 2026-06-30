import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../models/session_record.dart';
import '../../providers/coordination_providers.dart';
import '../../widgets/empty_state.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coord = ref.watch(coordinationProvider).valueOrNull;
    final sessions = (coord?.sessions ?? const <SessionRecord>[]).reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        automaticallyImplyLeading: false,
        actions: [
          if (sessions.isNotEmpty)
            TextButton.icon(
              onPressed: () =>
                  ref.read(coordinationProvider.notifier).clearHistory(),
              icon: const Icon(Icons.delete_outline, size: IconSizes.sm),
              label: const Text('Clear'),
            ),
          const SizedBox(width: Spacing.md),
        ],
      ),
      body: sessions.isEmpty
          ? const EmptyState(
              icon: Icons.history,
              title: 'No sessions yet',
              message: 'Each documentation generation cycle is recorded here '
                  'with the providers used and what was produced.',
            )
          : ListView.separated(
              padding: Spacing.page,
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
              itemBuilder: (_, i) => _SessionTile(
                record: sessions[i],
                isLatest: i == 0,
              ),
            ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.record, required this.isLatest});
  final SessionRecord record;
  final bool isLatest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: Spacing.panel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.10),
                    borderRadius: Radii.button,
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.bolt_outlined,
                      size: IconSizes.md, color: scheme.primary),
                ),
                const SizedBox(width: Spacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.date, style: theme.textTheme.titleMedium),
                    Text(
                      TimeOfDay.fromDateTime(record.timestamp).format(context),
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
                const Spacer(),
                if (isLatest)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.xs, vertical: 2),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      borderRadius: Radii.chip,
                    ),
                    child: Text('Latest',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: scheme.primary)),
                  ),
              ],
            ),
            if (record.summary.isNotEmpty) ...[
              const SizedBox(height: Spacing.sm),
              Text(record.summary, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: Spacing.sm),
            Wrap(
              spacing: Spacing.xs,
              runSpacing: Spacing.xs,
              children: [
                for (final d in record.generatedDocumentation)
                  Chip(
                    avatar: const Icon(Icons.description_outlined,
                        size: IconSizes.xs),
                    label: Text(d),
                  ),
              ],
            ),
            if (record.aiProvidersUsed.isNotEmpty) ...[
              const SizedBox(height: Spacing.xs),
              Row(
                children: [
                  Icon(Icons.smart_toy_outlined,
                      size: IconSizes.xs, color: scheme.onSurfaceVariant),
                  const SizedBox(width: Spacing.xs),
                  Expanded(
                    child: Text(
                      record.aiProvidersUsed.join('  ·  '),
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
