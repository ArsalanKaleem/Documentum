import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Thin wrapper around [Markdown] that applies a readable, theme-aware style
/// sheet and enables text selection. Used by the documentation viewer and
/// chat bubbles.
class MarkdownView extends StatelessWidget {
  const MarkdownView({
    required this.data,
    this.padding = const EdgeInsets.all(20),
    this.shrinkWrap = false,
    super.key,
  });

  final String data;
  final EdgeInsets padding;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final codeBg = scheme.surfaceContainerHighest.withValues(alpha: 0.6);

    final styleSheet = MarkdownStyleSheet.fromTheme(theme).copyWith(
      h1: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      h2: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      h3: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      p: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
      code: TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        backgroundColor: codeBg,
        color: scheme.onSurface,
      ),
      codeblockDecoration: BoxDecoration(
        color: codeBg,
        borderRadius: BorderRadius.circular(10),
      ),
      codeblockPadding: const EdgeInsets.all(14),
      blockquoteDecoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: scheme.primary, width: 4),
        ),
      ),
      blockquotePadding: const EdgeInsets.all(12),
      tableBorder: TableBorder.all(
        color: scheme.outlineVariant,
        width: 1,
      ),
      tableHead: const TextStyle(fontWeight: FontWeight.w700),
    );

    return Markdown(
      data: data,
      selectable: true,
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: padding,
      styleSheet: styleSheet,
    );
  }
}
