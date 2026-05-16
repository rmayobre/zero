import 'package:meta/meta.dart';

/// Marks a type or function as eagerly evaluated.
///
/// Eager types compute and hold their value immediately upon construction.
/// Apply to extension types whose backing value is a concrete result rather
/// than a deferred computation (i.e. not a function or [Future]).
///
/// ```dart
/// @eager
/// extension type Option<T>._(T? _value) { ... }
/// ```
@internal
const eager = _Eager();

final class _Eager {
  const _Eager();
}
