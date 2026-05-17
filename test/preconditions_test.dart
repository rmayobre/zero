import 'package:test/test.dart';
import 'package:zero/zero.dart';

void main() {
  group('preconditions', () {
    group('check', () {
      test('does not throw when condition is true', () {
        expect(() => check(true), returnsNormally);
      });

      test('throws StateError when condition is false', () {
        expect(() => check(false), throwsStateError);
      });

      test('uses custom message builder in thrown error', () {
        expect(
          () => check(false, () => 'custom message'),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('custom message'),
          )),
        );
      });
    });

    group('checkNotNull', () {
      test('returns value when non-null', () {
        expect(checkNotNull(42), 42);
      });

      test('throws StateError when null', () {
        expect(() => checkNotNull<int>(null), throwsStateError);
      });

      test('uses custom message builder in thrown error', () {
        expect(
          () => checkNotNull<int>(null, () => 'was null'),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('was null'),
          )),
        );
      });
    });

    group('checkTypeOf', () {
      test('returns value when it is the correct type', () {
        expect(checkTypeOf<int>(42), 42);
      });

      test('throws StateError when value is wrong type', () {
        expect(() => checkTypeOf<int>('hello'), throwsStateError);
      });

      test('uses custom message builder in thrown error', () {
        expect(
          () => checkTypeOf<int>('hi', () => 'bad type'),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('bad type'),
          )),
        );
      });
    });

    group('error', () {
      test('always throws StateError', () {
        expect(() => error('bad state'), throwsStateError);
      });

      test('includes the provided message', () {
        expect(
          () => error('my message'),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('my message'),
          )),
        );
      });
    });

    group('require', () {
      test('does not throw when condition is true', () {
        expect(() => require(true), returnsNormally);
      });

      test('throws ArgumentError when condition is false', () {
        expect(() => require(false), throwsArgumentError);
      });

      test('uses custom message builder in thrown error', () {
        expect(
          () => require(false, () => 'bad input'),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('bad input'),
          )),
        );
      });
    });

    group('requireNotNull', () {
      test('returns value when non-null', () {
        expect(requireNotNull(42), 42);
      });

      test('throws ArgumentError when null', () {
        expect(() => requireNotNull<int>(null), throwsArgumentError);
      });

      test('accepts a custom message builder', () {
        expect(
          () => requireNotNull<int>(null, () => 'param_name'),
          throwsArgumentError,
        );
      });
    });

    group('requireTypeOf', () {
      test('returns value when it is the correct type', () {
        expect(requireTypeOf<int>(42), 42);
      });

      test('throws ArgumentError when value is wrong type', () {
        expect(() => requireTypeOf<int>('hello'), throwsArgumentError);
      });

      test('uses custom message builder in thrown error', () {
        expect(
          () => requireTypeOf<int>('hi', () => 'wrong type'),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('wrong type'),
          )),
        );
      });
    });

    group('TODO', () {
      test('throws UnimplementedError', () {
        expect(() => TODO(), throwsUnimplementedError);
      });

      test('includes custom message when provided', () {
        expect(
          () => TODO('not yet done'),
          throwsA(isA<UnimplementedError>().having(
            (e) => e.message,
            'message',
            contains('not yet done'),
          )),
        );
      });
    });
  });
}
