import 'package:test/test.dart';
import 'package:zero_nads/zero_nads.dart';

void main() {
  group('StreamExtensions', () {
    group('asFlow', () {
      test('wraps a stream in a lazy Flow', () async {
        final stream = Stream.fromIterable([1, 2, 3]);
        final flow = stream.flow();
        expect(await flow.collect().toList(), [1, 2, 3]);
      });

      test('is lazy — does not subscribe until collect() is called', () async {
        bool subscribed = false;
        final stream = Stream<int>.multi((controller) {
          subscribed = true;
          controller.add(1);
          controller.close();
        });
        final flow = stream.flow();
        expect(subscribed, isFalse);
        await flow.collect().toList();
        expect(subscribed, isTrue);
      });
    });

    group('whereType', () {
      test('filters elements by type', () async {
        final stream = Stream<Object>.fromIterable([1, 'hello', 2, 'world', 3]);
        final result = await stream.whereType<int>().toList();
        expect(result, [1, 2, 3]);
      });

      test('returns empty stream when no elements match', () async {
        final stream = Stream<Object>.fromIterable(['a', 'b', 'c']);
        final result = await stream.whereType<int>().toList();
        expect(result, isEmpty);
      });

      test('returns all elements when all match', () async {
        final stream = Stream<Object>.fromIterable([1, 2, 3]);
        final result = await stream.whereType<int>().toList();
        expect(result, [1, 2, 3]);
      });
    });
  });
}
