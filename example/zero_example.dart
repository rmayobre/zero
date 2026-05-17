/// A self-contained example that demonstrates how zero's types compose
/// together to model a simple user-profile loading scenario.
///
/// The flow:
///   1. Validate raw input with [Either]
///   2. Parse and cache the user id with [Option]
///   3. Fetch the user profile with [Task] (async, lazy)
///   4. Capture the outcome with [Result]
///   5. Stream activity events through [Flow] and track app state with [Snapshot]
library;

import 'package:zero/zero.dart';

// ---------------------------------------------------------------------------
// Domain
// ---------------------------------------------------------------------------

class UserProfile {
  final int id;
  final String name;
  final String email;
  const UserProfile(this.id, this.name, this.email);
  @override
  String toString() => 'UserProfile($id, $name, $email)';
}

// ---------------------------------------------------------------------------
// Validation layer — Either<ValidId, ErrorMessage>
// ---------------------------------------------------------------------------

Either<int, String> validateUserId(String raw) {
  final n = int.tryParse(raw);
  if (n == null) return Either.right('Id must be a number, got "$raw"');
  if (n <= 0) return Either.right('Id must be positive, got $n');
  return Either.left(n);
}

// ---------------------------------------------------------------------------
// Repository layer — Task<UserProfile>
// ---------------------------------------------------------------------------

const _db = {
  1: UserProfile(1, 'Alice', 'alice@example.com'),
  2: UserProfile(2, 'Bob', 'bob@example.com'),
};

Task<UserProfile> fetchProfile(int id) => Task(() async {
  await Future.delayed(Duration(milliseconds: 10)); // simulated network
  final profile = _db[id];
  if (profile == null) throw Exception('User $id not found');
  return profile;
});

// ---------------------------------------------------------------------------
// Cache layer — Option<UserProfile>
// ---------------------------------------------------------------------------

final Map<int, UserProfile> _cache = {};

Option<UserProfile> getCached(int id) => Option(_cache[id]);

void putCache(UserProfile p) => _cache[p.id] = p;

// ---------------------------------------------------------------------------
// Activity log — Flow<String>
// ---------------------------------------------------------------------------

final List<String> _activityLog = [];

// ---------------------------------------------------------------------------
// App state — Snapshot<String>
// ---------------------------------------------------------------------------

final appState = Snapshot('idle');

// ---------------------------------------------------------------------------
// Business logic
// ---------------------------------------------------------------------------

/// Loads a user profile by raw string id. Returns a [Result] of the profile.
///
/// Pipeline:
///   validateUserId  →  `Either<int, String>`
///   getCached       →  `Option<UserProfile>`   (fast path)
///   fetchProfile    →  `Task<UserProfile>`     (slow path)
///   Result          →  captures exceptions
Future<Result<UserProfile>> loadUser(String rawId) async {
  // Step 1: validate input
  final idOrError = validateUserId(rawId);
  if (idOrError.isRight) {
    appState.value = 'error';
    return Result.failure(ArgumentError(idOrError.right));
  }
  final id = idOrError.left;

  // Step 2: fast path — check cache
  final cached = getCached(id);
  if (cached.isSome) {
    _activityLog.add('cache hit for id=$id');
    return Result.success(cached.getOrThrow());
  }

  // Step 3: slow path — fetch and cache
  appState.value = 'loading';
  _activityLog.add('fetching id=$id');

  return (await Result.runAsync(() => fetchProfile(id).run()))
      .onSuccess((p) {
        putCache(p);
        _activityLog.add('cached id=${p.id}');
        appState.value = 'success';
      })
      .onFailure((_) => appState.value = 'error');
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

void main() async {
  // Watch app state changes
  appState.collect().listen((s) => print('[state] $s'));

  // --- Valid request ---
  final r1 = await loadUser('1');
  r1.onSuccess((p) => print('Loaded: $p'))
      .onFailure((e) => print('Failed: $e'));
  // [state] loading
  // [state] success
  // Loaded: UserProfile(1, Alice, alice@example.com)

  // --- Cache hit (no network call) ---
  final r2 = await loadUser('1');
  print('from cache: ${r2.getOrNull()?.name}'); // from cache: Alice

  // --- Another user ---
  final r3 = await loadUser('2');
  print('second user: ${r3.getOrNull()?.name}'); // second user: Bob

  // --- Invalid id (not a number) ---
  final r4 = await loadUser('abc');
  print('bad input: ${r4.isFailure}'); // bad input: true

  // --- Not found ---
  final r5 = await loadUser('99');
  print('not found: ${r5.isFailure}'); // not found: true

  await Future.delayed(Duration.zero);

  // --- Replay activity log via Flow ---
  print('\nActivity log:');
  await for (final entry in _activityLog.flow().collect()) {
    print('  $entry');
  }

  // --- Effect: build a summary synchronously ---
  final summary = Effect(() => _cache.values.toList())
      .map((profiles) => profiles.map((p) => p.name).join(', '))
      .map((names) => 'Cached users: $names');

  print(summary.run()); // Cached users: Alice, Bob
}
