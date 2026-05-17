import 'dart:async';

import 'internal/lazy.dart';
import 'internal/throws.dart';
import 'internal/typedefs.dart';
import 'snapshot.dart';
import 'task.dart';

/// [Flow] handles a sequence of events asynchronously and lazily.
/// It wraps a function that produces a Stream: [() -> Stream<S>].
@lazy
extension type const Flow<T>._(Calculation<Stream<T>> _compute) {
  /// Creates a Flow from a Stream factory.
  const Flow(Calculation<Stream<T>> compute) : this._(compute);

  /// Creates a [Flow] from an existing [Stream].
  ///
  /// The same [source] instance is returned on each [collect] call.
  factory Flow.of(Stream<T> source) => Flow(() => source);

  /// Creates a [Flow] that emits the elements of [iterable].
  factory Flow.fromIterable(Iterable<T> iterable) =>
      Flow(() => Stream.fromIterable(iterable));

  /// Transforms each event emitted by the Flow.
  Flow<R> map<R extends Object>(Transformation<T, R> transformer) {
    return Flow(() => _compute().map(transformer));
  }

  /// Projects each element of the Flow into a new Flow and flattens the result.
  Flow<R> flatMap<R extends Object>(Transformation<T, Flow<R>> transformer) {
    return Flow(() => _compute().asyncExpand((s) => transformer(s).collect()));
  }

  /// Keeps only the elements that satisfy [predicate].
  Flow<T> filter(Predicate<T> predicate) {
    return Flow(() => _compute().where(predicate));
  }

  /// Applies [f] to each element as a side effect, then forwards the element unchanged.
  Flow<T> onEach(ValueCallable<T> f) {
    return Flow(
      () => _compute().map((value) {
        f(value);
        return value;
      }),
    );
  }

  /// Attempts to recover the flow from any errors thrown during collection.
  ///
  /// Each error is passed to [attempt] and the returned value is emitted as a
  /// data event in place of the error. If [attempt] itself throws, the new
  /// exception is forwarded as an error downstream.
  @throws
  Flow<T> recover(Transformation<(Object, StackTrace?), T> attempt) => Flow(() {
    return _compute().transform(StreamTransformer.fromHandlers(
      handleData: (data, sink) => sink.add(data),
      handleError: (error, stackTrace, sink) {
        try {
          sink.add(attempt((error, stackTrace)));
        } catch (e, st) {
          sink.addError(e, st);
        }
      },
    ));
  });

  /// Silently drops any errors emitted by the flow, preventing them from
  /// propagating to the subscriber. Data events pass through unchanged.
  Flow<T> catchErrors() => Flow(() => _compute().transform(
    StreamTransformer.fromHandlers(
      handleData: (data, sink) => sink.add(data),
      handleError: (_, __, ___) {},
    ),
  ));

  /// Emits at most the first [n] elements.
  Flow<T> take(int n) => Flow(() => _compute().take(n));

  /// Skips the first [n] elements.
  Flow<T> drop(int n) => Flow(() => _compute().skip(n));

  /// Reduces all emitted elements into a single value using [combine], starting
  /// from [initial]. Returns a [Task] that resolves when the stream closes.
  Task<R> fold<R extends Object>(R initial, Reducer<R, T> combine) {
    return Task(() => _compute().fold(initial, combine));
  }

  /// Subscribes to the stream and returns the native [Stream].
  @throws
  Stream<T> collect() => _compute();

  /// Asynchronous iteration of the flow.
  @throws
  void forEach(ValueCallable<T> process) async {
    await for (final element in _compute()) {
      process(element);
    }
  }
}

/// Extensions on non-nullable [Flow] elements.
extension NonNullFlowExtensions <T extends Object> on Flow<T> {

  /// Converts this [Flow] into a [Snapshot] with the given [initial] value.
  ///
  /// The [Snapshot] holds the latest emitted value and broadcasts subsequent
  /// events to all listeners.
  Snapshot<T> toSnapshot(T initial) => Snapshot(initial, collect());
}
