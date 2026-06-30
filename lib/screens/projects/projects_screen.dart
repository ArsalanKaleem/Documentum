import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/tokens.dart';
import '../../models/generated_doc.dart';
import '../../models/project.dart';
import '../../providers/project_providers.dart';
import '../../widgets/empty_state.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recents = ref.watch(recentProjectsProvider);
    final active = ref.watch(projectControllerProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        automaticallyImplyLeading: false,
        actions: [
          FilledButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.add, size: IconSizes.sm),
            label: const Text('New project'),
          ),
          const SizedBox(width: Spacing.md),
        ],
      ),
      body: recents.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load: $e')),
        data: (list) {
          if (list.isEmpty && active == null) {
            return EmptyState(
              icon: Icons.folder_open_outlined,
              title: 'No projects yet',
              message: 'Upload a project archive to analyze it and generate '
                  'documentation.',
              actionLabel: 'Upload a project',
              onAction: () => context.go('/'),
            );
          }
          return GridView.extent(
            padding: Spacing.page,
            maxCrossAxisExtent: 380,
            mainAxisSpacing: Spacing.md,
            crossAxisSpacing: Spacing.md,
            childAspectRatio: 1.7,
            children: [
              for (final p in list)
                _ProjectCard(
                  project: p,
                  isActive: active?.id == p.id,
                  onOpen: () {
                    ref.read(projectControllerProvider.notifier).setProject(p);
                    context.go('/analysis');
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ProjectCard extends StatefulWidget {
  const _ProjectCard({
    required this.project,
    required this.isActive,
    required this.onOpen,
  });

  final Project project;
  final bool isActive;
  final VoidCallback onOpen;

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ctx = widget.project.context;
    final dark = theme.brightness == Brightness.dark;
    final subtitle = [
      if (ctx.language != 'Unknown') ctx.language,
      if (ctx.framework != 'Unknown') ctx.framework,
    ].join(' · ');

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: Motion.fast,
        curve: Motion.curve,
        transform: _hover
            ? Matrix4.translationValues(0, -2, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: Radii.card,
          border: Border.all(
            color: widget.isActive ? scheme.primary : scheme.outlineVariant,
            width: widget.isActive ? Borders.medium : Borders.thin,
          ),
          boxShadow: _hover ? Shadows.raised(dark) : Shadows.card(dark),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onOpen,
            borderRadius: Radii.card,
            child: Padding(
              padding: Spacing.panel,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.10),
                          borderRadius: Radii.button,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          ctx.name.isNotEmpty ? ctx.name[0].toUpperCase() : '?',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: scheme.primary),
                        ),
                      ),
                      const Spacer(),
                      if (widget.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: Spacing.xs, vertical: 2),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.12),
                            borderRadius: Radii.chip,
                          ),
                          child: Text('Active',
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: scheme.primary)),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(ctx.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge),
                  if (subtitle.isNotEmpty)
                    Text(subtitle, style: theme.textTheme.bodySmall),
                  const SizedBox(height: Spacing.sm),
                  Row(
                    children: [
                      _meta(theme, Icons.insert_drive_file_outlined,
                          '${ctx.fileCount} files'),
                      const SizedBox(width: Spacing.md),
                      _meta(theme, Icons.description_outlined,
                          '${widget.project.docs.where((d) => d.content.isNotEmpty).length}/${DocType.values.length} docs'),
                      const Spacer(),
                      if (widget.project.updatedAt != null)
                        Text(
                          DateFormat.MMMd().format(widget.project.updatedAt!),
                          style: theme.textTheme.labelSmall,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _meta(ThemeData theme, IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: IconSizes.xs, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      );
}
