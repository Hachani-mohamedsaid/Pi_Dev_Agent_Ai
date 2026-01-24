import '../../core/usecase/usecase.dart';
import '../entities/counter.dart';
import '../repositories/counter_repository.dart';

class IncrementCounter extends UseCase<Counter, NoParams> {
  const IncrementCounter(this._repository);
  final CounterRepository _repository;

  @override
  Counter call(NoParams params) => _repository.increment();
}


