import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../screens/about/about_screen.dart';
import '../../screens/analysis/analysis_screen.dart';
import '../../screens/brain/project_brain_screen.dart';
import '../../screens/chat/chat_screen.dart';
import '../../screens/coordination/coordination_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/documentation/documentation_screen.dart';
import '../../screens/history/history_screen.dart';
import '../../screens/projects/projects_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../widgets/app_shell.dart';

/// The nine workspace destinations, in sidebar order. Index positions here map
/// 1:1 to the [StatefulShellRoute] branches below and to [AppShell]'s nav.
const appDestinations = <AppDestination>[
  AppDestination('/', Icons.space_dashboard_outlined, Icons.space_dashboard,
      'Dashboard'),
  AppDestination('/projects', Icons.folder_open_outlined, Icons.folder,
      'Projects'),
  AppDestination('/analysis', Icons.insights_outlined, Icons.insights,
      'Analysis'),
  AppDestination('/docs', Icons.description_outlined, Icons.description,
      'Documentation'),
  AppDestination('/coordination', Icons.hub_outlined, Icons.hub,
      'AI Coordination'),
  AppDestination('/brain', Icons.psychology_outlined, Icons.psychology,
      'Project Brain'),
  AppDestination('/chat', Icons.forum_outlined, Icons.forum, 'Chat'),
  AppDestination('/history', Icons.history, Icons.history, 'History'),
  AppDestination('/settings', Icons.settings_outlined, Icons.settings,
      'Settings'),
  AppDestination('/about', Icons.info_outline, Icons.info, 'About'),
];

class AppDestination {
  const AppDestination(this.path, this.icon, this.selectedIcon, this.label);
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

GoRoute _route(String path, Widget child) =>
    GoRoute(path: path, builder: (_, __) => child);

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [_route('/', const DashboardScreen())]),
        StatefulShellBranch(
            routes: [_route('/projects', const ProjectsScreen())]),
        StatefulShellBranch(
            routes: [_route('/analysis', const AnalysisScreen())]),
        StatefulShellBranch(
            routes: [_route('/docs', const DocumentationScreen())]),
        StatefulShellBranch(
            routes: [_route('/coordination', const CoordinationScreen())]),
        StatefulShellBranch(
            routes: [_route('/brain', const ProjectBrainScreen())]),
        StatefulShellBranch(routes: [_route('/chat', const ChatScreen())]),
        StatefulShellBranch(
            routes: [_route('/history', const HistoryScreen())]),
        StatefulShellBranch(
            routes: [_route('/settings', const SettingsScreen())]),
        StatefulShellBranch(
            routes: [_route('/about', const AboutScreen())]),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Route not found: ${state.uri}')),
  ),
);