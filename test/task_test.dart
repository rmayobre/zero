import 'package:test/test.dart';
import 'package:zero_nads/zero_nads.dart';

void main() {
  group('Task', () {
    group('constructors', () {
      test('Task wraps a deferred async computation', () async {
        bool executed = false;
        final task = Task(() async {
          executed = true;
          return 42;
        });
        expect(executed, isFalse);
        expect(await task.run(), 42);
        expect(executed, isTrue);
      });

      test('Task.of completes immediately with value', () async {
        expect(await Task.of(42).run(), 42);
      });
    });

    group('run', () {
      test('executes the computation', () async {
        expect(await Task(() async => 7).run(), 7);
      });

      test('converts synchronous throw into a failed Future', () async {
        final task = Task<int>(() => throw Exception('boom'));
        await expectLater(task.run(), throwsException);
      });
    });

    group('map', () {
      test('transforms the resolved value', () async {
        expect(await Task.of(2).map((x) => x * 3).run(), 6);
      });
    });

    group('flatMap', () {
      test('chains tasks sequentially', () async {
        final task = Task.of(2).flatMap((x) => Task.of(x * 3));
        expect(await task.run(), 6);
      });
    });

    group('foldAsync', () {
      test('calls onSuccess when resolved', () async {
        final r = await Task.of(5).foldAsync(
          onSuccess: (v) => 'ok:$v',
          onFailure: (_) => 'err',
        );
        expect(r, 'ok:5');
      });

      test('calls onFailure when task fails', () async {
        final task = Task<int>(() async => throw Exception('boom'));
        final r = await task.foldAsync(
          onSuccess: (_) => 'ok',
          onFailure: (_) => 'err',
        );
        expect(r, 'err');
      });
    });

    group('recover', () {
      test('recovers from error with a value', () async {
        final task = Task<int>(() async => throw Exception('boom'))
            .recover((_) => 99);
        expect(await task.run(), 99);
      });

      test('leaves successful result unchanged', () async {
        expect(await Task.of(5).recover((_) => 0).run(), 5);
      });
    });

    group('onSuccess', () {
      test('calls side effect with resolved value', () async {
        int? captured;
        await Task.of(5).onSuccess((v) => captured = v).run();
        expect(captured, 5);
      });

      test('forwards the value after the side effect', () async {
        expect(await Task.of(5).onSuccess((_) {}).run(), 5);
      });
    });

    group('onFailure', () {
      test('calls side effect with error', () async {
        Object? captured;
        final task = Task<int>(() async => throw Exception('boom'))
            .onFailure((e) => captured = e);
        await expectLater(task.run(), throwsException);
        expect(captured, isNotNull);
      });

      test('rethrows the error after the side effect', () async {
        final task = Task<int>(() async => throw Exception('boom'))
            .onFailure((_) {});
        await expectLater(task.run(), throwsException);
      });
    });

    group('zip', () {
      test('combines two successful tasks into a tuple', () async {
        final task = Task.of(1).zip(Task.of('a'));
        expect(await task.run(), (1, 'a'));
      });
    });

    group('IterableTaskExtensions.flatten', () {
      test('emits each element of the iterable as a stream', () async {
        final task = Task<Iterable<int>>.of([1, 2, 3]);
        expect(await task.flatten().toList(), [1, 2, 3]);
      });

      test('emits nothing for an empty iterable', () async {
        final task = Task<Iterable<int>>.of([]);
        expect(await task.flatten().toList(), isEmpty);
      });
    });
  });
}
