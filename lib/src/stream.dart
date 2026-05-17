import 'flow.dart';

/// Extensions on [Stream] for converting to zero-nads types.
extension StreamExtensions <T> on Stream<T> {

  /// Wraps this [Stream] in a lazy [Flow].
  Flow<T> asFlow() => Flow(() async* {
    yield* this;
  });

  /// Filters elements by type, emitting only those that are instances of [R].
  Stream<R> whereType<R>() => where((element) => element is R).cast<R>();
}
