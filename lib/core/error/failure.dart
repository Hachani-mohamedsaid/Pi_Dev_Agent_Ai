/// Base class for failures used in the Domain layer.
///
/// Keep it simple (no external deps) and expand as your project grows.
abstract class Failure {
  const Failure(this.message);
  final String message;

  @override
  String toString() => '$runtimeType(message: $message)';
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}


