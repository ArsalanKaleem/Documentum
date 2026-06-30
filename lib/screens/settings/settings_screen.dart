import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../models/agent_provider_config.dart';
import '../../models/ai_provider_config.dart';
import '../../models/generated_doc.dart';
import '../../providers/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load settings: $e')),
        data: (settings) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ThemeToggle(settings: settings),
                    const SizedBox(height: Spacing.xl),
                    Text('AI Provider',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      'Choose the active provider. API keys are encrypted and '
                      'stored only on this device.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    _ProviderSelector(settings: settings),
                    const SizedBox(height: 24),
                    _ApiKeySection(settings: settings),
                    const SizedBox(height: 24),
                    _ModelSection(settings: settings),
                    const SizedBox(height: 24),
                    _AgentAssignmentSection(settings: settings),
                    const SizedBox(height: 24),
                    const _SecurityNote(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeToggle extends ConsumerWidget {
  const _ThemeToggle({required this.settings});
  final SettingsState settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(settingsProvider.notifier);
    final current = settings.themeMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Appearance', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: Spacing.md),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.light,
              icon: Icon(Icons.light_mode_outlined),
              label: Text('Light'),
            ),
            ButtonSegment(
              value: ThemeMode.system,
              icon: Icon(Icons.brightness_auto_outlined),
              label: Text('System'),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              icon: Icon(Icons.dark_mode_outlined),
              label: Text('Dark'),
            ),
          ],
          selected: {current},
          onSelectionChanged: (s) => notifier.setThemeMode(s.first),
        ),
      ],
    );
  }
}

class _ProviderSelector extends ConsumerWidget {
  const _ProviderSelector({required this.settings});
  final SettingsState settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final type in AiProviderType.values)
          ChoiceChip(
            label: Text(type.label),
            selected: settings.activeProvider == type,
            avatar: settings.configuredProviders.contains(type)
                ? const Icon(Icons.check_circle, size: 18, color: Colors.green)
                : const Icon(Icons.circle_outlined, size: 18),
            onSelected: (_) =>
                ref.read(settingsProvider.notifier).selectProvider(type),
          ),
      ],
    );
  }
}

class _ApiKeySection extends ConsumerStatefulWidget {
  const _ApiKeySection({required this.settings});
  final SettingsState settings;

  @override
  ConsumerState<_ApiKeySection> createState() => _ApiKeySectionState();
}

class _ApiKeySectionState extends ConsumerState<_ApiKeySection> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.settings.activeProvider;
    final configured = widget.settings.configuredProviders.contains(type);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('${type.label} API key',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 8),
                if (configured)
                  Chip(
                    label: const Text('Saved'),
                    backgroundColor: Colors.green.withValues(alpha: 0.15),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              obscureText: _obscure,
              decoration: InputDecoration(
                hintText: configured ? '•••••••• (saved)' : 'Paste API key',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: () async {
                    final key = _controller.text.trim();
                    if (key.isEmpty) return;
                    await ref
                        .read(settingsProvider.notifier)
                        .setApiKey(type, key);
                    _controller.clear();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${type.label} key saved')),
                      );
                    }
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save key'),
                ),
                const SizedBox(width: 8),
                if (configured)
                  OutlinedButton.icon(
                    onPressed: () async {
                      await ref
                          .read(settingsProvider.notifier)
                          .removeApiKey(type);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${type.label} key removed')),
                        );
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModelSection extends ConsumerWidget {
  const _ModelSection({required this.settings});
  final SettingsState settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = settings.config;
    final notifier = ref.read(settingsProvider.notifier);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Model configuration',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextFormField(
              key: ValueKey('model_${config.type.name}'),
              initialValue: config.model,
              decoration: const InputDecoration(
                labelText: 'Model',
                border: OutlineInputBorder(),
              ),
              onFieldSubmitted: (v) =>
                  notifier.updateConfig(config.copyWith(model: v.trim())),
            ),
            const SizedBox(height: 16),
            if (config.embeddingModel != null)
              TextFormField(
                key: ValueKey('emb_${config.type.name}'),
                initialValue: config.embeddingModel,
                decoration: const InputDecoration(
                  labelText: 'Embedding model (for RAG chat)',
                  border: OutlineInputBorder(),
                ),
                onFieldSubmitted: (v) => notifier
                    .updateConfig(config.copyWith(embeddingModel: v.trim())),
              ),
            const SizedBox(height: 20),
            Text('Temperature: ${config.temperature.toStringAsFixed(2)}'),
            Slider(
              value: config.temperature,
              max: 1,
              divisions: 20,
              label: config.temperature.toStringAsFixed(2),
              onChanged: (v) =>
                  notifier.updateConfig(config.copyWith(temperature: v)),
            ),
            Text('Max tokens: ${config.maxTokens}'),
            Slider(
              value: config.maxTokens.toDouble(),
              min: 512,
              max: 8192,
              divisions: 15,
              label: '${config.maxTokens}',
              onChanged: (v) =>
                  notifier.updateConfig(config.copyWith(maxTokens: v.round())),
            ),
            const SizedBox(height: 4),
            Text(
              'Press Enter to save text fields.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgentAssignmentSection extends ConsumerWidget {
  const _AgentAssignmentSection({required this.settings});
  final SettingsState settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentConfig = settings.agentConfig;
    final notifier = ref.read(settingsProvider.notifier);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Per-agent providers',
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        'Assign a different provider to each agent. They run in '
                        'parallel.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: agentConfig.autoMode,
                  onChanged: (v) => notifier.setAutoMode(v),
                ),
              ],
            ),
            if (agentConfig.autoMode)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Auto routing is on: README→OpenAI, API→Gemini, '
                  'Architecture→DeepSeek, Installation→OpenAI, '
                  'Contributing→Gemini, Changelog→DeepSeek.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  children: [
                    for (final type in DocType.values)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text('${type.label} Agent'),
                            ),
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<AiProviderType>(
                                value: agentConfig.providerFor(type),
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                items: [
                                  for (final p in AiProviderType.values)
                                    DropdownMenuItem(
                                      value: p,
                                      child: Row(
                                        children: [
                                          Text(p.label),
                                          if (!settings.configuredProviders
                                              .contains(p)) ...[
                                            const SizedBox(width: 6),
                                            Icon(Icons.key_off,
                                                size: 14,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .error),
                                          ],
                                        ],
                                      ),
                                    ),
                                ],
                                onChanged: (p) {
                                  if (p != null) {
                                    notifier.assignAgentProvider(type, p);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'API keys are stored using the platform secure storage '
              '(Keychain on macOS/iOS, libsecret on Linux, Credential Locker '
              'on Windows, encrypted storage on the web). Keys are never '
              'written to plain shared preferences and never leave your device '
              'except in direct calls to the provider you select.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
