import 'flow.dart';

extension IterableExtensions <T> on Iterable<T> {

  Flow<T> flow() => Flow.fromIterable(this);
}