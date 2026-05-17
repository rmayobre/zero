import 'package:zero/zero.dart';

void main() async {
  // --- Construction ---
  final counter = Snapshot(0);
  print(counter.value); // 0

  // --- Update value (broadcasts to listeners) ---
  counter.value = 1;
  print(counter.value); // 1

  // Duplicate values are suppressed — no broadcast, no update
  counter.value = 1;

  // --- Listen to changes ---
  final subscription = counter.collect().listen((n) {
    print('counter changed: $n');
  });

  counter.value = 2; // counter changed: 2
  counter.value = 3; // counter changed: 3

  await Future.delayed(Duration.zero);

  // --- Map (derived snapshot) ---
  final doubled = counter.map((x) => x * 2);
  print('doubled initial: ${doubled.value}'); // 6

  final doubledSub = doubled.collect().listen((n) {
    print('doubled changed: $n');
  });

  counter.value = 4; // counter changed: 4  /  doubled changed: 8
  await Future.delayed(Duration.zero);

  // --- Filter ---
  final evens = Snapshot(0);
  final evenOnly = evens.filter((x) => x.isEven);

  final evenSub = evenOnly.collect().listen((n) => print('even: $n'));

  evens.value = 2; // even: 2
  evens.value = 3; // filtered — no broadcast
  evens.value = 4; // even: 4
  await Future.delayed(Duration.zero);

  // --- onEach (side effect on each emitted value) ---
  final logged = Snapshot(0).onEach((x) => print('observed: $x'));
  logged.collect().listen((_) {});

  // --- Take / Drop ---
  final snap = Snapshot(0);
  final firstTwo = snap.take(2);
  final afterTwo = snap.drop(2);

  final taken = <int>[];
  firstTwo.collect().listen((n) => taken.add(n));
  afterTwo.collect().listen((n) => print('after drop: $n'));

  snap.value = 1;
  snap.value = 2;
  snap.value = 3; // only 'after drop: 3' — take(2) is done
  await Future.delayed(Duration.zero);
  print('taken: $taken'); // [1, 2]

  // --- Snapshot seeded from an external Stream ---
  final source = Stream.fromIterable([10, 20, 30]);
  final streamed = Snapshot(0, source);
  await Future.delayed(Duration.zero);
  print('last from stream: ${streamed.value}'); // 30

  // --- Flow interop ---
  final stateSnap = Snapshot('idle');
  final stateFlow = stateSnap.flow();

  final states = <String>[];
  stateFlow.collect().listen((s) => states.add(s));

  stateSnap.value = 'loading';
  stateSnap.value = 'success';
  await Future.delayed(Duration.zero);
  print('states: $states'); // [loading, success]

  await subscription.cancel();
  await doubledSub.cancel();
  await evenSub.cancel();
}
