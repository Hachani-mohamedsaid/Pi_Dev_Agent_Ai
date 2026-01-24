/// Generic use case contract.
///
/// In Clean Architecture, the Presentation layer calls use cases to execute
/// business logic.
abstract class UseCase<Output, Params> {
  const UseCase();
  Output call(Params params);
}

class NoParams {
  const NoParams();
}


