import '../../core/usecase/usecase.dart';
import '../entities/counter.dart';
import '../repositories/counter_repository.dart';

class GetCounter extends UseCase<Counter, NoParams> {
  const GetCounter(this._repository);
  final CounterRepository _repository;

  @override
  Counter call(NoParams params) => _repository.getCounter();
}


