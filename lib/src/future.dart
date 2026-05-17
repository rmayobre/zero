import 'task.dart';

extension FutureExtensions <T> on Future<T> {

  Task<T> task() => Task(() => this);
}