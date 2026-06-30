import 'dart:math' as math;

import '../../models/ai_provider_config.dart';
import '../../models/generated_doc.dart';
import '../../models/source_file.dart';
import '../ai/ai_provider_factory.dart';

/// A retrievable unit of text with its origin and optional embedding vector.
class RagChunk {
  RagChunk({required this.source, required this.text, this.vector});

  final String source;
  final String text;
  List<double>? vector;

  // Lexical fallback representation (term -> tf-idf weight).
  Map<String, double>? lexical;
}

/// A retrieval result with its relevance score.
class RetrievedChunk {
  RetrievedChunk(this.chunk, this.score);
  final RagChunk chunk;
  final double score;
}

/// Builds a searchable index over source code + generated docs and serves
/// semantic search for the chat feature (Retrieval-Augmented Generation).
///
/// Strategy: if the active provider exposes embeddings, vectors are used with
/// cosine similarity. Otherwise the service falls back to an on-device TF-IDF
/// lexical index so chat works without an embedding-capable key.
class EmbeddingService {
  EmbeddingService(this._factory);

  final AiProviderFactory _factory;

  final List<RagChunk> _chunks = [];
  Map<String, double> _idf = {};
  bool _usingVectors = false;

  bool get isIndexed => _chunks.isNotEmpty;
  bool get usingVectors => _usingVectors;

  /// Chunk size in characters with a small overlap to preserve context.
  static const int _chunkChars = 1200;
  static const int _overlap = 150;

  /// Builds the index. Tries provider embeddings; gracefully degrades to
  /// lexical retrieval on any failure.
  Future<void> indexProject({
    required List<SourceFile> files,
    required List<GeneratedDoc> docs,
    required AiProviderConfig config,
    String? apiKey,
  }) async {
    _chunks
      ..clear()
      ..addAll(_chunkFiles(files))
      ..addAll(_chunkDocs(docs));

    _usingVectors = false;
    if (apiKey != null && apiKey.isNotEmpty && config.embeddingModel != null) {
      try {
        await _embedAll(config, apiKey);
        _usingVectors = true;
        return;
      } catch (_) {
        // fall through to lexical
      }
    }
    _buildLexicalIndex();
  }

  /// Returns the top-[k] chunks most relevant to [query].
  Future<List<RetrievedChunk>> search(
    String query, {
    int k = 6,
    AiProviderConfig? config,
    String? apiKey,
  }) async {
    if (_chunks.isEmpty) return [];

    if (_usingVectors && config != null && apiKey != null) {
      try {
        final provider = _factory.resolve(config.type);
        final qVec = (await provider.embed(
          inputs: [query],
          config: config,
          apiKey: apiKey,
        ))
            .first;
        final scored = _chunks
            .where((c) => c.vector != null)
            .map((c) => RetrievedChunk(c, _cosine(qVec, c.vector!)))
            .toList()
          ..sort((a, b) => b.score.compareTo(a.score));
        return scored.take(k).toList();
      } catch (_) {
        // fall through to lexical
      }
    }

    final qVec = _lexicalVector(_tokenize(query));
    final scored = _chunks.map((c) {
      final score = _cosineSparse(qVec, c.lexical ?? const {});
      return RetrievedChunk(c, score);
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return scored.where((r) => r.score > 0).take(k).toList();
  }

  // ---- chunking ------------------------------------------------------------

  Iterable<RagChunk> _chunkFiles(List<SourceFile> files) sync* {
    for (final f in files) {
      yield* _split(f.content, f.relativePath);
    }
  }

  Iterable<RagChunk> _chunkDocs(List<GeneratedDoc> docs) sync* {
    for (final d in docs) {
      if (d.content.isEmpty) continue;
      yield* _split(d.content, 'docs/${d.type.fileName}');
    }
  }

  Iterable<RagChunk> _split(String text, String source) sync* {
    if (text.isEmpty) return;
    var start = 0;
    while (start < text.length) {
      final end = math.min(start + _chunkChars, text.length);
      yield RagChunk(source: source, text: text.substring(start, end));
      if (end == text.length) break;
      start = end - _overlap;
    }
  }

  // ---- embeddings ----------------------------------------------------------

  Future<void> _embedAll(AiProviderConfig config, String apiKey) async {
    final provider = _factory.resolve(config.type);
    const batch = 64;
    for (var i = 0; i < _chunks.length; i += batch) {
      final slice = _chunks.sublist(i, math.min(i + batch, _chunks.length));
      final vectors = await provider.embed(
        inputs: slice.map((c) => c.text).toList(),
        config: config,
        apiKey: apiKey,
      );
      for (var j = 0; j < slice.length && j < vectors.length; j++) {
        slice[j].vector = vectors[j];
      }
    }
  }

  // ---- lexical (TF-IDF) ----------------------------------------------------

  void _buildLexicalIndex() {
    final docFreq = <String, int>{};
    final perChunkCounts = <Map<String, int>>[];

    for (final c in _chunks) {
      final counts = <String, int>{};
      for (final t in _tokenize(c.text)) {
        counts.update(t, (v) => v + 1, ifAbsent: () => 1);
      }
      perChunkCounts.add(counts);
      for (final t in counts.keys) {
        docFreq.update(t, (v) => v + 1, ifAbsent: () => 1);
      }
    }

    final n = _chunks.length;
    _idf = {
      for (final e in docFreq.entries)
        e.key: math.log((n + 1) / (e.value + 1)) + 1,
    };

    for (var i = 0; i < _chunks.length; i++) {
      final counts = perChunkCounts[i];
      final total = counts.values.fold<int>(0, (a, b) => a + b);
      final vec = <String, double>{};
      counts.forEach((term, count) {
        vec[term] = (count / total) * (_idf[term] ?? 0);
      });
      _chunks[i].lexical = vec;
    }
  }

  Map<String, double> _lexicalVector(List<String> tokens) {
    final counts = <String, int>{};
    for (final t in tokens) {
      counts.update(t, (v) => v + 1, ifAbsent: () => 1);
    }
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return const {};
    return {
      for (final e in counts.entries)
        e.key: (e.value / total) * (_idf[e.key] ?? 0),
    };
  }

  List<String> _tokenize(String text) => text
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9_]+'))
      .where((t) => t.length > 1)
      .toList();

  // ---- similarity ----------------------------------------------------------

  double _cosine(List<double> a, List<double> b) {
    final len = math.min(a.length, b.length);
    var dot = 0.0, na = 0.0, nb = 0.0;
    for (var i = 0; i < len; i++) {
      dot += a[i] * b[i];
      na += a[i] * a[i];
      nb += b[i] * b[i];
    }
    if (na == 0 || nb == 0) return 0;
    return dot / (math.sqrt(na) * math.sqrt(nb));
  }

  double _cosineSparse(Map<String, double> a, Map<String, double> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final smaller = a.length < b.length ? a : b;
    final larger = identical(smaller, a) ? b : a;
    var dot = 0.0;
    smaller.forEach((k, v) {
      final o = larger[k];
      if (o != null) dot += v * o;
    });
    final na = math.sqrt(a.values.fold<double>(0, (s, v) => s + v * v));
    final nb = math.sqrt(b.values.fold<double>(0, (s, v) => s + v * v));
    if (na == 0 || nb == 0) return 0;
    return dot / (na * nb);
  }
}
