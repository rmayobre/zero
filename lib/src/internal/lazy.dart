import 'package:meta/meta.dart';

/// Marks a type or function as lazily evaluated.
///
/// Lazy types wrap a deferred computation and do not execute it until
/// explicitly forced. Apply to extension types whose backing value is a
/// [Calculation] (or similar function type) that produces the result on demand.
///
/// ```dart
/// @lazy
/// extension type Task<T>._(Calculation<Future<T>> _computation) { ... }
/// ```
@internal
const lazy = _Lazy();

final class _Lazy {
  const _Lazy();
}
