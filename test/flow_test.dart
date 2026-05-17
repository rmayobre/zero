import 'dart:async';
import 'package:test/test.dart';
import 'package:zero_nads/zero_nads.dart';

void main() {
  group('Flow', () {
    group('constructors', () {
      test('Flow wraps a stream factory (lazy)', () async {
        bool created = false;
        final flow = Flow(() {
          created = true;
          return Stream.fromIterable([1, 2, 3]);
        });
        expect(created, isFalse);
        expect(await flow.collect().toList(), [1, 2, 3]);
        expect(created, isTrue);
      });

      test('Flow.of wraps an existing stream', () async {
        final stream = Stream.fromIterable([1, 2, 3]);
        final flow = Flow.of(stream);
        expect(await flow.collect().toList(), [1, 2, 3]);
      });

      test('Flow.fromIterable emits iterable elements', () async {
        final flow = Flow.fromIterable([10, 20, 30]);
        expect(await flow.collect().toList(), [10, 20, 30]);
      });
    });

    group('map', () {
      test('transforms each element', () async {
        final flow = Flow.fromIterable([1, 2, 3]).map((x) => x * 2);
        expect(await flow.collect().toList(), [2, 4, 6]);
      });
    });

    group('flatMap', () {
      test('expands each element into a flow and flattens', () async {
        final flow = Flow.fromIterable([1, 2]).flatMap(
          (x) => Flow.fromIterable([x, x * 10]),
        );
        expect(await flow.collect().toList(), [1, 10, 2, 20]);
      });
    });

    group('filter', () {
      test('keeps only elements matching the predicate', () async {
        final flow = Flow.fromIterable([1, 2, 3, 4]).filter((x) => x.isEven);
        expect(await flow.collect().toList(), [2, 4]);
      });
    });

    group('onEach', () {
      test('calls side effect for each element and forwards unchanged', () async {
        final seen = <int>[];
        final result = await Flow.fromIterable([1, 2, 3])
            .onEach(seen.add)
            .collect()
            .toList();
        expect(seen, [1, 2, 3]);
        expect(result, [1, 2, 3]);
      });
    });

    group('recover', () {
      test('injects the recovery value as a stream element', () async {
        final flow = Flow<int>(
          () => Stream.fromFuture(Future.error('err')),
        ).recover((_) => -1);
        expect(await flow.collect().toList(), [-1]);
      });

      test('data events and recovery value all appear in order', () async {
        final controller = StreamController<int>();
        final flow = Flow.of(controller.stream).recover((_) => -1);
        final result = <int>[];
        flow.collect().listen(result.add);
        controller.add(10);
        controller.add(20);
        controller.addError('oops');
        await controller.close();
        await Future.delayed(Duration.zero);
        expect(result, [10, 20, -1]);
      });

      test('forwards a new error when attempt itself throws', () async {
        final flow = Flow<int>(
          () => Stream.fromFuture(Future.error('original')),
        ).recover((_) => throw Exception('from attempt'));
        await expectLater(flow.collect().toList(), throwsException);
      });
    });

    group('catchErrors', () {
      test('suppresses errors without emitting a recovery value', () async {
        final flow = Flow<int>(
          () => Stream.fromFuture(Future.error('err')),
        ).catchErrors();
        expect(await flow.collect().toList(), isEmpty);
      });

      test('data events before an error pass through unchanged', () async {
        final controller = StreamController<int>();
        final flow = Flow.of(controller.stream).catchErrors();
        final result = <int>[];
        flow.collect().listen(result.add);
        controller.add(1);
        controller.add(2);
        controller.addError('oops');
        await controller.close();
        await Future.delayed(Duration.zero);
        expect(result, [1, 2]);
      });

      test('multiple errors are all suppressed', () async {
        final controller = StreamController<int>();
        final flow = Flow.of(controller.stream).catchErrors();
        final result = <int>[];
        flow.collect().listen(result.add);
        controller.add(1);
        controller.addError('first');
        controller.add(2);
        controller.addError('second');
        controller.add(3);
        await controller.close();
        await Future.delayed(Duration.zero);
        expect(result, [1, 2, 3]);
      });
    });

    group('take', () {
      test('emits at most the first n elements', () async {
        final flow = Flow.fromIterable([1, 2, 3, 4, 5]).take(3);
        expect(await flow.collect().toList(), [1, 2, 3]);
      });
    });

    group('drop', () {
      test('skips the first n elements', () async {
        final flow = Flow.fromIterable([1, 2, 3, 4, 5]).drop(2);
        expect(await flow.collect().toList(), [3, 4, 5]);
      });
    });

    group('fold', () {
      test('reduces all elements to a single value', () async {
        final task = Flow.fromIterable([1, 2, 3, 4]).fold(0, (acc, x) => acc + x);
        expect(await task.run(), 10);
      });

      test('returns initial value for empty flow', () async {
        final task = Flow<int>.fromIterable([]).fold(99, (acc, x) => acc + x);
        expect(await task.run(), 99);
      });
    });

    group('collect', () {
      test('subscribes and returns the native stream', () async {
        final flow = Flow.fromIterable([1, 2]);
        expect(await flow.collect().toList(), [1, 2]);
      });
    });

    group('forEach', () {
      test('calls process for each element', () async {
        final seen = <int>[];
        Flow.fromIterable([1, 2, 3]).forEach(seen.add);
        await Future.delayed(const Duration(milliseconds: 10));
        expect(seen, [1, 2, 3]);
      });
    });

    group('NonNullFlowExtensions.toSnapshot', () {
      test('creates a Snapshot with the given initial value', () {
        final snapshot = Flow.fromIterable([1, 2, 3]).snapshot(0);
        expect(snapshot.value, 0);
      });

      test('snapshot receives values emitted by the flow', () async {
        final snapshot = Flow.fromIterable([1, 2, 3]).snapshot(0);
        await Future.delayed(const Duration(milliseconds: 10));
        expect(snapshot.value, 3);
      });
    });
  });
}
