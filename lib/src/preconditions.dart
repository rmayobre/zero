import 'inline.dart';
import 'internal/constants.dart';
import 'internal/throws.dart';

/// Throws [StateError] if [condition] is `false`.
///
/// Used to assert internal invariants. Pass a lazy [message] to avoid
/// constructing the message string when the condition passes.
@throws
@inline
void check(bool condition, [String Function()? message]) {
  if (!condition) throw StateError(message?.call() ?? conditionCheckMsg);
}

/// Returns [value] if it is non-null, otherwise throws [StateError].
///
/// Used to assert that an internal value expected to be present is not `null`.
@throws
@inline
T checkNotNull<T extends Object>(T? value, [String Function()? message]) {
  if (value != null) return value;
  throw StateError(message?.call() ?? nullCheckMsg);
}

/// Returns [value] cast to [T] if it is an instance of [T], otherwise throws [StateError].
///
/// Used to assert internal type invariants.
@throws
@inline
T checkTypeOf<T>(dynamic value, [String Function()? message]) {
  if (value is T) return value;
  throw StateError(message?.call() ?? '$typeCheckMsg: $T');
}

/// Unconditionally throws [StateError] with [message].
///
/// Declared as [Never] so the compiler treats call sites as unreachable.
@throws
@inline
Never error(String message) => throw StateError(message);

/// Throws [ArgumentError] if [condition] is `false`.
///
/// Used to validate caller-supplied arguments. Pass a lazy [message] to avoid
/// constructing the message string when the condition passes.
@throws
@inline
void require(bool condition, [String Function()? message]) {
  if (condition == false) throw ArgumentError(message?.call() ?? conditionCheckMsg);
}

/// Returns [value] if it is non-null, otherwise throws [ArgumentError].
///
/// Used to reject `null` values supplied by the caller.
@throws
@inline
T requireNotNull<T extends Object>(T? value, [String Function()? message]) {
  if (value != null) return value;
  throw ArgumentError.notNull(message?.call() ?? nullCheckMsg);
}

/// Returns [value] cast to [T] if it is an instance of [T], otherwise throws [ArgumentError].
///
/// Used to reject caller-supplied values of the wrong type.
@throws
@inline
T requireTypeOf<T>(dynamic value, [String Function()? message]) {
  if (value is T) return value;
  throw ArgumentError(message?.call() ?? '$typeCheckMsg: $T');
}

/// Always throws [UnimplementedError] with an optional [message].
///
/// Use as a placeholder for code that has not yet been implemented.
// ignore: non_constant_identifier_names
@throws
Never TODO([String? message]) => throw UnimplementedError(message);