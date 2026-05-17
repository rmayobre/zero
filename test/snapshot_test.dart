import 'dart:async';
import 'package:test/test.dart';
import 'package:zero/zero.dart';

void main() {
  group('Snapshot', () {
    group('constructor', () {
      test('holds initial value', () {
        expect(Snapshot(42).value, 42);
      });

      test('accepts a source stream and updates value when it emits', () async {
        final controller = StreamController<int>.broadcast();
        final s = Snapshot(0, controller.stream);
        expect(s.value, 0);
        controller.add(5);
        await Future.delayed(Duration.zero);
        expect(s.value, 5);
        await controller.close();
      });

      test('closes internal stream when source closes', () async {
        final controller = StreamController<int>();
        final s = Snapshot(0, controller.stream);
        final emitted = <int>[];
        s.collect().listen(emitted.add);
        controller.add(1);
        await controller.close();
        await Future.delayed(Duration.zero);
        expect(emitted, [1]);
      });
    });

    group('value setter', () {
      test('updates the current value', () {
        final s = Snapshot(1);
        s.value = 2;
        expect(s.value, 2);
      });

      test('broadcasts new value to listeners', () async {
        final s = Snapshot(0);
        final emitted = <int>[];
        s.collect().listen(emitted.add);
        s.value = 7;
        await Future.delayed(Duration.zero);
        expect(emitted, [7]);
      });

      test('deduplicates consecutive equal values', () async {
        final s = Snapshot(1);
        final emitted = <int>[];
        s.collect().listen(emitted.add);
        s.value = 1;
        s.value = 2;
        s.value = 2;
        s.value = 3;
        await Future.delayed(Duration.zero);
        expect(emitted, [2, 3]);
      });
    });

    group('map', () {
      test('transforms the initial value', () {
        final mapped = Snapshot(5).map((x) => x * 2);
        expect(mapped.value, 10);
      });

      test('streams transformed values when source updates', () async {
        final s = Snapshot(1);
        final mapped = s.map((x) => x * 10);
        final emitted = <int>[];
        mapped.collect().listen(emitted.add);
        s.value = 3;
        await Future.delayed(Duration.zero);
        expect(emitted, [30]);
      });
    });

    group('flatMap', () {
      test('uses the provided initial value', () {
        final s = Snapshot(1);
        final flat = s.flatMap((_) => Flow.fromIterable([10, 20]), 0);
        expect(flat.value, 0);
      });

      test('expands each update into a flow', () async {
        final s = Snapshot(1);
        final flat = s.flatMap(
          (x) => Flow.fromIterable([x * 10, x * 100]),
          0,
        );
        final emitted = <int>[];
        flat.collect().listen(emitted.add);
        s.value = 2;
        await Future.delayed(const Duration(milliseconds: 10));
        expect(emitted, containsAll([20, 200]));
      });
    });

    group('filter', () {
      test('preserves current value regardless of predicate', () {
        final filtered = Snapshot(3).filter((x) => x.isEven);
        expect(filtered.value, 3);
      });

      test('only forwards values satisfying the predicate', () async {
        final s = Snapshot(0);
        final filtered = s.filter((x) => x.isEven);
        final emitted = <int>[];
        filtered.collect().listen(emitted.add);
        s.value = 1;
        s.value = 2;
        s.value = 3;
        s.value = 4;
        await Future.delayed(Duration.zero);
        expect(emitted, [2, 4]);
      });
    });

    group('onEach', () {
      test('calls side effect for each emitted value', () async {
        final s = Snapshot(0);
        final seen = <int>[];
        final s2 = s.onEach(seen.add);
        s2.collect().listen((_) {});
        s.value = 1;
        s.value = 2;
        await Future.delayed(Duration.zero);
        expect(seen, [1, 2]);
      });
    });

    group('take', () {
      test('limits to the first n emitted events', () async {
        final s = Snapshot(0);
        final taken = s.take(2);
        final emitted = <int>[];
        taken.collect().listen(emitted.add);
        s.value = 1;
        s.value = 2;
        s.value = 3;
        await Future.delayed(Duration.zero);
        expect(emitted, [1, 2]);
      });
    });

    group('drop', () {
      test('skips the first n emitted events', () async {
        final s = Snapshot(0);
        final dropped = s.drop(2);
        final emitted = <int>[];
        dropped.collect().listen(emitted.add);
        s.value = 1;
        s.value = 2;
        s.value = 3;
        await Future.delayed(Duration.zero);
        expect(emitted, [3]);
      });
    });

    group('flow', () {
      test('returns a Flow that emits future updates', () async {
        final s = Snapshot(0);
        final flow = s.flow();
        final emitted = <int>[];
        flow.collect().listen(emitted.add);
        s.value = 1;
        await Future.delayed(Duration.zero);
        expect(emitted, [1]);
      });
    });

    group('collect', () {
      test('returns the underlying broadcast stream', () async {
        final s = Snapshot(0);
        final emitted = <int>[];
        s.collect().listen(emitted.add);
        s.value = 7;
        await Future.delayed(Duration.zero);
        expect(emitted, [7]);
      });
    });

    group('fold', () {
      test('accumulates values until the stream closes', () async {
        final controller = StreamController<int>();
        final s = Snapshot(0, controller.stream);
        final foldFuture = s.fold(0, (acc, x) => acc + x).run();
        controller.add(1);
        controller.add(2);
        controller.add(3);
        await controller.close();
        expect(await foldFuture, 6);
      });
    });

    group('forEach', () {
      test('calls process for each emitted value', () async {
        final s = Snapshot(0);
        final seen = <int>[];
        s.forEach(seen.add);
        s.value = 1;
        s.value = 2;
        await Future.delayed(const Duration(milliseconds: 5));
        expect(seen, containsAll([1, 2]));
      });
    });
  });
}
