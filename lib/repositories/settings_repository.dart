import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/agent_provider_config.dart';
import '../models/ai_provider_config.dart';

/// Persists user settings. API keys live ONLY in [FlutterSecureStorage], which
/// is backed by the platform keychain/keystore (Keychain on macOS/iOS, DPAPI
/// on Windows, libsecret on Linux) so keys are encrypted at rest. Non-secret
/// preferences (selected provider, model) live in [SharedPreferences].
class SettingsRepository {
  SettingsRepository({
    FlutterSecureStorage? secure,
    SharedPreferences? prefs,
  })  : _secure = secure ??
      const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      ),
        _prefs = prefs;

  final FlutterSecureStorage _secure;
  SharedPreferences? _prefs;

  static const _keyPrefix = 'api_key_';
  static const _activeProviderKey = 'active_provider';
  static const _configPrefix = 'provider_config_';

  Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  // ---- API keys (secure) ---------------------------------------------------

  Future<void> setApiKey(AiProviderType type, String key) =>
      _secure.write(key: '$_keyPrefix${type.name}', value: key);

  Future<String?> getApiKey(AiProviderType type) =>
      _secure.read(key: '$_keyPrefix${type.name}');

  Future<void> deleteApiKey(AiProviderType type) =>
      _secure.delete(key: '$_keyPrefix${type.name}');

  Future<bool> hasApiKey(AiProviderType type) async {
    final v = await getApiKey(type);
    return v != null && v.isNotEmpty;
  }

  // ---- active provider -----------------------------------------------------

  Future<void> setActiveProvider(AiProviderType type) async {
    final prefs = await _p;
    await prefs.setString(_activeProviderKey, type.name);
  }

  Future<AiProviderType> getActiveProvider() async {
    final prefs = await _p;
    final name = prefs.getString(_activeProviderKey);
    return AiProviderType.values.firstWhere(
          (t) => t.name == name,
      orElse: () => AiProviderType.gemini,
    );
  }

  // ---- provider config -----------------------------------------------------

  Future<void> saveConfig(AiProviderConfig config) async {
    final prefs = await _p;
    await prefs.setString(
      '$_configPrefix${config.type.name}',
      jsonEncode(config.toJson()),
    );
  }

  Future<AiProviderConfig> getConfig(AiProviderType type) async {
    final prefs = await _p;
    final raw = prefs.getString('$_configPrefix${type.name}');
    if (raw == null) return AiProviderConfig.defaults(type);
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      // Force the correct type regardless of what was serialised — this handles
      // the case where old JSON has a removed enum value (e.g. "openai") but
      // was stored under the correct key (e.g. provider_config_openrouter).
      map['type'] = type.name;
      return AiProviderConfig.fromJson(map);
    } catch (_) {
      return AiProviderConfig.defaults(type);
    }
  }

  /// Removes configs for provider types that no longer exist in the enum.
  /// Call once at startup to clear stale SharedPreferences keys.
  Future<void> pruneStaleConfigs() async {
    final prefs = await _p;
    final validNames = AiProviderType.values.map((t) => t.name).toSet();
    final keysToRemove = prefs
        .getKeys()
        .where((k) =>
    k.startsWith(_configPrefix) &&
        !validNames.contains(k.substring(_configPrefix.length)))
        .toList();
    for (final k in keysToRemove) {
      await prefs.remove(k);
    }
  }

  // ---- per-agent provider assignment ---------------------------------------

  static const _agentConfigKey = 'agent_provider_config';

  Future<void> saveAgentConfig(AgentProviderConfig config) async {
    final prefs = await _p;
    await prefs.setString(_agentConfigKey, jsonEncode(config.toJson()));
  }

  Future<AgentProviderConfig> getAgentConfig() async {
    final prefs = await _p;
    final raw = prefs.getString(_agentConfigKey);
    if (raw == null) return const AgentProviderConfig();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final validNames = AiProviderType.values.map((t) => t.name).toSet();
      // Replace any stale provider names with 'gemini' as the safe default.
      final fields = [
        'readmeProvider', 'apiProvider', 'architectureProvider',
        'installationProvider', 'contributingProvider', 'changelogProvider',
      ];
      for (final f in fields) {
        if (map.containsKey(f) && !validNames.contains(map[f])) {
          map[f] = AiProviderType.gemini.name;
        }
      }
      return AgentProviderConfig.fromJson(map);
    } catch (_) {
      return const AgentProviderConfig();
    }
  }

  // ---- theme mode ----------------------------------------------------------

  static const _themeModeKey = 'theme_mode';

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await _p;
    await prefs.setString(_themeModeKey, mode.name);
  }

  Future<ThemeMode> getThemeMode() async {
    final prefs = await _p;
    final raw = prefs.getString(_themeModeKey);
    return ThemeMode.values.firstWhere(
          (m) => m.name == raw,
      orElse: () => ThemeMode.system,
    );
  }
}