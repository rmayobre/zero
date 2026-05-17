import 'package:test/test.dart';
import 'package:zero/zero.dart';

void main() {
  group('Result', () {
    group('constructors', () {
      test('Result.success creates success', () {
        final r = Result.success(42);
        expect(r.isSuccess, isTrue);
        expect(r.isFailure, isFalse);
      });

      test('Result.failure creates failure', () {
        final r = Result<int>.failure('oops');
        expect(r.isFailure, isTrue);
        expect(r.isSuccess, isFalse);
      });

      test('Result.failure accepts StackTrace', () {
        final st = StackTrace.current;
        final r = Result<int>.failure('err', st);
        expect(r.isFailure, isTrue);
      });

      test('Result.run wraps return value in success', () {
        final r = Result.run(() => 42);
        expect(r.isSuccess, isTrue);
        expect(r.getOrNull(), 42);
      });

      test('Result.run captures exception as failure', () {
        final r = Result<int>.run(() => throw Exception('boom'));
        expect(r.isFailure, isTrue);
      });
    });

    group('getOrDefault', () {
      test('returns success value', () {
        expect(Result.success(5).getOrDefault(0), 5);
      });

      test('returns default on failure', () {
        expect(Result<int>.failure('e').getOrDefault(0), 0);
      });
    });

    group('getOrElse', () {
      test('returns success value', () {
        expect(Result.success(5).getOrElse(() => 0), 5);
      });

      test('calls compute on failure', () {
        expect(Result<int>.failure('e').getOrElse(() => 99), 99);
      });
    });

    group('getOrNull', () {
      test('returns value on success', () {
        expect(Result.success(5).getOrNull(), 5);
      });

      test('returns null on failure', () {
        expect(Result<int>.failure('e').getOrNull(), isNull);
      });
    });

    group('getOrThrow', () {
      test('returns value on success', () {
        expect(Result.success(5).getOrThrow(), 5);
      });

      test('throws captured error on failure', () {
        final err = Exception('boom');
        expect(() => Result<int>.failure(err).getOrThrow(), throwsA(err));
      });

      test('rethrows with original stack trace when available', () {
        final st = StackTrace.current;
        final r = Result<int>.failure(Exception('err'), st);
        expect(() => r.getOrThrow(), throwsException);
      });
    });

    group('fold', () {
      test('calls onSuccess when success', () {
        final result = Result.success(5).fold(
          onSuccess: (v) => v * 2,
          onFailure: (_) => 0,
        );
        expect(result, 10);
      });

      test('calls onFailure when failure', () {
        final result = Result<int>.failure('err').fold(
          onSuccess: (v) => v * 2,
          onFailure: (_) => 42,
        );
        expect(result, 42);
      });
    });

    group('map', () {
      test('transforms success value', () {
        final r = Result.success(2).map((x) => x * 3);
        expect(r.getOrNull(), 6);
      });

      test('propagates failure unchanged', () {
        final r = Result<int>.failure('err').map((x) => x * 3);
        expect(r.isFailure, isTrue);
      });

      test('captures exception thrown by transform', () {
        final r = Result.success(1).map<int>((_) => throw Exception('boom'));
        expect(r.isFailure, isTrue);
      });
    });

    group('flatMap', () {
      test('chains success to success', () {
        final r = Result.success(2).flatMap((x) => Result.success(x * 3));
        expect(r.getOrNull(), 6);
      });

      test('propagates failure unchanged', () {
        final r = Result<int>.failure('err').flatMap((x) => Result.success(x));
        expect(r.isFailure, isTrue);
      });

      test('captures exception thrown by f', () {
        final r = Result.success(1).flatMap<int>((_) => throw Exception('boom'));
        expect(r.isFailure, isTrue);
      });
    });

    group('recoverWith', () {
      test('recovers failure with new Result', () {
        final r = Result<int>.failure('err').recoverWith((_) => Result.success(99));
        expect(r.getOrNull(), 99);
      });

      test('leaves success unchanged', () {
        final r = Result.success(5).recoverWith((_) => Result.success(99));
        expect(r.getOrNull(), 5);
      });

      test('captures exception thrown by f', () {
        final r = Result<int>.failure('err')
            .recoverWith((_) => throw Exception('x'));
        expect(r.isFailure, isTrue);
      });
    });

    group('mapFailure', () {
      test('transforms the failure error object', () {
        final r = Result<int>.failure(Exception('original'))
            .mapFailure((_) => Exception('transformed'));
        expect(r.isFailure, isTrue);
        expect(
          () => r.getOrThrow(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('transformed'),
          )),
        );
      });

      test('leaves success unchanged', () {
        final r = Result.success(5).mapFailure((_) => 'mapped');
        expect(r.getOrNull(), 5);
      });

      test('captures exception thrown by transform', () {
        final r = Result<int>.failure('err')
            .mapFailure((_) => throw Exception('x'));
        expect(r.isFailure, isTrue);
      });
    });

    group('recover', () {
      test('converts failure to success', () {
        final r = Result<int>.failure('err').recover((_) => 42);
        expect(r.getOrNull(), 42);
      });

      test('leaves success unchanged', () {
        final r = Result.success(5).recover((_) => 0);
        expect(r.getOrNull(), 5);
      });

      test('captures exception thrown by transform', () {
        final r = Result<int>.failure('err').recover((_) => throw Exception('x'));
        expect(r.isFailure, isTrue);
      });
    });

    group('either', () {
      test('success maps to left', () {
        final e = Result.success(5).either();
        expect(e.isLeft, isTrue);
        expect(e.left, 5);
      });

      test('failure maps to right', () {
        final e = Result<int>.failure('err').either();
        expect(e.isRight, isTrue);
      });
    });

    group('asOption', () {
      test('success becomes Some', () {
        final o = Result.success(5).asOption();
        expect(o.isSome, isTrue);
        expect(o.getOrNull(), 5);
      });

      test('failure becomes None', () {
        final o = Result<int>.failure('err').asOption();
        expect(o.isNone, isTrue);
      });
    });

    group('asFuture', () {
      test('success completes with value', () async {
        final v = await Result.success(5).asFuture();
        expect(v, 5);
      });

      test('failure completes with error', () async {
        await expectLater(
          Result<int>.failure(Exception('oops')).asFuture(),
          throwsException,
        );
      });
    });

    group('asTask', () {
      test('success runs to value', () async {
        final v = await Result.success(5).asTask().run();
        expect(v, 5);
      });

      test('failure runs to error', () async {
        await expectLater(
          Result<int>.failure(Exception('oops')).asTask().run(),
          throwsException,
        );
      });
    });

    group('onSuccess', () {
      test('calls side effect when success and returns self', () {
        int? captured;
        final r = Result.success(5).onSuccess((v) => captured = v);
        expect(captured, 5);
        expect(r.getOrNull(), 5);
      });

      test('does not call side effect when failure', () {
        int? captured;
        Result<int>.failure('err').onSuccess((v) => captured = v);
        expect(captured, isNull);
      });
    });

    group('onFailure', () {
      test('calls side effect when failure and returns self', () {
        Object? captured;
        final r = Result<int>.failure('err').onFailure((e) => captured = e);
        expect(captured, 'err');
        expect(r.isFailure, isTrue);
      });

      test('does not call side effect when success', () {
        Object? captured;
        Result.success(5).onFailure((e) => captured = e);
        expect(captured, isNull);
      });
    });
  });
}
