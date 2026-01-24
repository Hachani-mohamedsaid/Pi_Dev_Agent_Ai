import 'package:flutter/foundation.dart';

import '../../core/usecase/usecase.dart';
import '../../domain/entities/counter.dart';
import '../../domain/usecases/get_counter.dart';
import '../../domain/usecases/increment_counter.dart';

class CounterController extends ChangeNotifier {
  CounterController({
    required GetCounter getCounter,
    required IncrementCounter incrementCounter,
  })  : _getCounter = getCounter,
        _incrementCounter = incrementCounter;

  final GetCounter _getCounter;
  final IncrementCounter _incrementCounter;

  Counter _counter = const Counter(0);
  Counter get counter => _counter;

  void load() {
    _counter = _getCounter(const NoParams());
    notifyListeners();
  }

  void increment() {
    _counter = _incrementCounter(const NoParams());
    notifyListeners();
  }
}


