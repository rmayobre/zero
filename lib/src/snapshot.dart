import 'dart:async';

import 'internal/eager.dart';
import 'internal/throws.dart';
import 'internal/typedefs.dart';
import 'flow.dart';
import 'task.dart';

/// An eager, stateful hot-stream wrapper that holds the latest value of type [T]
/// and broadcasts subsequent changes to all listeners.
///
/// Unlike [Flow], [Snapshot] always has a current [value]. Consecutive duplicate
/// values are suppressed — the stream only emits when the value actually changes.
/// An optional [source] stream can be supplied to seed the snapshot from an
/// external producer.
@eager
extension type Snapshot<T extends Object>._(_SnapshotState<T> _data) {

  // @throws because source.listen() throws StateError if source is a
  // single-subscription stream that already has a listener.

  /// Creates a [Snapshot] with the given [initial] value.
  ///
  /// If [source] is provided its events are forwarded into the snapshot,
  /// deduplicated against the current [value]. Throws [StateError] if [source]
  /// is a single-subscription stream that already has a listener.
  @throws
  factory Snapshot(T initial, [Stream<T>? source]) {
    final data = _SnapshotState(initial);
    source?.listen(
      (sourceData) {
        if (sourceData != data.value) {
          data.value = sourceData;
          data.controller.add(sourceData);
        }
      },
      onError: data.controller.addError,
      onDone: data.controller.close,
    );
    return Snapshot._(data);
  }

  /// The current value held by this snapshot.
  T get value => _data.value;

  /// Updates the current value and broadcasts it to all listeners.
  ///
  /// Setting the same value that is already held is a no-op.
  set value(T v) {
    if (v == _data.value) return;
    _data.value = v;
    _data.controller.add(v);
  }

  // @throws because transformer is called immediately to derive the initial value.

  /// Returns a new [Snapshot] whose value is the result of applying [transformer]
  /// to the current value, and whose stream reflects future transformed events.
  @throws
  Snapshot<R> map<R extends Object>(Transformation<T, R> transformer) =>
      Snapshot(transformer(_data.value), _data.controller.stream.map(transformer));

  /// Returns a new [Snapshot] backed by the stream produced by [transformer],
  /// with [initial] as the starting value.
  ///
  /// The caller must supply [initial] because a synchronous starting value
  /// cannot be derived from an async [Flow].
  // flatMap cannot derive an initial value synchronously, so the caller supplies one.
  Snapshot<R> flatMap<R extends Object>(Transformation<T, Flow<R>> transformer, R initial) =>
      Snapshot(initial, _data.controller.stream.asyncExpand((s) => transformer(s).collect()));

  /// Returns a new [Snapshot] that forwards only elements satisfying [predicate].
  ///
  /// The current [value] is always preserved as the initial value regardless of
  /// whether it passes [predicate].
  Snapshot<T> filter(Predicate<T> predicate) =>
      Snapshot(_data.value, _data.controller.stream.where(predicate));

  /// Applies [process] to each emitted element as a side effect, then forwards
  /// the element unchanged.
  Snapshot<T> onEach(ValueCallable<T> process) =>
      Snapshot(_data.value, _data.controller.stream.map((element) {
        process(element);
        return element;
      }));

  /// Returns a new [Snapshot] limited to the next [n] emitted events.
  Snapshot<T> take(int n) => Snapshot(_data.value, _data.controller.stream.take(n));

  /// Returns a new [Snapshot] that skips the next [n] emitted events.
  Snapshot<T> drop(int n) => Snapshot(_data.value, _data.controller.stream.skip(n));

  //
  // Transformers
  //

  /// Exposes the underlying broadcast stream as a lazy [Flow].
  Flow<T> flow() => Flow(() => _data.controller.stream);

  /// Returns the underlying broadcast [Stream] directly.
  Stream<T> collect() => _data.controller.stream;

  /// Folds all emitted elements into a single value using [combine], starting
  /// from [initial]. Returns a [Task] that resolves when the stream closes.
  Task<R> fold<R extends Object>(R initial, Reducer<R, T> combine) =>
      Task(() => _data.controller.stream.fold(initial, combine));

  /// Asynchronous iteration of the flow.
  @throws
  void forEach(ValueCallable<T> process) async {
    await for (final element in collect()) {
      process(element);
    }
  }
}

final class _SnapshotState<T extends Object> {

  T value;

  final StreamController<T> controller; // Broadcast controller

  _SnapshotState(this.value) : controller = StreamController<T>.broadcast();
}
