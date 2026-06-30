import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../core/router/app_router.dart';
import '../core/theme/tokens.dart';
import '../core/theme/typography.dart';
import '../models/generated_doc.dart';
import '../providers/coordination_providers.dart';
import '../providers/documentation_providers.dart';
import '../providers/project_providers.dart';
import '../providers/settings_providers.dart';

/// The premium desktop shell: a slim top navigation bar, a collapsible left
/// sidebar with the nine workspace destinations, the center workspace, and a
/// dynamic, collapsible right context panel.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _sidebarExpanded = true;
  bool _rightOpen = true;

  void _go(int index) => widget.navigationShell.goBranch(
    index,
    initialLocation: index == widget.navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 1024;
    final canShowRight = width >= 1280 && _rightOpen;
    final expanded = compact ? false : _sidebarExpanded;

    return Scaffold(
      body: Column(
        children: [
          _TopBar(
            onToggleSidebar: () =>
                setState(() => _sidebarExpanded = !_sidebarExpanded),
            onToggleRight: width >= 1280
                ? () => setState(() => _rightOpen = !_rightOpen)
                : null,
            rightOpen: canShowRight,
          ),
          const Divider(height: 1),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Sidebar(
                  expanded: expanded,
                  currentIndex: widget.navigationShell.currentIndex,
                  onSelect: _go,
                ),
                const VerticalDivider(width: 1),
                Expanded(child: widget.navigationShell),
                if (canShowRight) ...[
                  const VerticalDivider(width: 1),
                  const _RightPanel(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- top bar ----------------------------------------------------------------

class _TopBar extends ConsumerWidget {
  const _TopBar({
    required this.onToggleSidebar,
    required this.onToggleRight,
    required this.rightOpen,
  });
  final VoidCallback onToggleSidebar;
  final VoidCallback? onToggleRight;
  final bool rightOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final project = ref.watch(projectControllerProvider).valueOrNull;
    final width = MediaQuery.sizeOf(context).width;

    return Container(
      height: Sizes.topBar,
      color: scheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Toggle sidebar',
            icon: const Icon(Icons.menu, size: IconSizes.md),
            onPressed: onToggleSidebar,
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Image.asset(
              'assets/logo.png',
              width: 28,
              height: 28,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: Spacing.xs),
          Text(AppConstants.appName,
              style: AppTypography.brand(
                size: 16,
                color: scheme.onSurface,
              )),
          if (project != null) ...[
            const SizedBox(width: Spacing.xs),
            Icon(Icons.chevron_right,
                size: IconSizes.sm, color: scheme.onSurfaceVariant),
            const SizedBox(width: Spacing.xs),
            Flexible(
              child: Text(
                project.context.name,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
          const Spacer(),
          if (width >= 880) ...[
            const _SearchBox(),
            const SizedBox(width: Spacing.sm),
          ],
          const _ProviderStatus(),
          const SizedBox(width: Spacing.xs),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined, size: IconSizes.md),
            onPressed: () => context.go('/settings'),
          ),
          if (onToggleRight != null)
            IconButton(
              tooltip: 'Toggle context panel',
              isSelected: rightOpen,
              icon: const Icon(Icons.view_sidebar_outlined, size: IconSizes.md),
              onPressed: onToggleRight,
            ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 240,
      height: 36,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search…',
          prefixIcon: Icon(Icons.search,
              size: IconSizes.sm, color: scheme.onSurfaceVariant),
          prefixIconConstraints:
          const BoxConstraints(minWidth: 36, minHeight: 36),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }
}

class _ProviderStatus extends ConsumerWidget {
  const _ProviderStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) return const SizedBox.shrink();

    final active = settings.activeProvider;
    final hasKey = settings.hasActiveKey;
    final count = settings.configuredProviders.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: Radii.chip,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(filled: hasKey),
          const SizedBox(width: Spacing.xs),
          Text(active.label, style: theme.textTheme.labelMedium),
          if (count > 1) ...[
            const SizedBox(width: 6),
            Text('+${count - 1}',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

/// A small status dot. Filled = ready; ring = not configured. (No second hue.)
class _Dot extends StatelessWidget {
  const _Dot({required this.filled});
  final bool filled;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? scheme.primary : Colors.transparent,
        border: Border.all(
          color: filled ? scheme.primary : scheme.onSurfaceVariant,
          width: 1.5,
        ),
      ),
    );
  }
}

// --- sidebar ----------------------------------------------------------------

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.expanded,
    required this.currentIndex,
    required this.onSelect,
  });
  final bool expanded;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: Motion.medium,
      curve: Motion.curve,
      width: expanded ? Sizes.sidebarExpanded : Sizes.sidebarCollapsed,
      color: scheme.surface,
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm, vertical: Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < appDestinations.length; i++)
            _NavItem(
              dest: appDestinations[i],
              selected: i == currentIndex,
              expanded: expanded,
              onTap: () => onSelect(i),
            ),
          const Spacer(),
          if (expanded)
            Padding(
              padding: const EdgeInsets.all(Spacing.xs),
              child: Text('v${AppConstants.appVersion}',
                  style: Theme.of(context).textTheme.labelSmall),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.dest,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });
  final AppDestination dest;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final selected = widget.selected;
    final bg = selected
        ? scheme.primary.withValues(alpha: 0.12)
        : _hover
        ? scheme.primary.withValues(alpha: 0.05)
        : Colors.transparent;
    final fg = selected ? scheme.primary : scheme.onSurface;

    final content = Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm, vertical: Spacing.sm),
      child: Row(
        mainAxisAlignment: widget.expanded
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        children: [
          Icon(selected ? widget.dest.selectedIcon : widget.dest.icon,
              size: IconSizes.md, color: fg),
          if (widget.expanded) ...[
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                widget.dest.label,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: fg,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: Motion.fast,
            decoration: BoxDecoration(color: bg, borderRadius: Radii.button),
            child: widget.expanded
                ? content
                : Tooltip(message: widget.dest.label, child: content),
          ),
        ),
      ),
    );
  }
}

// --- right context panel ----------------------------------------------------

class _RightPanel extends ConsumerWidget {
  const _RightPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final project = ref.watch(projectControllerProvider).valueOrNull;
    final progress = ref.watch(analysisProgressProvider);
    final docs = ref.watch(documentationProvider);
    final coord = ref.watch(coordinationProvider).valueOrNull;

    final generating =
        docs.values.where((d) => d.status == DocStatus.generating).length;
    final completed =
        docs.values.where((d) => d.status == DocStatus.completed).length;

    return Container(
      width: Sizes.rightPanel,
      color: scheme.surface,
      child: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          Text('Context', style: theme.textTheme.titleSmall),
          const SizedBox(height: Spacing.sm),
          if (project == null)
            _PanelCard(
              child:
              Text('No project loaded.', style: theme.textTheme.bodySmall),
            )
          else ...[
            _PanelCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Project', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 4),
                  Text(project.context.name, style: theme.textTheme.titleSmall),
                  const SizedBox(height: Spacing.sm),
                  _stat(theme, 'Files', '${project.context.fileCount}'),
                  _stat(theme, 'Lines', '${project.context.totalLines}'),
                  _stat(theme, 'Docs', '$completed/${DocType.values.length}'),
                ],
              ),
            ),
            const SizedBox(height: Spacing.sm),
            if (progress.phase != AnalysisPhase.idle &&
                progress.phase != AnalysisPhase.done)
              _PanelCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Analysis', style: theme.textTheme.labelMedium),
                    const SizedBox(height: Spacing.xs),
                    Text(progress.message, style: theme.textTheme.bodySmall),
                    const SizedBox(height: Spacing.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                          value: progress.fraction, minHeight: 6),
                    ),
                  ],
                ),
              ),
            if (generating > 0)
              _PanelCard(
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: Text('$generating agent(s) running',
                          style: theme.textTheme.bodySmall),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: Spacing.sm),
            _PanelCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recent activity', style: theme.textTheme.labelMedium),
                  const SizedBox(height: Spacing.xs),
                  if (coord?.lastSession == null)
                    Text('No sessions yet.', style: theme.textTheme.bodySmall)
                  else
                    Text(
                      'Last cycle ${coord!.lastSession!.date} · '
                          '${coord.lastSession!.generatedDocumentation.length} docs',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stat(ThemeData theme, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Text(value,
            style: theme.textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: Spacing.xs),
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: Radii.field,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: child,
    );
  }
}