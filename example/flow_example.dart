import 'package:zero/zero.dart';

Stream<int> numbersStream() async* {
  for (var i = 1; i <= 10; i++) {
    yield i;
  }
}

void main() async {
  // --- Construction ---
  final fromIterable = Flow.fromIterable([1, 2, 3, 4, 5]);
  final fromStream = Flow.of(numbersStream());

  // --- Collect and iterate ---
  print('fromIterable:');
  await for (final n in fromIterable.collect()) {
    print(n); // 1 2 3 4 5
  }

  // --- Map ---
  final doubled = Flow.fromIterable([1, 2, 3]).map((x) => x * 2);
  print('doubled:');
  await for (final n in doubled.collect()) {
    print(n); // 2 4 6
  }

  // --- Filter ---
  final evens = fromStream.filter((x) => x.isEven);
  print('evens:');
  await for (final n in evens.collect()) {
    print(n); // 2 4 6 8 10
  }

  // --- FlatMap ---
  final expanded = Flow.fromIterable([1, 2, 3])
      .flatMap((x) => Flow.fromIterable([x, x * 10]));
  print('expanded:');
  await for (final n in expanded.collect()) {
    print(n); // 1 10 2 20 3 30
  }

  // --- onEach (side effect) ---
  final logged = Flow.fromIterable(['a', 'b', 'c'])
      .onEach((s) => print('processing: $s'));
  await for (final _ in logged.collect()) {} // processing: a, b, c

  // --- Take / Drop ---
  final first3 = Flow.of(numbersStream()).take(3);
  print('first 3:');
  await for (final n in first3.collect()) {
    print(n); // 1 2 3
  }

  final after3 = Flow.fromIterable([1, 2, 3, 4, 5]).drop(3);
  print('after drop 3:');
  await for (final n in after3.collect()) {
    print(n); // 4 5
  }

  // --- Fold ---
  final sum = await Flow.of(numbersStream())
      .fold<int>(0, (acc, x) => acc + x)
      .run();
  print('sum: $sum'); // 55

  // --- Recover from errors ---
  final errorFlow = Flow<int>(() async* {
    yield 1;
    yield 2;
    throw Exception('something broke');
  }).recover((pair) {
    final (error, _) = pair;
    print('recovered from: $error');
    return -1;
  });

  await for (final n in errorFlow.collect()) {
    print(n); // 1  2  recovered from: ...  -1
  }

  // --- CatchErrors (silently drop errors) ---
  final silenced = Flow<int>(() async* {
    yield 10;
    throw Exception('ignored');
    // ignore: dead_code
    yield 20;
  }).catchErrors();

  print('silenced:');
  await for (final n in silenced.collect()) {
    print(n); // 10
  }

  // --- StreamExtensions: wrap a Stream in a Flow ---
  final streamFlow = numbersStream().flow().take(3);
  print('from stream extension:');
  await for (final n in streamFlow.collect()) {
    print(n); // 1 2 3
  }

  // --- IterableExtensions: wrap an Iterable in a Flow ---
  final iterFlow = [10, 20, 30].flow();
  await for (final n in iterFlow.collect()) {
    print(n); // 10 20 30
  }
}
