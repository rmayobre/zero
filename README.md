# Zero Nads

A Dart 3.x functional programming library built on **extension types** — zero-cost wrappers that add monadic abstractions with no runtime overhead.

Provides `Option`, `Either`, `Result`, `Task`, `Flow`, `Effect`, and `Snapshot`, plus precondition helpers and stream/iterable/future extensions.

## Features

- **`Option<T>`** — represent presence or absence of a value without nullable `T?` leaking everywhere
- **`Either<L, R>`** — hold one of two distinct values (e.g. error on the left, result on the right)
- **`Result<T>`** — success or failure, with optional `StackTrace` preservation
- **`Task<T>`** — lazy asynchronous computation; nothing runs until you call `.run()`
- **`Flow<T>`** — lazy asynchronous stream; nothing is subscribed until you call `.collect()`
- **`Effect<T>`** — lazy synchronous computation
- **`Snapshot<T>`** — reactive mutable state backed by a broadcast `Stream`
- **Preconditions** — `check`, `require`, `checkNotNull`, etc. for guard clauses
- **Extensions** — `.flow()` on `Stream` and `Iterable`, `.task()` on `Future`, `.options()` on `Iterable<T?>`

All types are extension types — they carry no runtime allocation beyond their wrapped value.

## Getting started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  zero: ^1.0.0
```

Then import:

```dart
import 'package:zero/zero.dart';
```

## Usage

### Option\<T\>

`Option<T>` wraps a nullable `T?`. Use `Some(value)` semantics when the value is present, `None` when it is absent.

```dart
// Construction
final name    = Option<String>('Alice');     // Some
final empty   = Option<String>(null);        // None
final nothing = Option<String>.nothing();   // None (explicit)

// Run a computation that might return null
final parsed = Option.run(() => int.tryParse(input));

// Query
parsed.isSome; // true / false
parsed.isNone;

// Safe access
parsed.getOrDefault(0);
parsed.getOrElse(() => computeDefault());
parsed.getOrNull();    // T?
parsed.getOrThrow();   // throws StateError if None

// Transform
final doubled  = parsed.map((n) => n * 2);
final filtered = parsed.filter((n) => n > 0);
final chained  = parsed.flatMap((n) => Option(n > 0 ? n : null));
final fallback = parsed.orElse(Option(0));

// Fold both branches
final label = parsed.fold(
  () => 'nothing here',
  (n) => 'got $n',
);

// Side effects (returns same Option)
parsed.tap((n) => print('value is $n'));

// Zip two Options into a record — None if either is None
final pair = Option('hello').zip(Option(42)); // Some(('hello', 42))

// Convert
final list = parsed.toList(); // [value] or []
```

---

### Either\<L, R\>

`Either<L, R>` holds exactly one of two values. By convention left is the error/secondary path and right is the success/primary path.

```dart
// Construction
final ok  = Either<String, int>.right(42);
final err = Either<String, int>.left('not a number');

// Query
ok.isRight; // true
err.isLeft;

// Access right (success) value
ok.right;                    // 42 — throws StateError if Left
ok.rightOrNull();            // int?
ok.rightOrDefault(0);
ok.rightOrElse(() => -1);

// Access left (error) value
err.left;                    // 'not a number' — throws StateError if Right
err.leftOrNull();            // String?
err.leftOrDefault('fallback');
err.leftOrElse(() => 'default');

// Transform
final mapped     = ok.map((n) => n * 2);               // Right(84)
final mappedLeft = err.mapLeft((s) => s.length);        // Left(13)
final mappedRight = ok.mapRight((n) => 'value: $n');

final chained = ok.flatMap(
  (n) => n > 0 ? Either.right('positive') : Either.left('non-positive'),
);
final chainedLeft = err.flatMapLeft((s) => Either.left(s.toUpperCase()));

// Fold both sides
final label = ok.fold(
  left:  (e) => 'error: $e',
  right: (n) => 'value: $n',
);

// Swap sides
final swapped = ok.swap(); // Left(42)

// Fallback access (right-biased)
ok.getOrDefault(0);
ok.getOrElse(() => -1);

// Side effects
ok
  .onRight((n) => print('success: $n'))
  .onLeft((e) => print('error: $e'));

// Convert
final result     = ok.rightResult(); // Result<int>
final leftResult = err.leftResult(); // Result<String>
final option     = ok.rightOption(); // Option<int>
final leftOption = err.leftOption(); // Option<String>
```

---

### Result\<T\>

`Result<T>` represents either a successful value or a failure (any `Object`, with an optional `StackTrace`). Unlike `Either`, `Result` is specifically designed for the success/failure pattern and integrates with Dart's error system.

```dart
// Construction
final ok   = Result.success(42);
final fail = Result<int>.failure('oops', StackTrace.current);

// Wrap a synchronous computation that might throw
final parsed = Result.run(() => int.parse(userInput));

// Wrap an asynchronous computation that might throw
final fetched = await Result.runAsync(() async => await api.getUser(id));

// Query
parsed.isSuccess;
parsed.isFailure;

// Access
parsed.getOrDefault(0);
parsed.getOrElse(() => -1);
parsed.getOrNull();       // T?
parsed.getOrThrow();      // re-throws original error with original StackTrace

// Transform
final doubled  = parsed.map((n) => n * 2);
final chained  = parsed.flatMap((n) => Result.run(() => expensiveOp(n)));

// Recovery
final recovered     = parsed.recover((error) => 0);
final recoveredWith = parsed.recoverWith((error) => Result.success(-1));
final mappedError   = parsed.mapFailure((e) => MyError('wrapped: $e'));

// Fold both branches
final label = parsed.fold(
  onSuccess: (n) => 'got $n',
  onFailure: (e) => 'failed: $e',
);

// Side effects
parsed
  .onSuccess((n) => print('done: $n'))
  .onFailure((e) => print('error: $e'));

// Convert
final either = parsed.either();   // Either<T, Object>
final option = parsed.asOption(); // Option<T>
final future = parsed.asFuture(); // Future<T>  (throws on failure)
final task   = parsed.asTask();   // Task<T>
```

---

### Task\<T\>

`Task<T>` is a lazy wrapper around `() -> Future<T>`. The computation does not start until `.run()` is called.

```dart
// Construction
final task      = Task<int>(() async => await fetchSomething());
final immediate = Task.of(100);  // resolves immediately with a constant

// Wrap an existing Future in a Task
final fromFuture = myFuture.task();

// Transform (still lazy — nothing runs yet)
final doubled = task.map((n) => n * 2);
final chained = task.flatMap((n) => Task(() async => n + 1));

// Recovery
final safe = task.recover((error) => -1);

// Side effects (still lazy)
final logged = task
  .onSuccess((n) => print('result: $n'))
  .onFailure((e) => print('error: $e'));

// Zip two tasks — runs them concurrently with Future.wait
final pair = task.zip(Task.of('hello')); // Task<(int, String)>

// Execute
final result = await task.run();

// Fold async — handles both success and failure in one call
final label = await task.foldAsync(
  onSuccess: (n) => 'got $n',
  onFailure: (e) => 'failed: $e',
);
```

#### Task\<Iterable\<T\>\> extension

```dart
// Flatten a Task<Iterable<T>> into a Stream<T>
final Task<Iterable<String>> task = fetchNames();
await for (final name in task.flatten()) {
  print(name);
}
```

---

### Flow\<T\>

`Flow<T>` is a lazy wrapper around `() -> Stream<T>`. Nothing is subscribed until `.collect()` or `.forEach()` is called.

```dart
// Construction
final flow       = Flow<int>(() => Stream.fromIterable([1, 2, 3, 4, 5]));
final fromStream = Flow.of(existingStream);
final fromList   = Flow.fromIterable([1, 2, 3]);

// Convert a Stream or Iterable directly
final fromStreamExt   = myStream.flow();
final fromIterableExt = myList.flow();

// Transform (still lazy)
final evens     = flow.filter((n) => n.isEven);
final doubled   = flow.map((n) => n * 2);
final flattened = flow.flatMap((n) => Flow.fromIterable([n, n * 10]));

// Limit / skip
final first3 = flow.take(3);
final skip2  = flow.drop(2);

// Side effects (lazy)
final logged = flow.onEach((n) => print(n));

// Recovery from stream errors
final safe = flow.recover((record) {
  final (error, stackTrace) = record;
  print('error: $error');
  return -1; // fallback element
});

// Silently drop errors
final silent = flow.catchErrors();

// Aggregate into a Task (lazy fold)
final sumTask = flow.fold(0, (acc, n) => acc + n);
final sum = await sumTask.run();

// Collect / iterate (subscribes now)
final stream = flow.collect();
await flow.forEach((n) => print(n));

// Convert to Snapshot (only for Flow<T> where T extends Object)
final snapshot = flow.snapshot(0); // initial value = 0
```

---

### Effect\<T\>

`Effect<T>` is a lazy wrapper around a synchronous `() -> T` computation. Nothing executes until `.run()` is called.

```dart
// Construction
final effect = Effect<String>(() => buildConfigString());

// Transform (still lazy)
final upper   = effect.map((s) => s.toUpperCase());
final chained = effect.flatMap((s) => Effect(() => processString(s)));

// Side effects (lazy, returns same value)
final logged = effect.onEach((s) => print('result: $s'));

// Execute
final value = effect.run(); // runs now, may throw
```

---

### Snapshot\<T\>

`Snapshot<T>` is reactive mutable state. It always holds a current `value` and broadcasts changes to all listeners via a broadcast stream. Consecutive duplicate values are suppressed.

```dart
// Construction
final counter = Snapshot<int>(0);

// Attach to an existing stream source
final fromStream = Snapshot<int>(0, myStream);

// Read / write
print(counter.value); // 0
counter.value = 1;    // emits 1 to subscribers; duplicate values are no-ops

// Listen for changes
counter.collect().listen((n) => print('changed: $n'));

// Convert to Flow / Stream for downstream use
final flow   = counter.flow();
final stream = counter.collect();

// Transform (produces a new Snapshot)
final doubled  = counter.map((n) => n * 2);
final positive = counter.filter((n) => n > 0);
final side     = counter.onEach((n) => print('changed: $n'));

// flatMap into a Flow (caller supplies the initial value)
final mapped = counter.flatMap((n) => Flow.fromIterable([n, n + 1]), 0);

// Limit / skip
final first5 = counter.take(5);
final skip2  = counter.drop(2);

// Aggregate (resolves when the stream closes)
final sumTask = counter.fold(0, (acc, n) => acc + n);
final sum = await sumTask.run();

// Iterate
await counter.forEach((n) => print(n));
```

---

### Preconditions

Guard clause helpers that throw `StateError` (internal invariant violations) or `ArgumentError` (bad caller input).

```dart
import 'package:zero/zero.dart';

// StateError variants — for internal invariants
check(list.isNotEmpty, () => 'list must not be empty');
final str   = checkNotNull(maybeString, () => 'string is required');
final typed = checkTypeOf<String>(dynamicValue);
error('should never reach here'); // Never — always throws

// ArgumentError variants — for public API parameter validation
require(age >= 0, () => 'age must be non-negative');
final name = requireNotNull(maybeName, () => 'name must be provided');
final id   = requireTypeOf<int>(rawId);

// Placeholder for unimplemented branches
TODO('implement serialization'); // throws UnimplementedError
```

---

### Extensions

#### `Stream<T>` extensions

```dart
// Convert a Stream<T> to a lazy Flow<T>
final flow = myStream.flow();

// Filter and downcast — emits only elements of type R
final strings = mixedStream.whereType<String>();
```

#### `Iterable<T>` extensions

```dart
// Convert an Iterable<T> to a lazy Flow<T>
final flow = myList.flow();
```

#### `Iterable<T?>` extensions

```dart
// Wrap each element in an Option<T>
final options = nullableList.options(); // Iterable<Option<T>>
```

#### `Future<T>` extensions

```dart
// Wrap a Future<T> in a lazy Task<T>
final task = myFuture.task();
```

---

## Examples

Standalone examples for each type are in the [`example/`](example/) directory:

| File | Covers |
|---|---|
| [`option_example.dart`](example/option_example.dart) | `Option<T>` |
| [`result_example.dart`](example/result_example.dart) | `Result<T>` |
| [`either_example.dart`](example/either_example.dart) | `Either<L, R>` |
| [`task_example.dart`](example/task_example.dart) | `Task<T>` |
| [`effect_example.dart`](example/effect_example.dart) | `Effect<T>` |
| [`flow_example.dart`](example/flow_example.dart) | `Flow<T>` |
| [`snapshot_example.dart`](example/snapshot_example.dart) | `Snapshot<T>` |
| [`zero_example.dart`](example/zero_example.dart) | End-to-end composition |

---

## Additional information

- **Zero runtime cost** — all types are Dart 3 extension types; the wrapper itself has no heap allocation.
- **No shared interface** — extension types cannot implement interfaces, so `Option`, `Either`, `Result`, `Task`, `Flow`, and `Effect` are self-contained. There is no common `Monad` supertype.
- **Lazy by default for async** — `Task` and `Flow` do nothing until executed. This makes them composable without side effects.
- **Error transparency** — `Result.getOrThrow()` re-throws the original exception with the original `StackTrace`, preserving full context.

For bugs or feature requests, open an issue in the repository.
