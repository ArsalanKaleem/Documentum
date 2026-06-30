import '../../models/generated_doc.dart';
import '../../models/project_brain.dart';
import '../../models/session_record.dart';

/// Generates the cross-AI handoff and memory artifacts:
/// AI_CONTEXT.md, PROJECT_BRAIN.md, SESSION_SUMMARY.md, and
/// AI_CONTINUATION_PROMPT.md.
///
/// These are produced deterministically from the structured [ProjectBrain],
/// generated docs, and session history — so they are reliable, free, and stable
/// across runs. They can later be enriched with an AI pass if desired.
class ContextFileService {
  /// Builds every context file as fileName → markdown content.
  Map<String, String> buildAll({
    required ProjectBrain brain,
    required List<GeneratedDoc> docs,
    required List<SessionRecord> sessions,
  }) {
    return {
      'AI_CONTEXT.md': aiContext(brain: brain, docs: docs, sessions: sessions),
      'PROJECT_BRAIN.md': projectBrain(brain: brain, docs: docs),
      'SESSION_SUMMARY.md': sessionSummary(
        brain: brain,
        docs: docs,
        latest: sessions.isNotEmpty ? sessions.last : null,
      ),
      'AI_CONTINUATION_PROMPT.md': continuationPrompt(
        brain: brain,
        docs: docs,
        sessions: sessions,
      ),
    };
  }

  String _list(List<String> items, {String empty = '_None detected._'}) {
    if (items.isEmpty) return empty;
    return items.map((i) => '- $i').join('\n');
  }

  String _completedDocList(List<GeneratedDoc> docs) {
    final done = docs.where((d) => d.status == DocStatus.completed).toList();
    if (done.isEmpty) return '_No documentation generated yet._';
    return done
        .map((d) => '- ${d.type.fileName}'
            '${d.providerUsed != null ? ' — via ${d.providerUsed}' : ''}')
        .join('\n');
  }

  // --- AI_CONTEXT.md ---------------------------------------------------------

  String aiContext({
    required ProjectBrain brain,
    required List<GeneratedDoc> docs,
    required List<SessionRecord> sessions,
  }) {
    final recent = sessions.isNotEmpty ? sessions.last : null;
    return '''
# AI_CONTEXT — ${brain.name}

> Handoff file. Hand this to GPT, Claude, Gemini, DeepSeek, Cursor, Windsurf,
> Copilot, or any other assistant so it can continue work without losing
> project understanding.

## Project Overview

- **Purpose:** ${brain.summary.isNotEmpty ? brain.summary : 'See generated README for the project purpose.'}
- **Primary languages:** ${brain.languages.isEmpty ? 'Unknown' : brain.languages.join(', ')}
- **Frameworks:** ${brain.frameworks.isEmpty ? 'Unknown' : brain.frameworks.join(', ')}

## Current Architecture

- **Architecture style:** ${brain.architecture}
- **Databases:** ${brain.databases.isEmpty ? 'None detected' : brain.databases.join(', ')}
- **Modules:**
${_list(brain.modules)}

### Folder structure

```
${brain.folderStructure.trim().isEmpty ? '(not available)' : brain.folderStructure.trim()}
```

## Important Files

${_list(brain.importantFiles)}

### Entry points

${_list(brain.entryPoints)}

## Features

- **Completed:** documentation generation, codebase analysis, multi-provider AI coordination.
- **In progress:** _track here as you work._
- **Planned:** _track here as you work._

## Current Issues

- **Known bugs:** _none recorded._
- **Technical debt:** _none recorded._
- **Blockers:** _none recorded._

## Recent Changes

${recent == null ? '_No sessions recorded yet._' : '''
- Last session: ${recent.date}
- Generated: ${recent.generatedDocumentation.isEmpty ? 'n/a' : recent.generatedDocumentation.join(', ')}
- Providers used: ${recent.aiProvidersUsed.isEmpty ? 'n/a' : recent.aiProvidersUsed.join(', ')}'''}

### Generated documentation
${_completedDocList(docs)}

## Recommended Next Tasks

${recent != null && recent.nextTasks.isNotEmpty ? _list(recent.nextTasks) : '''
- Review the generated documentation for accuracy.
- Fill in Features / Issues sections above as development proceeds.
- Add tests for any newly implemented modules.'''}

## Developer Notes

- This project was analyzed once; all AI agents share a single ProjectBrain.
- Dependencies detected: ${brain.dependencies.isEmpty ? 'none parsed' : brain.dependencies.take(20).join(', ')}${brain.dependencies.length > 20 ? ', …' : ''}.
- Git history present: ${brain.hasGitHistory ? 'yes' : 'no'}.
''';
  }

  // --- PROJECT_BRAIN.md ------------------------------------------------------

  String projectBrain({
    required ProjectBrain brain,
    required List<GeneratedDoc> docs,
  }) {
    return '''
# PROJECT_BRAIN — ${brain.name}

> Master memory file. A compressed, structured understanding of the entire
> project. More detailed than AI_CONTEXT.md.

## Snapshot

| Metric | Value |
|---|---|
| Files | ${brain.fileCount} |
| Lines of code | ${brain.totalLines} |
| Languages | ${brain.languages.isEmpty ? 'Unknown' : brain.languages.join(', ')} |
| Frameworks | ${brain.frameworks.isEmpty ? 'Unknown' : brain.frameworks.join(', ')} |
| Databases | ${brain.databases.isEmpty ? 'None' : brain.databases.join(', ')} |
| Architecture | ${brain.architecture} |
| Git history | ${brain.hasGitHistory ? 'yes' : 'no'} |

## Architecture

${brain.architecture == 'Unknown' ? 'Architecture style was not conclusively detected.' : 'Detected architecture: **${brain.architecture}**.'}

### Modules
${_list(brain.modules)}

### Folder structure
```
${brain.folderStructure.trim().isEmpty ? '(not available)' : brain.folderStructure.trim()}
```

## Important Files & Entry Points

### Entry points
${_list(brain.entryPoints)}

### Key files
${_list(brain.importantFiles)}

## Dependencies

${_list(brain.dependencies, empty: '_No dependencies parsed from manifests._')}

## Existing Documentation

${_list(brain.existingDocumentation, empty: '_No documentation files found in the source._')}

## Generated Documentation Summaries

${_docSummaries(docs)}

## Data Flow (inferred)

Entry point(s) initialise the application, configuration is loaded, and requests
or events flow through the detected modules above. Consult ARCHITECTURE.md for
the AI-generated narrative of data flow.
''';
  }

  String _docSummaries(List<GeneratedDoc> docs) {
    final done = docs.where((d) => d.status == DocStatus.completed).toList();
    if (done.isEmpty) return '_No documentation generated yet._';
    final buf = StringBuffer();
    for (final d in done) {
      final firstPara = d.content
          .split('\n')
          .firstWhere(
            (l) => l.trim().isNotEmpty && !l.trim().startsWith('#'),
            orElse: () => '',
          )
          .trim();
      buf.writeln('### ${d.type.fileName}');
      buf.writeln(firstPara.isEmpty ? '(see file)' : firstPara);
      buf.writeln();
    }
    return buf.toString().trimRight();
  }

  // --- SESSION_SUMMARY.md ----------------------------------------------------

  String sessionSummary({
    required ProjectBrain brain,
    required List<GeneratedDoc> docs,
    required SessionRecord? latest,
  }) {
    final generated =
        docs.where((d) => d.status == DocStatus.completed).map((d) => d.type.fileName);
    final failed =
        docs.where((d) => d.status == DocStatus.failed).map((d) => d.type.fileName);
    return '''
# SESSION_SUMMARY — ${brain.name}

**Date:** ${latest?.date ?? DateTime.now().toIso8601String().split('T').first}

## What changed

This cycle ran the multi-agent documentation pipeline over the project.

## What was generated

${generated.isEmpty ? '_Nothing completed in this cycle._' : generated.map((g) => '- $g').join('\n')}
${failed.isEmpty ? '' : '\n### Failed\n${failed.map((g) => '- $g').join('\n')}'}

### Providers used
${latest == null || latest.aiProvidersUsed.isEmpty ? '_n/a_' : latest.aiProvidersUsed.map((p) => '- $p').join('\n')}

## What should happen next

${latest != null && latest.nextTasks.isNotEmpty ? latest.nextTasks.map((t) => '- $t').join('\n') : '''
- Review generated docs for accuracy and fill gaps.
- Record completed features and fixed bugs in the next session.
- Regenerate any documents that failed.'''}
''';
  }

  // --- AI_CONTINUATION_PROMPT.md --------------------------------------------

  String continuationPrompt({
    required ProjectBrain brain,
    required List<GeneratedDoc> docs,
    required List<SessionRecord> sessions,
  }) {
    final recent = sessions.isNotEmpty ? sessions.last : null;
    return '''
# AI_CONTINUATION_PROMPT — ${brain.name}

Copy everything below into a new AI session to continue development.

---

You are continuing development on **${brain.name}**.

**Project Summary:**
${brain.summary.isNotEmpty ? brain.summary : 'A ${brain.languages.isEmpty ? '' : '${brain.languages.first} '}project using ${brain.frameworks.isEmpty ? 'no detected framework' : brain.frameworks.join(', ')}.'}

**Current State:**
- ${brain.fileCount} files, ${brain.totalLines} lines.
- Generated documentation: ${docs.where((d) => d.status == DocStatus.completed).map((d) => d.type.fileName).join(', ').ifEmptyText('none yet')}.

**Architecture:**
- ${brain.architecture}
- Modules: ${brain.modules.isEmpty ? 'n/a' : brain.modules.join(', ')}
- Entry points: ${brain.entryPoints.isEmpty ? 'n/a' : brain.entryPoints.join(', ')}

**Known Bugs:**
- None recorded. (Update before handoff if any exist.)

**Recent Changes:**
${recent == null ? '- No prior sessions recorded.' : '- ${recent.date}: generated ${recent.generatedDocumentation.join(', ').ifEmptyText('n/a')} using ${recent.aiProvidersUsed.join(', ').ifEmptyText('n/a')}.'}

**Current Sprint / Next Tasks:**
${recent != null && recent.nextTasks.isNotEmpty ? recent.nextTasks.map((t) => '- $t').join('\n') : '- Review and refine generated documentation.\n- Implement the next planned feature.'}

Follow existing architectural patterns. Do not re-architect unless necessary.
''';
  }
}

extension _IfEmpty on String {
  String ifEmptyText(String fallback) => trim().isEmpty ? fallback : this;
}
