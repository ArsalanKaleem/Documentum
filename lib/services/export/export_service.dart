import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/errors/failures.dart';
import '../../models/generated_doc.dart';

/// A single exportable file (name + bytes) for UI save dialogs.
class ExportFile {
  ExportFile(this.fileName, this.bytes);
  final String fileName;
  final Uint8List bytes;
}

/// Packages generated documentation into ZIP, PDF, or individual Markdown
/// files. All output is structured under a `docs/` directory as required.
class ExportService {
  /// Produces a ZIP archive containing `docs/<DOC>.md` for every completed doc.
  Uint8List exportZip(List<GeneratedDoc> docs) {
    final completed = _completed(docs);
    if (completed.isEmpty) {
      throw const ExportFailure('No completed documents to export.');
    }
    final archive = Archive();
    for (final doc in completed) {
      final bytes = utf8.encode(normalizeMarkdown(doc.content));
      archive.addFile(
        ArchiveFile('docs/${doc.type.fileName}', bytes.length, bytes),
      );
    }
    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) {
      throw const ExportFailure('Failed to encode ZIP archive.');
    }
    return Uint8List.fromList(encoded);
  }

  /// Normalizes Markdown so GitHub-Flavored tables render correctly in any
  /// viewer (GitHub, VS Code, Obsidian). The in-app renderer is lenient, but
  /// strict viewers require a blank line before a table and a proper separator
  /// row of dashes directly under the header. This inserts both when missing.
  static String normalizeMarkdown(String input) {
    final lines = input.split('\n');
    final out = <String>[];

    bool isTableRow(String l) {
      final t = l.trim();
      return t.startsWith('|') && t.contains('|', 1);
    }

    bool isSeparator(String l) =>
        RegExp(r'^\s*\|?\s*:?-{2,}:?\s*(\|\s*:?-{2,}:?\s*)*\|?\s*$')
            .hasMatch(l);

    int columnCount(String l) {
      var t = l.trim();
      if (t.startsWith('|')) t = t.substring(1);
      if (t.endsWith('|')) t = t.substring(0, t.length - 1);
      return t.split('|').length;
    }

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final next = i + 1 < lines.length ? lines[i + 1] : '';

      // Start of a table: current line is a row, the line after is NOT already
      // a separator, and the line after IS another row (the body/header pair).
      final startsTable = isTableRow(line) &&
          (out.isEmpty || !isTableRow(out.last)) &&
          isTableRow(next);

      if (startsTable) {
        // Ensure a blank line precedes the table for strict parsers.
        if (out.isNotEmpty && out.last.trim().isNotEmpty) out.add('');
        out.add(line);
        // If the next line isn't a separator, synthesize one.
        if (!isSeparator(next)) {
          final cols = columnCount(line);
          out.add('|${List.filled(cols, ' --- ').join('|')}|');
        }
        continue;
      }
      out.add(line);
    }
    return out.join('\n');
  }

  /// Produces the complete coordination package: generated docs under `docs/`,
  /// the AI handoff / memory files at the root, and `session_history.json`.
  ///
  /// [contextFiles] maps a root-level file name (e.g. `AI_CONTEXT.md`) to its
  /// markdown content. [sessionHistoryJson] is the pretty-printed history.
  Uint8List exportFullPackage({
    required List<GeneratedDoc> docs,
    Map<String, String> contextFiles = const {},
    String? sessionHistoryJson,
  }) {
    final archive = Archive();
    var count = 0;

    void add(String path, String content) {
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile(path, bytes.length, bytes));
      count++;
    }

    for (final doc in _completed(docs)) {
      add('docs/${doc.type.fileName}', normalizeMarkdown(doc.content));
    }
    contextFiles.forEach((name, content) => add(name, content));
    if (sessionHistoryJson != null) {
      add('session_history.json', sessionHistoryJson);
    }

    if (count == 0) {
      throw const ExportFailure('Nothing to export.');
    }
    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) {
      throw const ExportFailure('Failed to encode ZIP archive.');
    }
    return Uint8List.fromList(encoded);
  }

  /// Returns one [ExportFile] per completed Markdown document.
  List<ExportFile> exportMarkdownFiles(List<GeneratedDoc> docs) {
    return _completed(docs)
        .map((d) => ExportFile(
              d.type.fileName,
              Uint8List.fromList(utf8.encode(normalizeMarkdown(d.content))),
            ))
        .toList();
  }

  /// Renders all completed docs into a single, professionally styled PDF with
  /// a cover page, branded headers/footers, and rich Markdown rendering.
  Future<Uint8List> exportPdf(
    List<GeneratedDoc> docs, {
    String projectName = 'Project',
  }) async {
    final completed = _completed(docs);
    if (completed.isEmpty) {
      throw const ExportFailure('No completed documents to export.');
    }

    // Load Poppins for a premium look; fall back to built-in fonts offline.
    pw.ThemeData theme;
    pw.Font? mono;
    try {
      theme = pw.ThemeData.withFont(
        base: await PdfGoogleFonts.poppinsRegular(),
        bold: await PdfGoogleFonts.poppinsBold(),
        italic: await PdfGoogleFonts.poppinsItalic(),
      );
      try {
        mono = await PdfGoogleFonts.jetBrainsMonoRegular();
      } catch (_) {
        mono = null; // mono font optional — code blocks fall back to base
      }
    } catch (_) {
      theme = pw.ThemeData();
      mono = null;
    }

    final pdf = pw.Document(
      theme: theme,
      title: '$projectName Documentation',
    );

    pdf.addPage(_coverPage(projectName, completed));

    for (final doc in completed) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(44, 54, 44, 48),
          header: (ctx) => _runningHeader(doc, projectName),
          footer: (ctx) => _footer(ctx),
          build: (ctx) => _renderMarkdown(doc.content, mono),
        ),
      );
    }
    return pdf.save();
  }

  static const PdfColor _brandPrimary = PdfColor.fromInt(0xFF50586C);
  static const PdfColor _brandMist = PdfColor.fromInt(0xFFDCE2F0);
  static final PdfColor _brandSoft = PdfColors.grey200;

  pw.Page _coverPage(String projectName, List<GeneratedDoc> docs) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (ctx) => pw.Stack(
        children: [
          pw.Container(color: _brandMist),
          pw.Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: pw.Container(height: 220, color: _brandPrimary),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(54),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 40),
                pw.Text('DOCUMENTATION',
                    style: pw.TextStyle(
                      color: _brandMist,
                      fontSize: 12,
                      letterSpacing: 4,
                      fontWeight: pw.FontWeight.bold,
                    )),
                pw.SizedBox(height: 10),
                pw.Text(projectName,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 34,
                      fontWeight: pw.FontWeight.bold,
                    )),
                pw.Spacer(),
                pw.Text('Contents',
                    style: pw.TextStyle(
                      color: _brandPrimary,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    )),
                pw.SizedBox(height: 10),
                ...docs.map((d) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4),
                      child: pw.Row(
                        children: [
                          pw.Container(
                            width: 6,
                            height: 6,
                            decoration: pw.BoxDecoration(
                              color: _brandPrimary,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                          pw.SizedBox(width: 10),
                          pw.Text(d.type.label,
                              style: pw.TextStyle(
                                  color: _brandPrimary, fontSize: 13)),
                          pw.SizedBox(width: 8),
                          pw.Text('· ${d.type.fileName}',
                              style: const pw.TextStyle(
                                  color: PdfColors.grey600, fontSize: 11)),
                        ],
                      ),
                    )),
                pw.Spacer(),
                pw.Text(
                  'Generated ${DateTime.now().toIso8601String().split('T').first} '
                  '· ${docs.length} document(s)',
                  style: const pw.TextStyle(
                      color: PdfColors.grey600, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _runningHeader(GeneratedDoc doc, String projectName) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 12),
        padding: const pw.EdgeInsets.only(bottom: 8),
        decoration: pw.BoxDecoration(
          border: pw.Border(
              bottom: pw.BorderSide(color: _brandSoft, width: 0.8)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(doc.type.label,
                style: pw.TextStyle(
                    color: _brandPrimary,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold)),
            pw.Text(projectName,
                style: const pw.TextStyle(
                    color: PdfColors.grey500, fontSize: 9)),
          ],
        ),
      );

  pw.Widget _footer(pw.Context ctx) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 12),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Smart Documentation Generator',
                style: const pw.TextStyle(
                    color: PdfColors.grey400, fontSize: 8)),
            pw.Text('${ctx.pageNumber} / ${ctx.pagesCount}',
                style: const pw.TextStyle(
                    color: PdfColors.grey500, fontSize: 9)),
          ],
        ),
      );

  // ---- Markdown rendering --------------------------------------------------

  List<pw.Widget> _renderMarkdown(String markdown, pw.Font? mono) {
    final widgets = <pw.Widget>[];
    final lines = const LineSplitter().convert(markdown);
    var inCode = false;
    final codeBuffer = StringBuffer();
    final tableBuffer = <String>[];

    void flushCode() {
      if (codeBuffer.isNotEmpty) {
        widgets.add(pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          margin: const pw.EdgeInsets.symmetric(vertical: 8),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: _brandSoft, width: 0.8),
          ),
          child: pw.Text(
            codeBuffer.toString().trimRight(),
            style: pw.TextStyle(font: mono, fontSize: 8.5, lineSpacing: 2),
          ),
        ));
        codeBuffer.clear();
      }
    }

    void flushTable() {
      if (tableBuffer.isNotEmpty) {
        final table = _buildTable(tableBuffer, mono);
        if (table != null) widgets.add(table);
        tableBuffer.clear();
      }
    }

    for (final line in lines) {
      final trimmed = line.trimLeft();

      if (trimmed.startsWith('```')) {
        if (inCode) flushCode();
        inCode = !inCode;
        continue;
      }
      if (inCode) {
        codeBuffer.writeln(line);
        continue;
      }

      // Markdown table rows (start and contain a pipe).
      final isTableRow = trimmed.startsWith('|') && trimmed.contains('|');
      if (isTableRow) {
        tableBuffer.add(trimmed);
        continue;
      } else if (tableBuffer.isNotEmpty) {
        flushTable();
      }

      if (line.startsWith('# ')) {
        widgets.add(_heading(line.substring(2), 21, topGap: 6));
      } else if (line.startsWith('## ')) {
        widgets.add(_heading(line.substring(3), 16, rule: true));
      } else if (line.startsWith('### ')) {
        widgets.add(_heading(line.substring(4), 13));
      } else if (line.startsWith('#### ')) {
        widgets.add(_heading(line.substring(5), 11.5));
      } else if (trimmed.startsWith('> ')) {
        widgets.add(_blockquote(trimmed.substring(2), mono));
      } else if (trimmed == '---' || trimmed == '***') {
        widgets.add(pw.Divider(color: _brandSoft, height: 16));
      } else if (line.trim().isEmpty) {
        widgets.add(pw.SizedBox(height: 5));
      } else if (RegExp(r'^\s*[-*]\s').hasMatch(line)) {
        widgets.add(_bullet(trimmed.substring(2), mono, ordered: false));
      } else if (RegExp(r'^\s*\d+\.\s').hasMatch(line)) {
        final content = trimmed.replaceFirst(RegExp(r'^\d+\.\s'), '');
        widgets.add(_bullet(content, mono, ordered: true,
            marker: trimmed.split('.').first));
      } else {
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.RichText(
            text: pw.TextSpan(children: _inline(line, mono)),
          ),
        ));
      }
    }
    flushCode();
    flushTable();
    return widgets;
  }

  pw.Widget _heading(String text, double size,
      {double topGap = 12, bool rule = false}) {
    return pw.Container(
      margin: pw.EdgeInsets.only(top: topGap, bottom: rule ? 8 : 4),
      padding: rule
          ? const pw.EdgeInsets.only(bottom: 5)
          : pw.EdgeInsets.zero,
      decoration: rule
          ? pw.BoxDecoration(
              border: pw.Border(
                  bottom: pw.BorderSide(color: _brandSoft, width: 0.8)))
          : null,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: size,
          fontWeight: pw.FontWeight.bold,
          color: _brandPrimary,
        ),
      ),
    );
  }

  pw.Widget _blockquote(String text, pw.Font? mono) => pw.Container(
        margin: const pw.EdgeInsets.symmetric(vertical: 6),
        padding: const pw.EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: pw.BoxDecoration(
          color: _brandMist,
          borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border(
              left: pw.BorderSide(color: _brandPrimary, width: 3)),
        ),
        child: pw.RichText(
          text: pw.TextSpan(children: _inline(text, mono)),
        ),
      );

  pw.Widget _bullet(String text, pw.Font? mono,
      {required bool ordered, String marker = '•'}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 6, top: 2, bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 16,
            child: pw.Text(ordered ? '$marker.' : '•',
                style: pw.TextStyle(
                    fontSize: 11,
                    color: _brandPrimary,
                    fontWeight: pw.FontWeight.bold)),
          ),
          pw.Expanded(
            child: pw.RichText(
              text: pw.TextSpan(children: _inline(text, mono)),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget? _buildTable(List<String> rows, pw.Font? mono) {
    // Drop the separator row (---|---).
    final dataRows = rows
        .where((r) => !RegExp(r'^\|[\s:|-]+\|?$').hasMatch(r))
        .toList();
    if (dataRows.isEmpty) return null;

    List<String> cells(String row) {
      var r = row.trim();
      if (r.startsWith('|')) r = r.substring(1);
      if (r.endsWith('|')) r = r.substring(0, r.length - 1);
      return r.split('|').map((c) => c.trim()).toList();
    }

    final header = cells(dataRows.first);
    final body = dataRows.skip(1).map(cells).toList();

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Table(
        border: pw.TableBorder.all(color: _brandSoft, width: 0.8),
        columnWidths: {
          for (var i = 0; i < header.length; i++) i: const pw.FlexColumnWidth(),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: _brandMist),
            children: header
                .map((c) => pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(c,
                          style: pw.TextStyle(
                              fontSize: 9.5,
                              fontWeight: pw.FontWeight.bold,
                              color: _brandPrimary)),
                    ))
                .toList(),
          ),
          for (final row in body)
            pw.TableRow(
              children: List.generate(header.length, (i) {
                final value = i < row.length ? row[i] : '';
                return pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.RichText(
                    text: pw.TextSpan(children: _inline(value, mono, size: 9.5)),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  /// Parses inline **bold**, *italic*, `code`, and [text](link) into spans.
  List<pw.TextSpan> _inline(String text, pw.Font? mono, {double size = 10.5}) {
    final spans = <pw.TextSpan>[];
    final pattern = RegExp(
      r'(\*\*([^*]+)\*\*)|(\*([^*]+)\*)|(`([^`]+)`)|(\[([^\]]+)\]\(([^)]+)\))',
    );
    var index = 0;
    final base = pw.TextStyle(fontSize: size, lineSpacing: 2.2,
        color: PdfColors.grey900);

    for (final m in pattern.allMatches(text)) {
      if (m.start > index) {
        spans.add(pw.TextSpan(text: text.substring(index, m.start), style: base));
      }
      if (m.group(2) != null) {
        spans.add(pw.TextSpan(
            text: m.group(2),
            style: base.copyWith(fontWeight: pw.FontWeight.bold)));
      } else if (m.group(4) != null) {
        spans.add(pw.TextSpan(
            text: m.group(4),
            style: base.copyWith(fontStyle: pw.FontStyle.italic)));
      } else if (m.group(6) != null) {
        spans.add(pw.TextSpan(
            text: m.group(6),
            style: base.copyWith(
                font: mono, fontSize: size - 1, color: _brandPrimary)));
      } else if (m.group(8) != null) {
        spans.add(pw.TextSpan(
            text: m.group(8),
            style: base.copyWith(
                color: _brandPrimary,
                decoration: pw.TextDecoration.underline)));
      }
      index = m.end;
    }
    if (index < text.length) {
      spans.add(pw.TextSpan(text: text.substring(index), style: base));
    }
    return spans.isEmpty ? [pw.TextSpan(text: text, style: base)] : spans;
  }

  List<GeneratedDoc> _completed(List<GeneratedDoc> docs) => docs
      .where((d) => d.status == DocStatus.completed && d.content.isNotEmpty)
      .toList();
}
