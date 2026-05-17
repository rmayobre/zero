import 'internal/eager.dart';
import 'internal/throws.dart';
import 'internal/typedefs.dart';
import 'option.dart';
import 'preconditions.dart';
import 'result.dart';

typedef _EitherData<L extends Object, R extends Object> = ({L? left, R? right});

/// A discriminated union holding either a [Left] value of type [L] or a [Right]
/// value of type [R].
///
/// By convention [Left] represents the secondary (error) case and [Right] the
/// primary (success) case, mirroring [Result]. Neither [L] nor [R] may be
/// nullable — both must extend [Object].
@eager
extension type const Either<L extends Object, R extends Object>._(_EitherData<L, R> _data) {

  /// Creates an [Either] holding a left value.
  const Either.left(L value) : this._((left: value, right: null));

  /// Creates an [Either] holding a right value.
  const Either.right(R value) : this._((left: null, right: value));

  /// Returns `true` if this holds a left value.
  bool get isLeft => _data.left != null;

  /// Returns `true` if this holds a right value.
  bool get isRight => _data.right != null;

  //
  // Getters
  //

  /// Returns the left value, or throws [StateError] if this is a right.
  @throws L get left => checkNotNull(_data.left, () => 'Either<$L, $R> is not $L - $_data');

  /// Returns the right value, or throws [StateError] if this is a left.
  @throws R get right => checkNotNull(_data.right, () => 'Either<$L, $R> is not $R - $_data');

  /// Returns the left value, or `null` if this is a right.
  L? leftOrNull() => _data.left;

  /// Returns the right value, or `null` if this is a left.
  R? rightOrNull() => _data.right;

  /// Returns the left value, or [def] if this is a right.
  L leftOrDefault(L def) => _data.left ?? def;

  /// Returns the right value, or [def] if this is a left.
  R rightOrDefault(R def) => _data.right ?? def;

  /// Returns the left value, or the result of [compute] if this is a right.
  @throws L leftOrElse(Calculation<L> compute) => _data.left ?? compute();

  /// Returns the right value, or the result of [compute] if this is a left.
  @throws R rightOrElse(Calculation<R> compute) => _data.right ?? compute();

  //
  // Transformers
  //

  /// Reduces this [Either] to a single value by applying [left] or [right].
  ///
  /// Exactly one branch is called depending on which side is populated.
  @throws
  R2 fold<R2>({
    required Transformation<L, R2> left,
    required Transformation<R, R2> right
  }) {
    if (isLeft) return left(this.left);
    if (isRight) return right(this.right);
    error('Either<$L, $R> is neither - $_data');
  }

  /// Applies [f] to the right value and returns the resulting [Either].
  ///
  /// Propagates the left value unchanged when this is a left.
  @throws
  Either<L, R2> flatMap<R2 extends Object>(Transformation<R, Either<L, R2>> f) {
    if (isLeft) return Either.left(left);
    if (isRight) return f(right);
    error('Either<$L, $R> is neither - $_data');
  }

  /// Applies [f] to the left value and returns the resulting [Either].
  ///
  /// Propagates the right value unchanged when this is a right.
  @throws
  Either<L2, R> flatMapLeft<L2 extends Object>(Transformation<L, Either<L2, R>> f) {
    if (isLeft) return f(left);
    if (isRight) return Either.right(right);
    error('Either<$L, $R> is neither - $_data');
  }

  /// Transforms the right value using [transform]. Equivalent to [mapRight].
  @throws
  Either<L, R2> map<R2 extends Object>(Transformation<R, R2> transform) =>
      mapRight(transform);

  /// Returns the right value, or [def] if this holds a left.
  R getOrDefault(R def) => _data.right ?? def;

  /// Returns the right value, or the result of [compute] if this holds a left.
  @throws R getOrElse(Calculation<R> compute) => _data.right ?? compute();

  /// Transforms the left value, leaving the right value unchanged.
  @throws
  Either<L2, R> mapLeft<L2 extends Object>(Transformation<L, L2> transform) {
    if (isLeft) return Either.left(transform(left));
    if (isRight) return Either.right(right);
    error('Either<$L, $R> is neither - $_data');
  }

  /// Transforms the right value, leaving the left value unchanged.
  @throws
  Either<L, R2> mapRight<R2 extends Object>(Transformation<R, R2> transform) {
    if (isLeft) return Either.left(left);
    if (isRight) return Either.right(transform(right));
    error('Either<$L, $R> is neither - $_data');
  }

  /// Returns a new [Either] with left and right swapped.
  @throws
  Either<R, L> swap() {
    if (isLeft) return Either.right(left);
    if (isRight) return Either.left(right);
    error('Either<$L, $R> is neither - $_data');
  }

  /// Wraps the left value in a [Result], capturing any [StateError] as a failure.
  Result<L> leftResult() => Result.run(() => left);

  /// Wraps the right value in a [Result], capturing any [StateError] as a failure.
  Result<R> rightResult() => Result.run(() => right);

  /// Returns an [Option] containing the left value, or [Option.nothing] if this is a right.
  Option<L> leftOption() => Option.run(leftOrNull);

  /// Returns an [Option] containing the right value, or [Option.nothing] if this is a left.
  Option<R> rightOption() => Option.run(rightOrNull);

  //
  // Side Effects
  //

  /// Calls [call] with the left value if this is a left, then returns `this`.
  @throws
  Either<L, R> onLeft(ValueCallable<L> call) {
    if (isLeft) call(left);
    return this;
  }

  /// Calls [call] with the right value if this is a right, then returns `this`.
  @throws
  Either<L, R> onRight(ValueCallable<R> call) {
    if (isRight) call(right);
    return this;
  }
}
