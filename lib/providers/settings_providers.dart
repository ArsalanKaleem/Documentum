import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/agent_provider_config.dart';
import '../models/ai_provider_config.dart';
import '../models/generated_doc.dart';
import '../repositories/settings_repository.dart';
import 'service_providers.dart';

/// Immutable snapshot of user-configurable settings.
class SettingsState {
  const SettingsState({
    required this.activeProvider,
    required this.config,
    required this.configuredProviders,
    required this.agentConfig,
    this.themeMode = ThemeMode.system,
  });

  final AiProviderType activeProvider;
  final AiProviderConfig config;
  final Set<AiProviderType> configuredProviders;
  final AgentProviderConfig agentConfig;
  final ThemeMode themeMode;

  bool get hasActiveKey => configuredProviders.contains(activeProvider);

  bool hasKeyForAgent(DocType type) =>
      configuredProviders.contains(agentConfig.providerFor(type));

  SettingsState copyWith({
    AiProviderType? activeProvider,
    AiProviderConfig? config,
    Set<AiProviderType>? configuredProviders,
    AgentProviderConfig? agentConfig,
    ThemeMode? themeMode,
  }) =>
      SettingsState(
        activeProvider: activeProvider ?? this.activeProvider,
        config: config ?? this.config,
        configuredProviders: configuredProviders ?? this.configuredProviders,
        agentConfig: agentConfig ?? this.agentConfig,
        themeMode: themeMode ?? this.themeMode,
      );
}

class SettingsNotifier extends AsyncNotifier<SettingsState> {
  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);

  @override
  Future<SettingsState> build() async {
    // Clean up any configs stored under old provider names (e.g. openai,
    // deepseek) that were removed from the enum. Without this, stale JSON
    // with an unknown 'type' field causes silent fallback to defaults.
    await _repo.pruneStaleConfigs();

    final active = await _repo.getActiveProvider();
    final config = await _repo.getConfig(active);
    final agentConfig = await _repo.getAgentConfig();
    final themeMode = await _repo.getThemeMode();
    final configured = <AiProviderType>{};
    for (final t in AiProviderType.values) {
      if (await _repo.hasApiKey(t)) configured.add(t);
    }
    return SettingsState(
      activeProvider: active,
      config: config,
      configuredProviders: configured,
      agentConfig: agentConfig,
      themeMode: themeMode,
    );
  }

  Future<void> setApiKey(AiProviderType type, String key) async {
    await _repo.setApiKey(type, key);
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(
        current.copyWith(
          configuredProviders: {...current.configuredProviders, type},
        ),
      );
    }
  }

  Future<void> removeApiKey(AiProviderType type) async {
    await _repo.deleteApiKey(type);
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(
        current.copyWith(
          configuredProviders: {...current.configuredProviders}..remove(type),
        ),
      );
    }
  }

  Future<void> selectProvider(AiProviderType type) async {
    await _repo.setActiveProvider(type);
    final config = await _repo.getConfig(type);
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(
        current.copyWith(activeProvider: type, config: config),
      );
    }
  }

  Future<void> updateConfig(AiProviderConfig config) async {
    await _repo.saveConfig(config);
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(config: config));
    }
  }

  /// Assigns [provider] to the agent that produces [type].
  Future<void> assignAgentProvider(DocType type, AiProviderType provider) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = current.agentConfig.assign(type, provider);
    await _repo.saveAgentConfig(updated);
    state = AsyncData(current.copyWith(agentConfig: updated));
  }

  /// Toggles automatic provider routing.
  /// Toggles between light, dark, and system theme and persists the choice.
  Future<void> setThemeMode(ThemeMode mode) async {
    await _repo.saveThemeMode(mode);
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(themeMode: mode));
    }
  }

  Future<void> setAutoMode(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = current.agentConfig.copyWith(autoMode: enabled);
    await _repo.saveAgentConfig(updated);
    state = AsyncData(current.copyWith(agentConfig: updated));
  }
}

final settingsProvider =
AsyncNotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);