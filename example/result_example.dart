import 'package:zero/zero.dart';

Result<int> parseAge(String raw) => Result.run(() {
  final n = int.parse(raw);
  require(n >= 0 && n <= 150, () => 'Age out of range: $n');
  return n;
});

Result<String> lookupUser(int id) {
  const db = {1: 'Alice', 2: 'Bob'};
  return db.containsKey(id)
      ? Result.success(db[id]!)
      : Result.failure('User $id not found');
}

void main() {
  // --- Construction ---
  final success = Result.success(42);
  final failure = Result<int>.failure('something went wrong');

  print(success.isSuccess); // true
  print(failure.isFailure); // true

  // --- Result.run captures exceptions ---
  final parsed = Result.run(() => int.parse('123'));
  final badParse = Result<int>.run(() => int.parse('abc'));
  print(parsed.getOrNull()); // 123
  print(badParse.isFailure); // true

  // --- Custom logic with run ---
  print(parseAge('25').getOrNull()); // 25
  print(parseAge('-5').isFailure); // true
  print(parseAge('abc').isFailure); // true

  // --- Retrieval ---
  print(success.getOrDefault(0)); // 42
  print(failure.getOrDefault(0)); // 0
  print(success.getOrElse(() => -1)); // 42
  print(failure.getOrNull()); // null

  // --- Map ---
  final doubled = Result.success(5).map((x) => x * 2);
  print(doubled.getOrNull()); // 10

  final propagated = Result<int>.failure('err').map((x) => x * 2);
  print(propagated.isFailure); // true

  // --- FlatMap (chain operations) ---
  final chained = lookupUser(1).flatMap((name) =>
      Result.success('Hello, $name!'));
  print(chained.getOrNull()); // Hello, Alice!

  final chainedFailure = lookupUser(99).flatMap((name) =>
      Result.success('Hello, $name!'));
  print(chainedFailure.isFailure); // true

  // --- Fold ---
  final message = lookupUser(2).fold(
    onSuccess: (name) => 'Found: $name',
    onFailure: (err) => 'Error: $err',
  );
  print(message); // Found: Bob

  // --- Recover ---
  final recovered = lookupUser(99).recover((_) => 'Guest');
  print(recovered.getOrNull()); // Guest

  final recoveredWith = lookupUser(99).recoverWith((_) => Result.success('Guest'));
  print(recoveredWith.getOrNull()); // Guest

  // --- MapFailure ---
  final remapped = lookupUser(99).mapFailure((_) => Exception('not found'));
  print(remapped.isFailure); // true

  // --- Side Effects ---
  lookupUser(1)
      .onSuccess((name) => print('Success: $name'))  // Success: Alice
      .onFailure((err) => print('Failed: $err'));

  // --- Convert to other types ---
  final opt = lookupUser(1).asOption();
  print(opt.isSome); // true

  final either = lookupUser(1).either();
  print(either.isLeft); // true (success → left by convention)
}
