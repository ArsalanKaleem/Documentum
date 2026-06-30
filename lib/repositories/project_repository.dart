import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/project.dart';

/// Stores the active project in memory and persists lightweight metadata for
/// the "recent projects" list. Full source content is kept only for the active
/// session (it can be large); recents store context + docs only.
class ProjectRepository {
  ProjectRepository({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  Project? _active;

  static const _recentsKey = 'recent_projects';
  static const _maxRecents = 10;

  Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  Project? get active => _active;
  set active(Project? project) => _active = project;

  /// Persists a compact summary of [project] to the recents list.
  Future<void> saveRecent(Project project) async {
    final prefs = await _p;
    final recents = await getRecents();
    final compact = project.copyWith(files: const []); // drop heavy content
    final updated = [
      compact,
      ...recents.where((r) => r.id != project.id),
    ].take(_maxRecents).toList();
    await prefs.setString(
      _recentsKey,
      jsonEncode(updated.map((p) => p.toJson()).toList()),
    );
  }

  Future<List<Project>> getRecents() async {
    final prefs = await _p;
    final raw = prefs.getString(_recentsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Project.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> deleteRecent(String id) async {
    final prefs = await _p;
    final recents = await getRecents();
    await prefs.setString(
      _recentsKey,
      jsonEncode(
        recents.where((r) => r.id != id).map((p) => p.toJson()).toList(),
      ),
    );
  }
}
