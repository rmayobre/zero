import 'dart:async';

import 'internal/eager.dart';
import 'internal/throws.dart';
import 'internal/typedefs.dart';
import 'flow.dart';
import 'task.dart';

@eager
extension type Snapshot<T extends Object>._(_SnapshotState<T> _data) {
  // @throws because source.listen() throws StateError if source is a
  // single-subscription stream that already has a listener.
  @throws
  factory Snapshot(T initial, [Stream<T>? source]) {
    final data = _SnapshotState(initial);
    source?.listen(
      (sourceData) {
        if (sourceData != data.value) {
          data.value = sourceData;
          data.controller.add(sourceData);
        }
      },
      onError: data.controller.addError,
      onDone: data.controller.close,
    );
    return Snapshot._(data);
  }

  T get value => _data.value;
  set value(T v) {
    if (v == _data.value) return;
    _data.value = v;
    _data.controller.add(v);
  }

  // @throws because transformer is called immediately to derive the initial value.
  @throws
  Snapshot<R> map<R extends Object>(Transformation<T, R> transformer) =>
      Snapshot(
        transformer(_data.value),
        _data.controller.stream.map(transformer),
      );

  // flatMap cannot derive an initial value synchronously, so the caller supplies one.
  Snapshot<R> flatMap<R extends Object>(
    Transformation<T, Flow<R>> transformer,
    R initial,
  ) => Snapshot(
    initial,
    _data.controller.stream.asyncExpand((s) => transformer(s).collect()),
  );

  Snapshot<T> filter(Predicate<T> predicate) =>
      Snapshot(_data.value, _data.controller.stream.where(predicate));

  Snapshot<T> onEach(ValueCallable<T> process) => Snapshot(
    _data.value,
    _data.controller.stream.map((element) {
      process(element);
      return element;
    }),
  );

  Snapshot<T> take(int n) =>
      Snapshot(_data.value, _data.controller.stream.take(n));

  Snapshot<T> drop(int n) =>
      Snapshot(_data.value, _data.controller.stream.skip(n));

  //
  // Transformers
  //

  Flow<T> flow() => Flow(() => _data.controller.stream);

  Stream<T> collect() => _data.controller.stream;

  Task<R> fold<R extends Object>(R initial, Reducer<R, T> combine) =>
      Task(() => _data.controller.stream.fold(initial, combine));

  /// Asynchronous iteration of the flow.
  @throws
  void forEach(ValueCallable<T> process) async {
    await for (final element in collect()) {
      process(element);
    }
  }
}

final class _SnapshotState<T extends Object> {
  T value;

  final StreamController<T> controller; // Broadcast controller

  _SnapshotState(this.value) : controller = StreamController<T>.broadcast();
}
