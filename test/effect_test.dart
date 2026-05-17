import 'package:test/test.dart';
import 'package:zero_nads/zero_nads.dart';

void main() {
  group('Effect', () {
    group('run', () {
      test('executes the computation and returns its value', () {
        final effect = Effect(() => 42);
        expect(effect.run(), 42);
      });

      test('is lazy — does not execute until run() is called', () {
        bool executed = false;
        final effect = Effect(() {
          executed = true;
          return 1;
        });
        expect(executed, isFalse);
        effect.run();
        expect(executed, isTrue);
      });

      test('propagates exceptions thrown by the computation', () {
        final effect = Effect<int>(() => throw Exception('boom'));
        expect(() => effect.run(), throwsException);
      });
    });

    group('map', () {
      test('transforms the result', () {
        final effect = Effect(() => 5).map((x) => x * 2);
        expect(effect.run(), 10);
      });

      test('map is lazy', () {
        bool executed = false;
        final effect = Effect(() => 3).map((x) {
          executed = true;
          return x * 2;
        });
        expect(executed, isFalse);
        effect.run();
        expect(executed, isTrue);
      });
    });

    group('flatMap', () {
      test('chains effects', () {
        final effect = Effect(() => 3).flatMap((x) => Effect(() => x * 4));
        expect(effect.run(), 12);
      });

      test('flatMap is lazy', () {
        bool executed = false;
        final effect = Effect(() => 2).flatMap((x) => Effect(() {
              executed = true;
              return x + 1;
            }));
        expect(executed, isFalse);
        effect.run();
        expect(executed, isTrue);
      });
    });

    group('onEach', () {
      test('calls side effect and returns the original value', () {
        int? captured;
        final effect = Effect(() => 7).onEach((v) => captured = v);
        final result = effect.run();
        expect(result, 7);
        expect(captured, 7);
      });

      test('onEach is lazy', () {
        bool called = false;
        final effect = Effect(() => 1).onEach((_) => called = true);
        expect(called, isFalse);
        effect.run();
        expect(called, isTrue);
      });
    });
  });
}
