import 'internal/lazy.dart';
import 'internal/throws.dart';
import 'internal/typedefs.dart';

/// An extension type representing a synchronous effectful computation.
/// This describes a sequence of operations that need to be run by an external executor.
@lazy
extension type const Effect<T extends Object>(Calculation<T> _compute) {

  /// Executes the synchronous computation to get the result.
  /// This method is synchronous in terms of the monad's execution, but the computation itself might involve blocking I/O if the caller handles it.
  ///
  /// @return The result of the computation.
  @throws
  T run() => _compute();

  /// Maps the result of the synchronous computation using a transformation.
  ///
  /// @param f The transformation function to apply to the result.
  /// @return A new `Effect<R>` with the transformed result.
  Effect<R> map<R extends Object>(Transformation<T, R> transform) =>
      Effect<R>(() => transform(_compute()));

  /// Flattens the `Effect` into a potentially nested `Effect`.
  ///
  /// @param f The function that transforms the result into another `Effect`.
  /// @return A new `Effect<R>`.
  Effect<R> flatMap<R extends Object>(Transformation<T, Effect<R>> transform) =>
      Effect<R>(() => transform(_compute()).run());

  /// Applies a side effect to the result of the computation.
  /// This is for effects that don't directly return a value but perform actions.
  ///
  /// @param f The side effect function to execute.
  Effect<T> onEach(ValueCallable<T> sideEffect) => Effect<T>(() {
    final result = _compute();
    sideEffect(result);
    return result;
  });
}
