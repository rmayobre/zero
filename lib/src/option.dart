import 'internal/eager.dart';
import 'internal/throws.dart';
import 'internal/typedefs.dart';
import 'preconditions.dart';

/// An extension type representing a nullable value, either `Some(value)` or `None`.
/// This is a zero-cost wrapper with no runtime overhead.
@eager
extension type const Option<T extends Object>(T? _value) {
  /// Creates an `Option` representing the absence of a value (`None`).
  const Option.nothing() : this(null);

  /// Creates an `Option` by running a lazy computation to produce a value.
  ///
  /// @param compute The lazy computation to execute.
  /// @return An `Option<T>` containing the result of the computation.
  @throws
  factory Option.run(Calculation<T?> compute) => Option(compute());

  /// Checks if the `Option` contains a value (`Some(value)`).
  bool get isSome => _value != null;

  /// Checks if the `Option` is empty (`None`).
  bool get isNone => _value == null;

  /// Returns the value if it exists, otherwise returns the default value.
  ///
  /// @param def The default value to return if the option is `None`.
  T getOrDefault(T def) => _value ?? def;

  /// Returns the value if it exists, otherwise executes the provided computation to get the value.
  ///
  /// @param compute The lazy computation to run if the option is `None`.
  /// @return The value if `Some`, or the result of `compute()` if `None`.
  @throws
  T getOrElse(Calculation<T> compute) => _value ?? compute();

  /// Returns the value if it exists, otherwise throws an error.
  ///
  /// @throws T If the option is `None`.
  @throws
  T getOrThrow() => checkNotNull(_value, () => 'Option<$T> was null.');

  /// Returns the nullable value itself.
  T? getOrNull() => _value;

  /// Transforms the value inside the `Option` using the provided transformation function.
  /// If the option is `None`, the result is `None`.
  ///
  /// @param f The transformation function to apply to the contained value.
  /// @return A new `Option<R>` with the transformed value or `None`.
  @throws
  Option<R> map<R extends Object>(Transformation<T, R> f) {
    final val = _value;
    return val == null ? Option<R>(null) : Option<R>(f(val));
  }

  /// Flattens the `Option` by applying a transformation that returns an `Option`.
  /// If the option is `None`, the result is `None`.
  ///
  /// @param f The transformation function that maps `T` to an `Option<R>`.
  /// @return A new `Option<R>`.
  @throws
  Option<R> flatMap<R extends Object>(Transformation<T, Option<R>> f) {
    final val = _value;
    return val == null ? Option<R>(null) : f(val);
  }

  /// Returns the value contained in this option if it is `Some`, otherwise returns the `other` option.
  ///
  /// @param other The alternative `Option` to fall back on.
  /// @return The value from the current option or the `other` option's value.
  Option<T> orElse(Option<T> other) => isSome ? this : other;

  /// Filters the `Option`, returning `Some` only if the `predicate` is true.
  /// If the option is `None`, it remains `None`.
  ///
  /// @param predicate The condition to test on the contained value.
  /// @return The filtered `Option<T>`.
  @throws
  Option<T> filter(Predicate<T> predicate) {
    final val = _value;
    if (val == null) return this;
    return predicate(val) ? this : Option<T>(null);
  }

  /// Performs a side effect on the value inside the `Option`.
  /// If the option is `Some`, the side effect is performed.
  ///
  /// @param f The side effect function to execute.
  ///return this;
  @throws
  Option<T> tap(ValueCallable<T> f) {
    final val = _value;
    if (val != null) f(val);
    return this;
  }

  /// Zips the current `Option` with another `Option`, returning an `Option` of a tuple.
  /// If either option is `None`, the result is `None`.
  ///
  /// @param other The other `Option` to zip with.
  /// @return An `Option<(T, R)>` containing the zipped values if both are `Some`.
  Option<(T, R)> zip<R extends Object>(Option<R> other) {
    final a = _value;
    final b = other._value;
    if (a == null || b == null) return Option<(T, R)>(null);
    return Option<(T, R)>((a, b));
  }

  /// Converts the `Option` into a `List`. If the option is `Some`, the list contains one element; otherwise, it is empty.
  ///
  /// @return A `List<T>` containing the value if `Some`, or an empty list if `None`.
  List<T> toList() {
    final val = _value;
    return val == null ? [] : [val];
  }

  /// Performs a fold operation over the `Option`.
  ///
  /// @param onNone The function to call if the option is `None`.
  /// @param onSome The function to call if the option is `Some`, receiving the contained value.
  /// @return The result of the fold operation.
  @throws
  R fold<R>(Calculation<R> onNone, Transformation<T, R> onSome) {
    final val = _value;
    return val == null ? onNone() : onSome(val);
  }
}
