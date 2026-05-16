import 'internal/eager.dart';
import 'internal/throws.dart';
import 'internal/typedefs.dart';
import 'option.dart';
import 'preconditions.dart';
import 'result.dart';

typedef _EitherData<L extends Object, R extends Object> = ({L? left, R? right});

@eager
extension type const Either<L extends Object, R extends Object>._(
  _EitherData<L, R> _data
) {
  const Either.left(L value) : this._((left: value, right: null));
  const Either.right(R value) : this._((left: null, right: value));

  bool get isLeft => _data.left != null;
  bool get isRight => _data.right != null;

  //
  // Getters
  //

  @throws
  L get left =>
      checkNotNull(_data.left, () => 'Either<$L, $R> is not $L - $_data');
  @throws
  R get right =>
      checkNotNull(_data.right, () => 'Either<$L, $R> is not $R - $_data');

  L? leftOrNull() => _data.left;
  R? rightOrNull() => _data.right;

  L leftOrDefault(L def) => _data.left ?? def;
  R rightOrDefault(R def) => _data.right ?? def;

  @throws
  L leftOrElse(Calculation<L> compute) => _data.left ?? compute();
  @throws
  R rightOrElse(Calculation<R> compute) => _data.right ?? compute();

  //
  // Transformers
  //

  @throws
  R2 fold<R2>({
    required Transformation<L, R2> left,
    required Transformation<R, R2> right,
  }) {
    if (isLeft) return left(this.left);
    if (isRight) return right(this.right);
    error('Either<$L, $R> is neither - $_data');
  }

  @throws
  Either<L, R2> flatMap<R2 extends Object>(Transformation<R, Either<L, R2>> f) {
    if (isLeft) return Either.left(left);
    if (isRight) return f(right);
    error('Either<$L, $R> is neither - $_data');
  }

  @throws
  Either<L2, R> flatMapLeft<L2 extends Object>(
    Transformation<L, Either<L2, R>> f,
  ) {
    if (isLeft) return f(left);
    if (isRight) return Either.right(right);
    error('Either<$L, $R> is neither - $_data');
  }

  @throws
  Either<L, R2> map<R2 extends Object>(Transformation<R, R2> transform) =>
      mapRight(transform);

  R getOrDefault(R def) => _data.right ?? def;

  @throws
  R getOrElse(Calculation<R> compute) => _data.right ?? compute();

  @throws
  Either<L2, R> mapLeft<L2 extends Object>(Transformation<L, L2> transform) {
    if (isLeft) return Either.left(transform(left));
    if (isRight) return Either.right(right);
    error('Either<$L, $R> is neither - $_data');
  }

  @throws
  Either<L, R2> mapRight<R2 extends Object>(Transformation<R, R2> transform) {
    if (isLeft) return Either.left(left);
    if (isRight) return Either.right(transform(right));
    error('Either<$L, $R> is neither - $_data');
  }

  @throws
  Either<R, L> swap() {
    if (isLeft) return Either.right(left);
    if (isRight) return Either.left(right);
    error('Either<$L, $R> is neither - $_data');
  }

  Result<L> leftResult() => Result.run(() => left);
  Result<R> rightResult() => Result.run(() => right);

  Option<L> leftOption() => Option.run(leftOrNull);
  Option<R> rightOption() => Option.run(rightOrNull);

  //
  // Side Effects
  //

  @throws
  Either<L, R> onLeft(ValueCallable<L> call) {
    if (isLeft) call(left);
    return this;
  }

  @throws
  Either<L, R> onRight(ValueCallable<R> call) {
    if (isRight) call(right);
    return this;
  }
}
