import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../models/project_brain.dart';
import '../../providers/coordination_providers.dart';
import '../../widgets/empty_state.dart';

class ProjectBrainScreen extends ConsumerWidget {
  const ProjectBrainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brain = ref.watch(projectBrainProvider);
    final continuation = ref.watch(continuationPromptProvider);

    if (brain == null) {
      return Scaffold(
        body: EmptyState(
          icon: Icons.psychology_outlined,
          title: 'No Project Brain yet',
          message: 'Analyze a project to build its master memory — modules, '
              'dependencies, entry points, and more.',
          actionLabel: 'Go to Dashboard',
          onAction: () => context.go('/'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Brain'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: Spacing.page,
        children: [
          _Hero(brain: brain),
          const SizedBox(height: Spacing.lg),
          _Grid(brain: brain),
          if (continuation != null) ...[
            const SizedBox(height: Spacing.lg),
            _ContinuationCard(text: continuation),
          ],
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.brain});
  final ProjectBrain brain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        borderRadius: Radii.card,
        border: Border.all(color: scheme.outlineVariant),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.10),
            scheme.primary.withValues(alpha: 0.02),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_outlined, color: scheme.primary),
              const SizedBox(width: Spacing.xs),
              Text(brain.name, style: theme.textTheme.headlineMedium),
            ],
          ),
          if (brain.summary.isNotEmpty) ...[
            const SizedBox(height: Spacing.xs),
            Text(brain.summary, style: theme.textTheme.bodyLarge),
          ],
          const SizedBox(height: Spacing.md),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.xs,
            children: [
              for (final t in [
                ...brain.languages,
                ...brain.frameworks,
                if (brain.architecture != 'Unknown') brain.architecture,
              ])
                Chip(label: Text(t)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.brain});
  final ProjectBrain brain;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 1080;
    final sections = <Widget>[
      _Section(
        icon: Icons.account_tree_outlined,
        title: 'Architecture',
        children: [_Para(brain.architecture)],
      ),
      _Section(
        icon: Icons.category_outlined,
        title: 'Modules',
        children: [_Chips(brain.modules)],
      ),
      _Section(
        icon: Icons.bolt_outlined,
        title: 'Entry points',
        children: [_Mono(brain.entryPoints)],
      ),
      _Section(
        icon: Icons.description_outlined,
        title: 'Important files',
        children: [_Mono(brain.importantFiles)],
      ),
      _Section(
        icon: Icons.inventory_2_outlined,
        title: 'Dependencies (${brain.dependencies.length})',
        children: [_Chips(brain.dependencies.take(40).toList())],
      ),
      _Section(
        icon: Icons.menu_book_outlined,
        title: 'Existing documentation',
        children: [_Mono(brain.existingDocumentation)],
      ),
    ];

    if (!wide) {
      return Column(
        children: [
          for (final s in sections) ...[s, const SizedBox(height: Spacing.md)],
        ],
      );
    }
    return Column(
      children: [
        for (var i = 0; i < sections.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: sections[i]),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: i + 1 < sections.length
                      ? sections[i + 1]
                      : const SizedBox(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.children,
  });
  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: Spacing.panel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: IconSizes.md, color: theme.colorScheme.primary),
                const SizedBox(width: Spacing.xs),
                Text(title, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Para extends StatelessWidget {
  const _Para(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text == 'Unknown' ? 'Not conclusively detected.' : text,
        style: Theme.of(context).textTheme.bodyMedium,
      );
}

class _Chips extends StatelessWidget {
  const _Chips(this.items);
  final List<String> items;
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text('None detected.',
          style: Theme.of(context).textTheme.bodySmall);
    }
    return Wrap(
      spacing: Spacing.xs,
      runSpacing: Spacing.xs,
      children: [for (final i in items) Chip(label: Text(i))],
    );
  }
}

class _Mono extends StatelessWidget {
  const _Mono(this.items);
  final List<String> items;
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text('None detected.',
          style: Theme.of(context).textTheme.bodySmall);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final i in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(i,
                style: AppTypography.mono(
                    color: Theme.of(context).colorScheme.onSurface)),
          ),
      ],
    );
  }
}

class _ContinuationCard extends StatelessWidget {
  const _ContinuationCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: Spacing.panel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.smart_toy_outlined,
                    size: IconSizes.md, color: theme.colorScheme.primary),
                const SizedBox(width: Spacing.xs),
                Text('AI Continuation Prompt',
                    style: theme.textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied continuation prompt')),
                    );
                  },
                  icon: const Icon(Icons.copy_all_outlined, size: IconSizes.sm),
                  label: const Text('Copy'),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: Radii.field,
              ),
              child: SelectableText(text, style: AppTypography.mono()),
            ),
          ],
        ),
      ),
    );
  }
}
