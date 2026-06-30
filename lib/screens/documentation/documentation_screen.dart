import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../models/generated_doc.dart';
import '../../providers/coordination_providers.dart';
import '../../providers/documentation_providers.dart';
import '../../providers/project_providers.dart';
import '../../providers/service_providers.dart';
import '../../providers/settings_providers.dart';
import '../../services/export/export_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/markdown_view.dart';

class DocumentationScreen extends ConsumerStatefulWidget {
  const DocumentationScreen({super.key});

  @override
  ConsumerState<DocumentationScreen> createState() =>
      _DocumentationScreenState();
}

class _DocumentationScreenState extends ConsumerState<DocumentationScreen> {
  DocType _selected = DocType.readme;

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(projectControllerProvider).valueOrNull;
    final docs = ref.watch(documentationProvider);
    final notifier = ref.read(documentationProvider.notifier);
    final settings = ref.watch(settingsProvider).valueOrNull;

    if (project == null) {
      return Scaffold(
        body: EmptyState(
          icon: Icons.description_outlined,
          title: 'No project loaded',
          message: 'Analyze a project first, then generate its documentation.',
          actionLabel: 'Go to Dashboard',
          onAction: () => context.go('/'),
        ),
      );
    }

    final hasKey = settings?.hasActiveKey ?? false;
    final generating = notifier.isGenerating;
    final current = docs[_selected]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documentation'),
        automaticallyImplyLeading: false,
        actions: [
          if (!hasKey)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => context.go('/settings'),
                icon: const Icon(Icons.key_off, size: 18),
                label: const Text('Add API key'),
              ),
            ),
          FilledButton.icon(
            onPressed: (!hasKey || generating)
                ? null
                : () => notifier.generateAll(),
            icon: generating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(generating ? 'Generating…' : 'Generate all'),
          ),
          const SizedBox(width: 8),
          _ExportMenu(docs: docs.values.toList()),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          _DocList(
            docs: docs,
            selected: _selected,
            onSelect: (t) => setState(() => _selected = t),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _DocDetail(
              doc: current,
              canGenerate: hasKey,
              onRegenerate: () => notifier.regenerate(_selected),
              onEdit: (content) => notifier.edit(_selected, content),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocList extends StatelessWidget {
  const _DocList({
    required this.docs,
    required this.selected,
    required this.onSelect,
  });

  final Map<DocType, GeneratedDoc> docs;
  final DocType selected;
  final ValueChanged<DocType> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (final type in DocType.values)
            _DocListTile(
              doc: docs[type]!,
              selected: type == selected,
              onTap: () => onSelect(type),
            ),
        ],
      ),
    );
  }
}

class _DocListTile extends StatelessWidget {
  const _DocListTile({
    required this.doc,
    required this.selected,
    required this.onTap,
  });

  final GeneratedDoc doc;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget statusIcon;
    switch (doc.status) {
      case DocStatus.generating:
        statusIcon = const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case DocStatus.completed:
        statusIcon =
            Icon(Icons.check_circle, size: 18, color: Colors.green.shade500);
      case DocStatus.failed:
        statusIcon =
            Icon(Icons.error_outline, size: 18, color: scheme.error);
      case DocStatus.pending:
        statusIcon = Icon(Icons.circle_outlined,
            size: 18, color: scheme.onSurfaceVariant);
      case DocStatus.cancelled:
        statusIcon = Icon(Icons.cancel_outlined,
            size: 18, color: scheme.onSurfaceVariant);
    }
    return ListTile(
      selected: selected,
      selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.35),
      title: Text(doc.type.label),
      subtitle: Text(
        doc.type.fileName,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: statusIcon,
      onTap: onTap,
    );
  }
}

class _DocDetail extends StatelessWidget {
  const _DocDetail({
    required this.doc,
    required this.canGenerate,
    required this.onRegenerate,
    required this.onEdit,
  });

  final GeneratedDoc doc;
  final bool canGenerate;
  final VoidCallback onRegenerate;
  final ValueChanged<String> onEdit;

  Future<void> _editDialog(BuildContext context) async {
    final controller = TextEditingController(text: doc.content);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${doc.type.fileName}'),
        content: SizedBox(
          width: 720,
          child: TextField(
            controller: controller,
            maxLines: 24,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) onEdit(result);
  }

  @override
  Widget build(BuildContext context) {
    if (doc.status == DocStatus.failed) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Generation failed',
        message: doc.error ?? 'An unknown error occurred.',
        actionLabel: canGenerate ? 'Retry' : null,
        onAction: canGenerate ? onRegenerate : null,
      );
    }
    if (doc.content.isEmpty) {
      return EmptyState(
        icon: Icons.description_outlined,
        title: '${doc.type.label} not generated yet',
        message: canGenerate
            ? 'Use "Generate all" above, or generate just this document.'
            : 'Add an API key in Settings to generate documentation.',
        actionLabel: canGenerate ? 'Generate this document' : null,
        onAction: canGenerate ? onRegenerate : null,
      );
    }

    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
            child: Row(
              children: [
                Text(doc.type.fileName,
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  tooltip: 'Copy',
                  icon: const Icon(Icons.copy_all_outlined),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: doc.content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editDialog(context),
                ),
                if (canGenerate)
                  IconButton(
                    tooltip: 'Regenerate',
                    icon: const Icon(Icons.refresh),
                    onPressed: onRegenerate,
                  ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(child: MarkdownView(data: doc.content)),
      ],
    );
  }
}

class _ExportMenu extends ConsumerWidget {
  const _ExportMenu({required this.docs});
  final List<GeneratedDoc> docs;

  Future<void> _saveBytes(
    BuildContext context,
    String fileName,
    Uint8List bytes,
  ) async {
    // On desktop, saveFile returns a path but does NOT write the file — we must
    // write the bytes ourselves. (The `bytes:` arg only auto-writes on mobile.)
    final path = await FilePicker.platform.saveFile(
      fileName: fileName,
      type: FileType.any,
    );
    if (path == null) return; // user cancelled
    try {
      await File(path).writeAsBytes(bytes);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Saved to $path')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    }
  }

  /// Saves every Markdown file into a single chosen folder (one dialog instead
  /// of one per file).
  Future<void> _saveMarkdownToFolder(
    BuildContext context,
    List<ExportFile> files,
  ) async {
    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose a folder for the Markdown files',
    );
    if (dir == null) return;
    try {
      final target = Directory('$dir${Platform.pathSeparator}docs');
      if (!target.existsSync()) target.createSync(recursive: true);
      for (final f in files) {
        await File('${target.path}${Platform.pathSeparator}${f.fileName}')
            .writeAsBytes(f.bytes);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved ${files.length} files to ${target.path}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final export = ref.read(exportServiceProvider);
    final anyContent = docs.any((d) => d.content.isNotEmpty);
    return PopupMenuButton<String>(
      enabled: anyContent,
      tooltip: 'Export',
      icon: const Icon(Icons.download_outlined),
      onSelected: (value) async {
        try {
          switch (value) {
            case 'zip':
              await _saveBytes(context, 'documentation.zip', export.exportZip(docs));
            case 'package':
              final coord = ref.read(coordinationProvider).valueOrNull;
              final history =
                  await ref.read(sessionTrackerProvider).toJsonString();
              final bytes = export.exportFullPackage(
                docs: docs,
                contextFiles: coord?.contextFiles ?? const {},
                sessionHistoryJson: history,
              );
              await _saveBytes(context, 'coordination_package.zip', bytes);
            case 'pdf':
              final projectName = ref
                      .read(projectControllerProvider)
                      .valueOrNull
                      ?.context
                      .name ??
                  'Project';
              final bytes =
                  await export.exportPdf(docs, projectName: projectName);
              await Printing.sharePdf(bytes: bytes, filename: 'documentation.pdf');
            case 'md':
              final files = export.exportMarkdownFiles(docs);
              await _saveMarkdownToFolder(context, files);
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Export failed: $e')));
          }
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'zip', child: Text('Export docs as ZIP')),
        PopupMenuItem(
            value: 'package',
            child: Text('Export full coordination package')),
        PopupMenuItem(value: 'pdf', child: Text('Export as PDF')),
        PopupMenuItem(value: 'md', child: Text('Export Markdown files')),
      ],
    );
  }
}
