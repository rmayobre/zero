import 'flow.dart';
import 'option.dart';

extension IterableExtensions <T> on Iterable<T> {

  Flow<T> flow() => Flow.fromIterable(this);

}

extension IterableOptionTransformer <T extends Object> on Iterable<T?> {

  Iterable<Option<T>> options<R extends Object>() sync* {
    for (final element in this) {
      yield Option(element);
    }
  }
}