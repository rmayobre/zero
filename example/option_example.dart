import 'package:zero/zero.dart';

// Simulated user database
final Map<int, String> _users = {1: 'Alice', 2: 'Bob', 3: 'Carol'};

Option<String> findUser(int id) => Option(_users[id]);

void main() {
  // --- Construction ---
  final some = Option(42);
  final none = Option<int>(null);
  final nothingOpt = Option<String>.nothing();

  print('isSome: ${some.isSome}'); // true
  print('isNone: ${none.isNone}'); // true
  print('isNone: ${nothingOpt.isNone}'); // true

  // --- Retrieval ---
  print(some.getOrDefault(0)); // 42
  print(none.getOrDefault(0)); // 0
  print(some.getOrElse(() => -1)); // 42
  print(none.getOrNull()); // null

  // --- Map / FlatMap ---
  final doubled = Option(5).map((x) => x * 2);
  print('doubled: ${doubled.getOrNull()}'); // 10

  final email = findUser(1)
      .map((name) => name.toLowerCase())
      .map((name) => '$name@example.com');
  print('email: ${email.getOrNull()}'); // alice@example.com

  final missingEmail = findUser(99)
      .map((name) => '$name@example.com');
  print('missing: ${missingEmail.isNone}'); // true

  final chained = Option(3).flatMap((x) => Option(x > 0 ? x * 10 : null));
  print('chained: ${chained.getOrNull()}'); // 30

  // --- Filter ---
  final even = Option(4).filter((x) => x.isEven);
  final odd = Option(3).filter((x) => x.isEven);
  print('even: ${even.isSome}'); // true
  print('odd (filtered out): ${odd.isNone}'); // true

  // --- Tap (side effect) ---
  Option(7).tap((x) => print('side effect: $x')); // side effect: 7

  // --- OrElse fallback ---
  final fallback = findUser(99).orElse(Option('Guest'));
  print('fallback: ${fallback.getOrNull()}'); // Guest

  // --- Zip ---
  final pair = Option(1).zip(Option('hello'));
  print('zipped: ${pair.getOrNull()}'); // (1, hello)

  final failedPair = Option<int>(null).zip(Option('hello'));
  print('failed zip: ${failedPair.isNone}'); // true

  // --- Fold ---
  final result = findUser(2).fold(
    () => 'nobody',
    (name) => 'Found: $name',
  );
  print(result); // Found: Bob

  // --- ToList ---
  print(Option(42).toList()); // [42]
  print(Option<int>(null).toList()); // []
}
