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
  factory Flow.of(Stream<T> source) => Flow(() => source);
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

  Flow<T> filter(Predicate<T> predicate) {
    return Flow(() => _compute().where(predicate));
  }

  Flow<T> onEach(ValueCallable<T> f) {
    return Flow(
      () => _compute().map((value) {
        f(value);
        return value;
      }),
    );
  }

  /// Attempts to recover the flow from any errors thrown during collection.
  @throws
  Flow<T> recover(Transformation<(Object, StackTrace?), T> attempt) =>
      Flow(() async* {
        yield* _compute().handleError(
          (error, stacktrace) => attempt((error, stacktrace)),
        );
      });

  Flow<T> take(int n) => Flow(() => _compute().take(n));

  Flow<T> drop(int n) => Flow(() => _compute().skip(n));

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

extension NonNullFlowExtensions<T extends Object> on Flow<T> {
  Snapshot<T> toSnapshot(T initial) => Snapshot(initial, collect());
}
