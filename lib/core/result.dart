import 'package:offroad_nav/core/failure.dart';

class Result<T> {
  final T? data;
  final Failure? error;
  const Result._({this.data, this.error});

  bool get isOk => error == null;

  static Result<T> ok<T>(T data) => Result._(data: data);
  static Result<T> err<T>(Failure e) => Result._(error: e);

  // ✅ Публичный хелпер для операций без полезного результата
  static Result<void> okVoid() => const Result<void>._(data: null);
}
