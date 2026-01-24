import '../entities/counter.dart';

abstract class CounterRepository {
  Counter getCounter();
  Counter increment();
}


