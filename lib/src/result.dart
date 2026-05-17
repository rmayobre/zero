import 'dart:async';

import 'internal/eager.dart';
import 'either.dart';
import 'internal/throws.dart';
import 'internal/typedefs.dart';
import 'option.dart';
import 'task.dart';

typedef _ResultData<T extends Object> = ({T? success, Object? failure, StackTrace? stackTrace});

/// Represents the outcome of an operation that may either succeed with a value
/// of type [T] or fail with an error object and an optional [StackTrace].
///
/// Construct via [Result.success], [Result.failure], or the catching factory
/// [Result.run]. The type parameter [T] must extend [Object] — success values
/// are never `null`.
@eager
extension type const Result<T extends Object>._(_ResultData<T> _data) {

  /// Creates a failed [Result] wrapping [error] and an optional [stackTrace].
  const Result.failure(Object error, [StackTrace? stackTrace]) : this._((success: null, failure: error, stackTrace: stackTrace));

  /// Creates a successful [Result] wrapping [value].
  const Result.success(T value) : this._((success: value, failure: null, stackTrace: null));

  /// Runs [compute] and wraps the return value in [Result.success].
  ///
  /// If [compute] throws, the error and current stack trace are captured in a
  /// [Result.failure] instead of propagating.
  factory Result.run(Calculation<T> compute) {
    try {
      return Result.success(compute());
    } catch (error, stacktrace) {
      return Result.failure(error, stacktrace);
    }
  }

  /// Runs [compute] and wraps the return value in [Future] [Result.success].
  ///
  /// If [compute] throws, the error and current stack trace are captured in a
  /// [Result.failure] instead of propagating.
  static Future<Result<T>> runAsync<T extends Object>(Calculation<FutureOr<T>> compute) async {
    try {
      return Result.success(await compute());
    } catch (error, stacktrace) {
      return Result.failure(error, stacktrace);
    }
  }

  //
  // Getters
  //

  /// Returns `true` if this is a success.
  bool get isSuccess => _data.failure == null;

  /// Returns `true` if this is a failure.
  bool get isFailure => _data.failure != null;

  /// Returns the success value, or [def] if this is a failure.
  T getOrDefault(T def) => _data.success ?? def;

  /// Returns the success value, or the result of [compute] if this is a failure.
  @throws
  T getOrElse(Calculation<T> compute) => _data.success ?? compute();

  /// Returns the success value, or `null` if this is a failure.
  T? getOrNull() => _data.success;

  /// Returns the success value, or rethrows the captured error (with its original
  /// stack trace when available) if this is a failure.
  @throws
  T getOrThrow() {
    if (isFailure) {
      var stacktrace = _data.stackTrace;
      if (stacktrace != null) Error.throwWithStackTrace(_data.failure!, stacktrace);
      throw _data.failure!;
    }
    return _data.success!;
  }

  //
  // Transformers
  //

  /// Reduces this [Result] to a single value by applying [onSuccess] or [onFailure].
  @throws
  R fold<R extends Object>({
    required Transformation<T, R> onSuccess,
    required Transformation<Object, R> onFailure,
  }) {
    if (isSuccess) {
      return onSuccess(getOrThrow());
    } else {
      return onFailure(_data.failure!);
    }
  }

  /// Transforms the success value using [transform].
  ///
  /// If [transform] throws, the error is captured as a new failure. Failures
  /// are forwarded unchanged.
  Result<R> map<R extends Object>(Transformation<T, R> transform) {
    try {
      if (isSuccess) {
        return Result.success(transform(getOrThrow()));
      } else {
        return Result.failure(_data.failure!, _data.stackTrace);
      }
    } catch (error, stacktrace) {
      return Result.failure(error, stacktrace);
    }
  }

  /// Applies [f] to the success value and returns the resulting [Result].
  ///
  /// Failures are forwarded unchanged; exceptions thrown by [f] are captured.
  Result<R> flatMap<R extends Object>(Transformation<T, Result<R>> f) {
    try {
      if (isSuccess) return f(getOrThrow());
      return Result.failure(_data.failure!, _data.stackTrace);
    } catch (error, stacktrace) {
      return Result.failure(error, stacktrace);
    }
  }

  /// Applies [f] to the failure error and returns the resulting [Result].
  ///
  /// Successes are returned unchanged; exceptions thrown by [f] are captured.
  Result<T> recoverWith(Transformation<Object, Result<T>> f) {
    try {
      if (isFailure) return f(_data.failure!);
    } catch (error, stacktrace) {
      return Result.failure(error, stacktrace);
    }
    return this;
  }

  /// Transforms the failure error object using [transform], leaving successes unchanged.
  ///
  /// Exceptions thrown by [transform] are captured as a new failure.
  Result<T> mapFailure(Transformation<Object, Object> transform) {
    try {
      if (isFailure) return Result.failure(transform(_data.failure!));
    } catch (error, stacktrace) {
      return Result.failure(error, stacktrace);
    }
    return this;
  }

  /// Converts a failure into a success by applying [transform] to the error.
  ///
  /// Successes are returned unchanged; exceptions thrown by [transform] are captured.
  Result<T> recover(Transformation<Object, T> transform) {
    try {
      if (isFailure) return Result.success(transform(_data.failure!));
    } catch (error, stacktrace) {
      return Result.failure(error, stacktrace);
    }
    return this;
  }

  /// Converts this [Result] into an [Either], with success mapped to [Left]
  /// and failure mapped to [Right].
  Either<T, Object> either() {
    try {
      final value = _data.success;
      if (value is T) return Either.left(value);
      return Either.right(_data.failure!);
    } catch (error) {
      return Either.right(error);
    }
  }

  /// Converts this [Result] into an [Option], discarding any failure information.
  Option<T> asOption() => Option.run(getOrNull);

  /// Returns a [Future] that completes with the success value or rethrows the failure.
  Future<T> asFuture() async => getOrThrow();

  /// Wraps this [Result] in a [Task] that resolves with the success value or
  /// rethrows the failure when run.
  Task<T> asTask() => Task(() async => getOrThrow());

  //
  // Side Effects
  //

  /// Calls [call] with the success value if this is a success, then returns `this`.
  @throws
  Result<T> onSuccess(ValueCallable<T> call) {
    if (isSuccess) call(getOrThrow());
    return this;
  }

  /// Calls [call] with the failure error if this is a failure, then returns `this`.
  @throws
  Result<T> onFailure(ValueCallable<Object> call) {
    if (isFailure) call(_data.failure!);
    return this;
  }
}
