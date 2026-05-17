import 'package:test/test.dart';
import 'package:zero_nads/zero_nads.dart';

void main() {
  group('Either', () {
    group('constructors', () {
      test('Either.left creates a left', () {
        final e = Either<String, int>.left('error');
        expect(e.isLeft, isTrue);
        expect(e.isRight, isFalse);
      });

      test('Either.right creates a right', () {
        final e = Either<String, int>.right(42);
        expect(e.isRight, isTrue);
        expect(e.isLeft, isFalse);
      });
    });

    group('left getter', () {
      test('returns left value when left', () {
        expect(Either<String, int>.left('error').left, 'error');
      });

      test('throws StateError when right', () {
        expect(() => Either<String, int>.right(42).left, throwsStateError);
      });
    });

    group('right getter', () {
      test('returns right value when right', () {
        expect(Either<String, int>.right(42).right, 42);
      });

      test('throws StateError when left', () {
        expect(() => Either<String, int>.left('error').right, throwsStateError);
      });
    });

    group('leftOrNull / rightOrNull', () {
      test('leftOrNull returns value when left', () {
        expect(Either<String, int>.left('x').leftOrNull(), 'x');
      });

      test('leftOrNull returns null when right', () {
        expect(Either<String, int>.right(1).leftOrNull(), isNull);
      });

      test('rightOrNull returns value when right', () {
        expect(Either<String, int>.right(1).rightOrNull(), 1);
      });

      test('rightOrNull returns null when left', () {
        expect(Either<String, int>.left('x').rightOrNull(), isNull);
      });
    });

    group('leftOrDefault / rightOrDefault', () {
      test('leftOrDefault returns value when left', () {
        expect(Either<String, int>.left('x').leftOrDefault('def'), 'x');
      });

      test('leftOrDefault returns default when right', () {
        expect(Either<String, int>.right(1).leftOrDefault('def'), 'def');
      });

      test('rightOrDefault returns value when right', () {
        expect(Either<String, int>.right(1).rightOrDefault(0), 1);
      });

      test('rightOrDefault returns default when left', () {
        expect(Either<String, int>.left('x').rightOrDefault(0), 0);
      });
    });

    group('leftOrElse / rightOrElse', () {
      test('leftOrElse returns value when left', () {
        expect(Either<String, int>.left('x').leftOrElse(() => 'y'), 'x');
      });

      test('leftOrElse calls compute when right', () {
        expect(Either<String, int>.right(1).leftOrElse(() => 'computed'), 'computed');
      });

      test('rightOrElse returns value when right', () {
        expect(Either<String, int>.right(1).rightOrElse(() => 99), 1);
      });

      test('rightOrElse calls compute when left', () {
        expect(Either<String, int>.left('x').rightOrElse(() => 99), 99);
      });
    });

    group('getOrDefault / getOrElse', () {
      test('getOrDefault returns right when right', () {
        expect(Either<String, int>.right(5).getOrDefault(0), 5);
      });

      test('getOrDefault returns default when left', () {
        expect(Either<String, int>.left('x').getOrDefault(0), 0);
      });

      test('getOrElse returns right when right', () {
        expect(Either<String, int>.right(5).getOrElse(() => 0), 5);
      });

      test('getOrElse calls compute when left', () {
        expect(Either<String, int>.left('x').getOrElse(() => 99), 99);
      });
    });

    group('fold', () {
      test('calls left branch when left', () {
        final result = Either<String, int>.left('err').fold(
          left: (l) => 'L:$l',
          right: (r) => 'R:$r',
        );
        expect(result, 'L:err');
      });

      test('calls right branch when right', () {
        final result = Either<String, int>.right(42).fold(
          left: (l) => 'L:$l',
          right: (r) => 'R:$r',
        );
        expect(result, 'R:42');
      });
    });

    group('flatMap', () {
      test('transforms right value', () {
        final result = Either<String, int>.right(2)
            .flatMap((r) => Either.right(r * 3));
        expect(result.right, 6);
      });

      test('propagates left unchanged', () {
        final result = Either<String, int>.left('err')
            .flatMap((r) => Either.right(r * 3));
        expect(result.left, 'err');
      });
    });

    group('flatMapLeft', () {
      test('transforms left value', () {
        final result = Either<String, int>.left('err')
            .flatMapLeft((l) => Either.left('mapped:$l'));
        expect(result.left, 'mapped:err');
      });

      test('propagates right unchanged', () {
        final result = Either<String, int>.right(1)
            .flatMapLeft((l) => Either<int, int>.left(0));
        expect(result.right, 1);
      });
    });

    group('map / mapRight', () {
      test('transforms right value', () {
        final result = Either<String, int>.right(2).map((r) => r * 5);
        expect(result.right, 10);
      });

      test('propagates left unchanged', () {
        final result = Either<String, int>.left('err').map((r) => r * 5);
        expect(result.left, 'err');
      });
    });

    group('mapLeft', () {
      test('transforms left value', () {
        final result = Either<String, int>.left('err')
            .mapLeft((l) => l.toUpperCase());
        expect(result.left, 'ERR');
      });

      test('propagates right unchanged', () {
        final result = Either<String, int>.right(1)
            .mapLeft((l) => l.toUpperCase());
        expect(result.right, 1);
      });
    });

    group('swap', () {
      test('swaps left to right', () {
        final result = Either<String, int>.left('x').swap();
        expect(result.right, 'x');
      });

      test('swaps right to left', () {
        final result = Either<String, int>.right(1).swap();
        expect(result.left, 1);
      });
    });

    group('leftResult / rightResult', () {
      test('leftResult is success when left', () {
        final r = Either<String, int>.left('val').leftResult();
        expect(r.isSuccess, isTrue);
        expect(r.getOrNull(), 'val');
      });

      test('leftResult is failure when right', () {
        final r = Either<String, int>.right(1).leftResult();
        expect(r.isFailure, isTrue);
      });

      test('rightResult is success when right', () {
        final r = Either<String, int>.right(42).rightResult();
        expect(r.isSuccess, isTrue);
        expect(r.getOrNull(), 42);
      });

      test('rightResult is failure when left', () {
        final r = Either<String, int>.left('err').rightResult();
        expect(r.isFailure, isTrue);
      });
    });

    group('leftOption / rightOption', () {
      test('leftOption is Some when left', () {
        final o = Either<String, int>.left('val').leftOption();
        expect(o.isSome, isTrue);
        expect(o.getOrNull(), 'val');
      });

      test('leftOption is None when right', () {
        final o = Either<String, int>.right(1).leftOption();
        expect(o.isNone, isTrue);
      });

      test('rightOption is Some when right', () {
        final o = Either<String, int>.right(42).rightOption();
        expect(o.isSome, isTrue);
        expect(o.getOrNull(), 42);
      });

      test('rightOption is None when left', () {
        final o = Either<String, int>.left('err').rightOption();
        expect(o.isNone, isTrue);
      });
    });

    group('onLeft', () {
      test('calls side effect when left and returns self', () {
        String? captured;
        final e = Either<String, int>.left('x');
        final returned = e.onLeft((l) => captured = l);
        expect(captured, 'x');
        expect(returned.left, 'x');
      });

      test('does not call side effect when right', () {
        String? captured;
        Either<String, int>.right(1).onLeft((l) => captured = l);
        expect(captured, isNull);
      });
    });

    group('onRight', () {
      test('calls side effect when right and returns self', () {
        int? captured;
        final e = Either<String, int>.right(5);
        final returned = e.onRight((r) => captured = r);
        expect(captured, 5);
        expect(returned.right, 5);
      });

      test('does not call side effect when left', () {
        int? captured;
        Either<String, int>.left('x').onRight((r) => captured = r);
        expect(captured, isNull);
      });
    });
  });
}
