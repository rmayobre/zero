
import 'package:meta/meta.dart';

@internal
typedef Calculation<T> = T Function();

@internal
typedef Callable = void Function();

@internal
typedef Predicate<T> = bool Function(T value);

@internal
typedef Reducer<A, T> = A Function(A acc, T value);

@internal
typedef Transformation<T, R> = R Function(T value);

@internal
typedef ValueCallable<T> = void Function(T value);
