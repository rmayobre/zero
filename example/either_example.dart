import 'package:zero/zero.dart';

// Validation returns Either<ValidUsername, String> where left = valid, right = error
Either<String, String> validateUsername(String name) {
  if (name.isEmpty) return Either.right('Username cannot be empty');
  if (name.length < 3) return Either.right('Username too short (min 3 chars)');
  if (name.contains(' ')) return Either.right('Username cannot contain spaces');
  return Either.left(name);
}

Either<int, String> parseInt(String raw) {
  final n = int.tryParse(raw);
  return n != null ? Either.left(n) : Either.right('Not a number: $raw');
}

void main() {
  // --- Construction ---
  final left = Either<int, String>.left(42);
  final right = Either<int, String>.right('error');

  print(left.isLeft); // true
  print(right.isRight); // true

  // --- Retrieval ---
  print(left.left); // 42
  print(right.right); // error
  print(left.leftOrNull()); // 42
  print(right.leftOrNull()); // null
  print(right.rightOrDefault('fallback')); // error
  print(left.rightOrDefault('fallback')); // fallback

  // --- Validation pattern ---
  final valid = validateUsername('alice');
  final tooShort = validateUsername('al');
  final empty = validateUsername('');

  print(valid.leftOrNull()); // alice
  print(tooShort.rightOrNull()); // Username too short (min 3 chars)
  print(empty.rightOrNull()); // Username cannot be empty

  // --- Fold ---
  final message = validateUsername('bob').fold(
    left: (name) => 'Welcome, $name!',
    right: (err) => 'Validation failed: $err',
  );
  print(message); // Welcome, bob!

  // --- Map (transforms the right side) ---
  final length = parseInt('42').map((n) => n * 2);
  print(length.leftOrNull()); // 84

  final failed = parseInt('bad').map((n) => n * 2);
  print(failed.rightOrNull()); // Not a number: bad

  // --- MapLeft / MapRight ---
  final uppercased = validateUsername('alice')
      .mapLeft((name) => name.toUpperCase());
  print(uppercased.leftOrNull()); // ALICE

  // --- FlatMap (chain validations) ---
  Either<String, String> validateEmail(String email) {
    if (!email.contains('@')) return Either.right('Invalid email: $email');
    return Either.left(email);
  }

  final registration = validateUsername('alice')
      .flatMap((name) => validateEmail('alice@example.com')
          .mapLeft((email) => '$name:$email'));
  print(registration.leftOrNull()); // alice:alice@example.com

  // --- Swap ---
  final swapped = Either<int, String>.left(10).swap();
  print(swapped.isRight); // true
  print(swapped.right); // 10

  // --- Convert to Option / Result ---
  final opt = validateUsername('eve').leftOption();
  print(opt.isSome); // true

  final res = parseInt('123').leftResult();
  print(res.isSuccess); // true

  // --- Side effects ---
  validateUsername('carol')
      .onLeft((name) => print('Accepted: $name'))  // Accepted: carol
      .onRight((err) => print('Rejected: $err'));
}
