import '../../domain/entities/counter.dart';
import '../../domain/repositories/counter_repository.dart';
import '../datasources/counter_local_data_source.dart';
import '../models/counter_model.dart';

class CounterRepositoryImpl implements CounterRepository {
  CounterRepositoryImpl(this._local);

  final CounterLocalDataSource _local;

  @override
  Counter getCounter() {
    return CounterModel(_local.read());
  }

  @override
  Counter increment() {
    return CounterModel(_local.increment());
  }
}


