import 'package:meta/meta.dart';

import 'inline.dart';
import 'internal/constants.dart';
import 'internal/throws.dart';

@internal
typedef MessageBuilder = String Function();

@throws
@inline
void check(bool condition, [MessageBuilder? builder]) {
  if (!condition) throw StateError(builder?.call() ?? conditionCheckMsg);
}

@throws
@inline
T checkNotNull<T extends Object>(T? value, [MessageBuilder? message]) {
  if (value != null) return value;
  throw StateError(message?.call() ?? nullCheckMsg);
}

@throws
@inline
T checkTypeOf<T>(dynamic value, [MessageBuilder? message]) {
  if (value is T) return value;
  throw StateError(message?.call() ?? '$typeCheckMsg: $T');
}

@throws
@inline
Never error(String message) => throw StateError(message);

@throws
@inline
void require(bool condition, [MessageBuilder? message]) {
  if (condition == false)
    throw ArgumentError(message?.call() ?? conditionCheckMsg);
}

@throws
@inline
T requireNotNull<T extends Object>(T? value, [MessageBuilder? message]) {
  if (value != null) return value;
  throw ArgumentError.notNull(message?.call() ?? nullCheckMsg);
}

@throws
@inline
T requireTypeOf<T>(dynamic value, [MessageBuilder? message]) {
  if (value is T) return value;
  throw ArgumentError(message?.call() ?? '$typeCheckMsg: $T');
}

// ignore: non_constant_identifier_names
@throws
Never TODO([String? message]) => throw UnimplementedError(message);
