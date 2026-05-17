import 'package:zero_nads/zero_nads.dart';

// A lazy synchronous computation that reads config values
Effect<String> readEnv(String key, String fallback) =>
    Effect(() => fallback); // simplified stand-in for actual env lookup

// Build a database URL from parts
Effect<String> buildDatabaseUrl() {
  final host = readEnv('DB_HOST', 'localhost');
  final port = readEnv('DB_PORT', '5432');
  final name = readEnv('DB_NAME', 'myapp');
  return host.flatMap((h) =>
      port.flatMap((p) =>
          name.map((n) => 'postgres://$h:$p/$n')));
}

void main() {
  // --- Construction ---
  final effect = Effect(() => 42);
  print(effect.run()); // 42

  // --- Map ---
  final doubled = Effect(() => 5).map((x) => x * 2);
  print(doubled.run()); // 10

  // --- FlatMap (chain synchronous effects) ---
  final chained = Effect(() => 'hello')
      .flatMap((s) => Effect(() => '$s world'))
      .map((s) => s.toUpperCase());
  print(chained.run()); // HELLO WORLD

  // --- onEach (side effect, then forward value) ---
  final logged = Effect(() => 99)
      .onEach((x) => print('computed: $x'));
  final value = logged.run(); // prints: computed: 99
  print(value); // 99

  // --- Composing multiple effects ---
  final dbUrl = buildDatabaseUrl();
  print(dbUrl.run()); // postgres://localhost:5432/myapp

  // --- Lazy: nothing runs until .run() ---
  var sideEffectRan = false;
  final lazy = Effect(() {
    sideEffectRan = true;
    return 'done';
  });
  print(sideEffectRan); // false
  lazy.run();
  print(sideEffectRan); // true

  // --- Transforming a parsed config ---
  final Effect<int> port = readEnv('PORT', '8080').map(int.parse);
  print(port.run()); // 8080
}
