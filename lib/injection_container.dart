import 'data/datasources/counter_local_data_source.dart';
import 'data/repositories/counter_repository_impl.dart';
import 'domain/repositories/counter_repository.dart';
import 'domain/usecases/get_counter.dart';
import 'domain/usecases/increment_counter.dart';
import 'presentation/state/counter_controller.dart';

/// Very small manual DI container (no external packages).
class InjectionContainer {
  InjectionContainer._();

  static final InjectionContainer instance = InjectionContainer._();

  late final CounterLocalDataSource _counterLocalDataSource =
      InMemoryCounterLocalDataSource();

  late final CounterRepository _counterRepository =
      CounterRepositoryImpl(_counterLocalDataSource);

  late final GetCounter _getCounter = GetCounter(_counterRepository);
  late final IncrementCounter _incrementCounter =
      IncrementCounter(_counterRepository);

  CounterController buildCounterController() {
    return CounterController(
      getCounter: _getCounter,
      incrementCounter: _incrementCounter,
    );
  }
}


