import 'package:test/test.dart';
import 'package:zero_nads/zero_nads.dart';

void main() {
  group('Option', () {
    group('constructors', () {
      test('Option(value) creates Some', () {
        final opt = Option(42);
        expect(opt.isSome, isTrue);
        expect(opt.isNone, isFalse);
      });

      test('Option(null) creates None', () {
        final opt = Option<int>(null);
        expect(opt.isSome, isFalse);
        expect(opt.isNone, isTrue);
      });

      test('Option.nothing() creates None', () {
        final opt = Option<int>.nothing();
        expect(opt.isNone, isTrue);
        expect(opt.getOrNull(), isNull);
      });

      test('Option.run() with non-null result creates Some', () {
        final opt = Option.run(() => 42);
        expect(opt.isSome, isTrue);
        expect(opt.getOrNull(), 42);
      });

      test('Option.run() with null result creates None', () {
        final opt = Option<int>.run(() => null);
        expect(opt.isNone, isTrue);
      });

      test('Option.run() propagates exceptions', () {
        expect(() => Option<int>.run(() => throw Exception('boom')), throwsException);
      });
    });

    group('getOrDefault', () {
      test('returns contained value when Some', () {
        expect(Option(42).getOrDefault(0), 42);
      });

      test('returns default when None', () {
        expect(Option<int>(null).getOrDefault(0), 0);
      });
    });

    group('getOrElse', () {
      test('returns contained value when Some', () {
        expect(Option(42).getOrElse(() => 0), 42);
      });

      test('calls compute and returns result when None', () {
        expect(Option<int>(null).getOrElse(() => 99), 99);
      });
    });

    group('getOrThrow', () {
      test('returns contained value when Some', () {
        expect(Option(42).getOrThrow(), 42);
      });

      test('throws StateError when None', () {
        expect(() => Option<int>(null).getOrThrow(), throwsStateError);
      });
    });

    group('getOrNull', () {
      test('returns value when Some', () {
        expect(Option(42).getOrNull(), 42);
      });

      test('returns null when None', () {
        expect(Option<int>(null).getOrNull(), isNull);
      });
    });

    group('map', () {
      test('transforms contained value when Some', () {
        final result = Option(2).map((x) => x * 3);
        expect(result.getOrNull(), 6);
      });

      test('returns None when None', () {
        final result = Option<int>(null).map((x) => x * 3);
        expect(result.isNone, isTrue);
      });
    });

    group('flatMap', () {
      test('chains Some to Some', () {
        final result = Option(2).flatMap((x) => Option(x * 3));
        expect(result.getOrNull(), 6);
      });

      test('chains Some to None', () {
        final result = Option(2).flatMap((_) => Option<int>(null));
        expect(result.isNone, isTrue);
      });

      test('returns None when None', () {
        final result = Option<int>(null).flatMap((x) => Option(x * 3));
        expect(result.isNone, isTrue);
      });
    });

    group('orElse', () {
      test('returns self when Some', () {
        expect(Option(1).orElse(Option(2)).getOrNull(), 1);
      });

      test('returns other when None', () {
        expect(Option<int>(null).orElse(Option(2)).getOrNull(), 2);
      });
    });

    group('filter', () {
      test('keeps value when predicate is true', () {
        expect(Option(4).filter((x) => x.isEven).isSome, isTrue);
      });

      test('becomes None when predicate is false', () {
        expect(Option(3).filter((x) => x.isEven).isNone, isTrue);
      });

      test('stays None when None regardless of predicate', () {
        expect(Option<int>(null).filter((_) => true).isNone, isTrue);
      });
    });

    group('tap', () {
      test('calls side effect when Some and returns self', () {
        int captured = 0;
        final result = Option(5).tap((x) => captured = x);
        expect(captured, 5);
        expect(result.getOrNull(), 5);
      });

      test('does not call side effect when None', () {
        int captured = 0;
        final result = Option<int>(null).tap((x) => captured = x);
        expect(captured, 0);
        expect(result.isNone, isTrue);
      });
    });

    group('zip', () {
      test('returns tuple when both are Some', () {
        final result = Option(1).zip(Option('a'));
        expect(result.getOrNull(), (1, 'a'));
      });

      test('returns None when first is None', () {
        final result = Option<int>(null).zip(Option('a'));
        expect(result.isNone, isTrue);
      });

      test('returns None when second is None', () {
        final result = Option(1).zip(Option<String>(null));
        expect(result.isNone, isTrue);
      });
    });

    group('toList', () {
      test('returns single-element list when Some', () {
        expect(Option(42).toList(), [42]);
      });

      test('returns empty list when None', () {
        expect(Option<int>(null).toList(), isEmpty);
      });
    });

    group('fold', () {
      test('calls onSome with value when Some', () {
        final result = Option(5).fold(() => 0, (x) => x * 2);
        expect(result, 10);
      });

      test('calls onNone when None', () {
        final result = Option<int>(null).fold(() => -1, (x) => x * 2);
        expect(result, -1);
      });
    });
  });
}
