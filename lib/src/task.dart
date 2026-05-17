import 'internal/lazy.dart';
import 'internal/typedefs.dart';

/// A lazy, deferred asynchronous computation that produces a value of type [T].
///
/// [Task] wraps a `Future`-returning function and does not execute until [run]
/// is called. Composition via [map], [flatMap], and [zip] builds a new [Task]
/// without triggering execution.
@lazy
extension type Task<T>(Calculation<Future<T>> _compute) {

  /// Creates a [Task] that completes immediately with [value].
  factory Task.of(T value) => Task(() async => value);

  /// Transforms the resolved value using [transform].
  Task<R> map<R extends Object>(Transformation<T, R> transform) {
    return Task(() => _compute().then(transform));
  }

  /// Applies [transform] to the resolved value and runs the resulting [Task].
  Task<R> flatMap<R extends Object>(Transformation<T, Task<R>> transform) {
    return Task(() => _compute().then((value) => transform(value).run()));
  }

  /// Awaits the computation and reduces the outcome to a single value via
  /// [onSuccess] or [onFailure].
  Future<R> foldAsync<R>({
    required Transformation<T, R> onSuccess,
    required Transformation<Object, R> onFailure,
  }) async {
    try {
      final val = await _compute();
      return onSuccess(val);
    } catch (error) {
      return onFailure(error);
    }
  }

  /// Returns a new [Task] that applies [transform] to any thrown error,
  /// converting it into a successful value.
  Task<T> recover(Transformation<Object, T> transform) {
    return Task(() async {
      try {
        return await _compute();
      } catch (error) {
        return transform(error);
      }
    });
  }

  /// Calls [f] with the resolved value as a side effect, then forwards the value.
  Task<T> onSuccess(ValueCallable<T> f) {
    return Task(() => _compute().then((value) {
      f(value);
      return value;
    }));
  }

  /// Calls [f] with any thrown error as a side effect, then rethrows it.
  Task<T> onFailure(ValueCallable<Object> f) {
    return Task(() => _compute().onError((error, _) {
      f(error!);
      return Future.error(error);
    }));
  }

  /// Runs this [Task] and [other] concurrently, returning both results as a tuple.
  Task<(T, R)> zip<R extends Object>(Task<R> other) {
    return Task(() async {
      final results = await Future.wait([_compute(), other.run()]);
      return (results[0] as T, results[1] as R);
    });
  }

  /// Executes the deferred computation and returns the resulting [Future].
  ///
  /// Any synchronous exception thrown by the computation factory is converted
  /// to a failed [Future] rather than propagating directly.
  Future<T> run() {
    try {
      return _compute();
    } catch(error, stackTrace) {
      return Future.error(error, stackTrace);
    }
  }
}

/// Extensions on [Task] whose result is an [Iterable].
extension IterableTaskExtensions <T extends Object> on Task<Iterable<T>> {

  /// Runs the [Task] and emits each element of the resulting iterable as a [Stream].
  Stream<T> flatten() async* {
    yield* Stream.fromIterable(await run());
  }
}
