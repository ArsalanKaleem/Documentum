import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../providers/settings_providers.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settings = ref.watch(settingsProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: Spacing.page,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Hero
                  _AppHero(scheme: scheme, theme: theme),
                  const SizedBox(height: Spacing.xl),

                  // Developer Card
                  _SectionCard(
                    icon: Icons.person_outline,
                    title: 'Developer',
                    child: Column(
                      children: [
                        // Circular photo
                        Center(
                          child: Container(
                            width: 140,
                            height: 140,
                            margin:
                            const EdgeInsets.only(bottom: Spacing.lg),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                scheme.primary.withValues(alpha: 0.10),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                  scheme.primary.withValues(alpha: 0.14),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/dev-pfp.png',
                                width: 108,
                                height: 108,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: scheme.primary
                                      .withValues(alpha: 0.10),
                                  child: Icon(Icons.person,
                                      size: 52, color: scheme.primary),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Name + title
                        Center(
                          child: Column(
                            children: [
                              Text(
                                // ── CHANGE YOUR NAME HERE ──
                                'Arsalan Kaleem',
                                style: AppTypography.brand(
                                  size: 22,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                // ── CHANGE YOUR TITLE HERE ──
                                'Full-Stack AI Application Developerr',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: Spacing.lg),

                        // Social links row
                        _SocialRow(scheme: scheme, theme: theme),
                        const SizedBox(height: Spacing.lg),

                        // Info rows
                        _InfoRow(
                          label: 'Email',
                          // ── CHANGE YOUR EMAIL HERE ──
                          value: 'arsalanabbasi.here@gmail.com',
                          icon: Icons.email_outlined,
                          copyable: true,
                        ),
                        _InfoRow(
                          label: 'Location',
                          // ── CHANGE YOUR LOCATION HERE ──
                          value: 'Karachi, Sindh',
                          icon: Icons.location_on_outlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Spacing.md),

                  // App Info Card
                  _SectionCard(
                    icon: Icons.info_outline,
                    title: 'Application',
                    child: Column(
                      children: [
                        _InfoRow(
                          label: 'App name',
                          value: AppConstants.appName,
                          icon: Icons.description_outlined,
                        ),
                        _InfoRow(
                          label: 'Version',
                          value: 'v${AppConstants.appVersion}',
                          icon: Icons.tag_outlined,
                        ),
                        _InfoRow(
                          label: 'Platform',
                          value: 'Windows · macOS · Linux · Web',
                          icon: Icons.devices_outlined,
                        ),
                        _InfoRow(
                          label: 'License',
                          value: 'MIT',
                          icon: Icons.gavel_outlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Spacing.md),

                  // What it does
                  _SectionCard(
                    icon: Icons.description_outlined,
                    title: 'What this app does',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        AppConstants.appTagline +
                            '\n\nDocumentum analyzes any software project '
                                'archive and generates six professional '
                                'documentation files in parallel — README, API, '
                                'Architecture, Installation, Contributing, and '
                                'Changelog — using multiple AI providers '
                                'simultaneously. It also provides a RAG-powered '
                                'codebase chat, a Project Brain knowledge base, '
                                'AI handoff files for seamless context transfer '
                                'between AI assistants, and a development session '
                                'tracker.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.md),

                  // Tech stack
                  _SectionCard(
                    icon: Icons.layers_outlined,
                    title: 'Built with',
                    child: Wrap(
                      spacing: Spacing.xs,
                      runSpacing: Spacing.xs,
                      children: const [
                        _TechChip('Flutter'),
                        _TechChip('Dart'),
                        _TechChip('Riverpod'),
                        _TechChip('GoRouter'),
                        _TechChip('Freezed'),
                        _TechChip('Dio'),
                        _TechChip('Instrument Sans'),
                        _TechChip('Poppins'),
                        _TechChip('Google Gemini'),
                        _TechChip('Groq'),
                        _TechChip('OpenRouter'),
                        _TechChip('NVIDIA NIM'),
                        _TechChip('Cerebras'),
                        _TechChip('SambaNova'),
                        _TechChip('flutter_secure_storage'),
                        _TechChip('pdf / printing'),
                        _TechChip('flutter_markdown'),
                      ],
                    ),
                  ),
                  const SizedBox(height: Spacing.md),

                  // Configured providers
                  if (settings != null) ...[
                    _SectionCard(
                      icon: Icons.hub_outlined,
                      title: 'Configured providers',
                      child: settings.configuredProviders.isEmpty
                          ? Text(
                        'No providers configured yet. '
                            'Add API keys in Settings.',
                        style: theme.textTheme.bodyMedium,
                      )
                          : Wrap(
                        spacing: Spacing.xs,
                        runSpacing: Spacing.xs,
                        children: [
                          for (final p in settings.configuredProviders)
                            Chip(
                              avatar: Icon(Icons.check_circle,
                                  size: IconSizes.xs,
                                  color: scheme.primary),
                              label: Text(p.label),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                  ],

                  // Credits
                  _SectionCard(
                    icon: Icons.favorite_outline,
                    title: 'Credits',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Built with Claude (Anthropic) as the AI development '
                              'assistant. Fonts by Google Fonts (Poppins, '
                              'Instrument Sans, JetBrains Mono). Icons from '
                              'Material Symbols. Free API tiers provided by '
                              'Google AI Studio, Groq, OpenRouter, NVIDIA NIM, '
                              'Cerebras, and SambaNova.',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: Spacing.md),
                        Text(
                          // ── CHANGE YOUR NAME HERE TOO ──
                          '© 2026 Arsalan Kaleem. All rights reserved.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Spacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// App hero
// ---------------------------------------------------------------------------

class _AppHero extends StatelessWidget {
  const _AppHero({required this.scheme, required this.theme});
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.xl),
      decoration: BoxDecoration(
        borderRadius: Radii.card,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.12),
            scheme.primary.withValues(alpha: 0.03),
          ],
        ),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              'assets/logo.png',
              width: 104,
              height: 104,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: Spacing.md),
          Text(
            AppConstants.appName,
            style: AppTypography.brand(
              size: 30,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppConstants.appTagline,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: Spacing.sm, vertical: 4),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              borderRadius: Radii.chip,
            ),
            child: Text(
              'v${AppConstants.appVersion}',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: scheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Social links row
// ---------------------------------------------------------------------------

class _SocialRow extends StatelessWidget {
  const _SocialRow({required this.scheme, required this.theme});
  final ColorScheme scheme;
  final ThemeData theme;

  Future<void> _open(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── CHANGE YOUR LINKS HERE ──
    const socials = [
      (
      icon: Icons.code,
      label: 'GitHub',
      url: 'https://github.com/ArsalanKaleem',
      ),
      (
      icon: Icons.work_outline,
      label: 'LinkedIn',
      url: 'www.linkedin.com/in/arsalankaleem',
      ),
      (
      icon: Icons.language,
      label: 'Website',
      url: 'https://arsalankaleem.github.io/portfolio/',
      ),
      (
      icon: Icons.email_outlined,
      label: 'Email',
      url: 'arsalanabbasi.here@gmail.com',
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final s in socials)
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: Spacing.xs),
            child: Tooltip(
              message: s.label,
              child: InkWell(
                onTap: () => _open(s.url, context),
                borderRadius: Radii.button,
                child: AnimatedContainer(
                  duration: Motion.fast,
                  padding: const EdgeInsets.all(Spacing.sm),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: Radii.button,
                    border:
                    Border.all(color: scheme.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      Icon(s.icon,
                          size: IconSizes.md, color: scheme.primary),
                      const SizedBox(height: 4),
                      Text(
                        s.label,
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable section card
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });
  final IconData icon;
  final String title;
  final Widget child;

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
                Icon(icon,
                    size: IconSizes.md,
                    color: theme.colorScheme.primary),
                const SizedBox(width: Spacing.xs),
                Text(title, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: Spacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info row with optional copy button
// ---------------------------------------------------------------------------

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.copyable = false,
  });
  final String label;
  final String value;
  final IconData icon;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: IconSizes.sm, color: scheme.onSurfaceVariant),
          const SizedBox(width: Spacing.sm),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          if (copyable)
            IconButton(
              icon: const Icon(Icons.copy_outlined),
              iconSize: IconSizes.sm,
              tooltip: 'Copy',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied $label'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tech chip
// ---------------------------------------------------------------------------

class _TechChip extends StatelessWidget {
  const _TechChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) =>
      Chip(label: Text(label), visualDensity: VisualDensity.compact);
}