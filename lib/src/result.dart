import 'internal/eager.dart';
import 'either.dart';
import 'internal/throws.dart';
import 'internal/typedefs.dart';
import 'option.dart';
import 'task.dart';

typedef _ResultData<T extends Object> = ({
  T? success,
  Object? failure,
  StackTrace? stackTrace,
});

@eager
extension type const Result<T extends Object>._(_ResultData<T> _data) {
  const Result.failure(Object error, [StackTrace? stackTrace])
    : this._((success: null, failure: error, stackTrace: stackTrace));
  const Result.success(T value)
    : this._((success: value, failure: null, stackTrace: null));

  factory Result.run(Calculation<T> compute) {
    try {
      final T value = compute();
      return Result.success(value);
    } catch (error, stacktrace) {
      return Result.failure(error, stacktrace);
    }
  }

  //
  // Getters
  //

  bool get isSuccess => _data.failure == null;
  bool get isFailure => _data.failure != null;

  T getOrDefault(T def) => _data.success ?? def;

  @throws
  T getOrElse(Calculation<T> compute) => _data.success ?? compute();

  T? getOrNull() => _data.success;

  @throws
  T getOrThrow() {
    if (isFailure) {
      var stacktrace = _data.stackTrace;
      if (stacktrace != null)
        Error.throwWithStackTrace(_data.failure!, stacktrace);
      throw _data.failure!;
    }
    return _data.success!;
  }

  //
  // Transformers
  //

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

  Result<R> flatMap<R extends Object>(Transformation<T, Result<R>> f) {
    try {
      if (isSuccess) return f(getOrThrow());
      return Result.failure(_data.failure!, _data.stackTrace);
    } catch (error, stacktrace) {
      return Result.failure(error, stacktrace);
    }
  }

  Result<T> recoverWith(Transformation<Object, Result<T>> f) {
    try {
      if (isFailure) return f(_data.failure!);
    } catch (error, stacktrace) {
      return Result.failure(error, stacktrace);
    }
    return this;
  }

  Result<T> mapFailure(Transformation<Object, Object> transform) {
    try {
      if (isFailure) return Result.failure(transform(_data.failure!));
    } catch (error, stacktrace) {
      return Result.failure(error, stacktrace);
    }
    return this;
  }

  Result<T> recover(Transformation<Object, T> transform) {
    try {
      if (isFailure) return Result.success(transform(_data.failure!));
    } catch (error, stacktrace) {
      return Result.failure(error, stacktrace);
    }
    return this;
  }

  Either<T, Object> either() {
    try {
      final value = _data.success;
      if (value is T) return Either.left(value);
      return Either.right(_data.failure!);
    } catch (error) {
      return Either.right(error);
    }
  }

  Option<T> asOption() => Option.run(getOrNull);

  Future<T> asFuture() async => getOrThrow();

  Task<T> asTask() => Task(() async => getOrThrow());

  //
  // Side Effects
  //

  @throws
  Result<T> onSuccess(ValueCallable<T> call) {
    if (isSuccess) call(getOrThrow());
    return this;
  }

  @throws
  Result<T> onFailure(ValueCallable<Object> call) {
    if (isFailure) call(_data.failure!);
    return this;
  }
}
