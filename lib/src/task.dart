import 'internal/lazy.dart';
import 'internal/typedefs.dart';

@lazy
extension type Task<T>(Calculation<Future<T>> _compute) {
  factory Task.of(T value) => Task(() async => value);

  Task<R> map<R extends Object>(Transformation<T, R> transform) {
    return Task(() => _compute().then(transform));
  }

  Task<R> flatMap<R extends Object>(Transformation<T, Task<R>> transform) {
    return Task(() => _compute().then((value) => transform(value).run()));
  }

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

  Task<T> recover(Transformation<Object, T> transform) {
    return Task(() async {
      try {
        return await _compute();
      } catch (error) {
        return transform(error);
      }
    });
  }

  Task<T> onSuccess(ValueCallable<T> f) {
    return Task(
      () => _compute().then((value) {
        f(value);
        return value;
      }),
    );
  }

  Task<T> onFailure(ValueCallable<Object> f) {
    return Task(
      () => _compute().onError((error, _) {
        f(error!);
        return Future.error(error);
      }),
    );
  }

  Task<(T, R)> zip<R extends Object>(Task<R> other) {
    return Task(() async {
      final results = await Future.wait([_compute(), other.run()]);
      return (results[0] as T, results[1] as R);
    });
  }

  Future<T> run() {
    try {
      return _compute();
    } catch (error, stackTrace) {
      return Future.error(error, stackTrace);
    }
  }
}

extension IterableTaskExtensions<T extends Object> on Task<Iterable<T>> {
  Stream<T> flatten() async* {
    yield* Stream.fromIterable(await run());
  }
}
