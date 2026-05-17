## 0.0.1

### Core monadic types

- `Option<T>` — zero-cost extension type wrapping `T?`; `Some(value)` / `None` constructors; `map`, `flatMap`, `filter`, `getOrElse`, `getOrThrow`, `fold`, `toResult`, `toEither`, and more.
- `Either<L, R>` — discriminated union of a left and right value; `Left` / `Right` constructors; `map`, `mapLeft`, `flatMap`, `fold`, `swap`, `toOption`, `toResult`, and more.
- `Result<T>` — success-or-failure with an optional `StackTrace`; `Success` / `Failure` constructors; `map`, `flatMap`, `recover`, `fold`, `getOrThrow`, `toOption`, `toEither`, and more.
- `Task<T>` — lazy, deferred `Future`-based computation; `run`, `map`, `flatMap`, `zip`, `catchError`, and more.
- `Flow<T>` — lazy, deferred `Stream`-based computation; `run`, `map`, `flatMap`, `filter`, `fold`, and more.

### Additional types

- `Snapshot<T>` — eager hot-stream wrapper with consecutive-distinct deduplication; exposes a writable `value` setter that pushes to the stream; optional source stream for seeding initial values.

### Extension methods

- `FutureExtension` — `task()`, `toResult()` on `Future<T>`.
- `StreamExtension` — `toFlow()` on `Stream<T>`.
- `IterableExtension` — `flow()`, `firstOption`, `lastOption`, monadic sequence helpers on `Iterable<T>`.

### Precondition helpers

- `check`, `require`, `checkNotNull`, `requireNotNull` — throw `StateError` (internal invariant) or `ArgumentError` (bad caller input) with optional lazy message builders.

### Annotations

- `@throws` — marks any function whose body may raise; imported from `lib/src/internal/throws.dart`.
- `@eager` / `@lazy` — required on every extension type declaration; signal whether the backing value is a concrete result or a deferred computation.
- `@inline` / `@noinline` — `vm:prefer-inline` / `vm:never-inline` pragmas for standalone hot-path and error-path functions.

### Internals

- `typedefs.dart` — single source of truth for all function-type aliases (`Calculation<T>`, `Callable`, `MessageBuilder`, `Predicate<T>`, `Reducer<A,T>`, `Transformation<T,R>`, `ValueCallable<T>`).
- `EitherData` / `ResultData` record types kept `@internal`.
