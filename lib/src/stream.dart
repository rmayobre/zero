import 'flow.dart';

extension StreamExtensions<T> on Stream<T> {
  Flow<T> asFlow() => Flow(() async* {
    yield* this;
  });

  Stream<R> whereType<R>() => where((element) => element is R).cast<R>();
}
