import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/session_record.dart';

/// Records and persists development sessions. Backed by [SharedPreferences]
/// under a single JSON key; exposes a JSON string for the exported
/// `session_history.json` artifact.
class SessionTrackerService {
  SessionTrackerService({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  static const _key = 'session_history';

  Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<List<SessionRecord>> load() async {
    final prefs = await _p;
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => SessionRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> add(SessionRecord record) async {
    final prefs = await _p;
    final existing = await load();
    final updated = [...existing, record];
    await prefs.setString(_key, _encode(updated));
  }

  Future<void> clear() async {
    final prefs = await _p;
    await prefs.remove(_key);
  }

  /// Pretty-printed JSON for the exported `session_history.json`.
  Future<String> toJsonString() async => _encode(await load(), pretty: true);

  String _encode(List<SessionRecord> records, {bool pretty = false}) {
    final data = records.map((r) => r.toJson()).toList();
    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(data);
    }
    return jsonEncode(data);
  }
}
