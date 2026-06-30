/// A minimal cooperative cancellation signal. Agents check [isCancelled]
/// between steps; cancelling prevents not-yet-started work from running.
///
/// Note: this cancels cooperatively. A request already in flight will still
/// complete its HTTP round-trip; for hard mid-flight aborts, wire a Dio
/// `CancelToken` through the providers.
class CancellationToken {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}

/// Thrown by orchestrator work when a [CancellationToken] is tripped.
class CancelledException implements Exception {
  const CancelledException();
  @override
  String toString() => 'Operation cancelled';
}
