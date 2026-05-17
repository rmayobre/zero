import 'package:zero_nads/zero_nads.dart';

// Simulated async data sources
Task<String> fetchUser(int id) => Task(() async {
  await Future.delayed(Duration(milliseconds: 10));
  const users = {1: 'Alice', 2: 'Bob'};
  final user = users[id];
  if (user == null) throw Exception('User $id not found');
  return user;
});

Task<List<String>> fetchPermissions(String username) => Task(() async {
  await Future.delayed(Duration(milliseconds: 10));
  return ['read', 'write'];
});

void main() async {
  // --- Construction ---
  final immediate = Task.of(42);
  print(await immediate.run()); // 42

  // --- Lazy execution (not run until .run() is called) ---
  final task = Task(() async => 'hello');
  print(await task.run()); // hello

  // --- Map ---
  final upper = fetchUser(1).map((name) => name.toUpperCase());
  print(await upper.run()); // ALICE

  // --- FlatMap (chain async operations) ---
  final withPermissions = fetchUser(1)
      .flatMap((name) => fetchPermissions(name)
          .map((perms) => '$name: ${perms.join(', ')}'));
  print(await withPermissions.run()); // Alice: read, write

  // --- Zip (run concurrently) ---
  final zipped = fetchUser(1).zip(fetchUser(2));
  final (alice, bob) = await zipped.run();
  print('$alice and $bob'); // Alice and Bob

  // --- Recover from errors ---
  final safe = fetchUser(99).recover((_) => 'Guest');
  print(await safe.run()); // Guest

  // --- foldAsync (reduce to a single async value) ---
  final result = await fetchUser(1).foldAsync(
    onSuccess: (name) => 'Found: $name',
    onFailure: (err) => 'Error: $err',
  );
  print(result); // Found: Alice

  final errResult = await fetchUser(99).foldAsync(
    onSuccess: (name) => 'Found: $name',
    onFailure: (err) => 'Error: $err',
  );
  print(errResult); // Error: Exception: User 99 not found

  // --- Side effects ---
  await fetchUser(2)
      .onSuccess((name) => print('Loaded: $name'))  // Loaded: Bob
      .onFailure((err) => print('Failed: $err'))
      .run();

  // --- FutureExtensions: wrap a Future in a Task ---
  final futureTask = Future.value('from future').task();
  print(await futureTask.run()); // from future

  // --- IterableTaskExtensions: flatten Task<Iterable> to Stream ---
  final items = Task(() async => ['a', 'b', 'c'] as Iterable<String>);
  await for (final item in items.flatten()) {
    print(item); // a, b, c
  }
}
