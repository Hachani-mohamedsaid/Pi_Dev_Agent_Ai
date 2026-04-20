import 'package:flutter_test/flutter_test.dart';
import 'package:pi_dev_agentia/presentation/state/counter_controller.dart';
import 'package:pi_dev_agentia/domain/entities/counter.dart';
import 'package:pi_dev_agentia/domain/usecases/get_counter.dart';
import 'package:pi_dev_agentia/domain/usecases/increment_counter.dart';
import 'package:pi_dev_agentia/core/usecase/usecase.dart';
import 'package:mockito/mockito.dart';

class MockGetCounter extends Mock implements GetCounter {
  @override
  Counter call(NoParams params) => super.noSuchMethod(
        Invocation.method(#call, [params]),
        returnValue: const Counter(0),
        returnValueForMissingStub: const Counter(0),
      ) as Counter;
}

class MockIncrementCounter extends Mock implements IncrementCounter {
  @override
  Counter call(NoParams params) => super.noSuchMethod(
        Invocation.method(#call, [params]),
        returnValue: const Counter(0),
        returnValueForMissingStub: const Counter(0),
      ) as Counter;
}

void main() {
  late MockGetCounter getCounter;
  late MockIncrementCounter incrementCounter;
  late CounterController controller;

  setUp(() {
    getCounter = MockGetCounter();
    incrementCounter = MockIncrementCounter();
    controller = CounterController(
      getCounter: getCounter,
      incrementCounter: incrementCounter,
    );
  });

  test('load sets counter', () {
    when(getCounter.call(const NoParams())).thenReturn(const Counter(5));
    controller.load();
    expect(controller.counter.value, 5);
  });

  test('increment updates counter', () {
    when(incrementCounter.call(const NoParams())).thenReturn(const Counter(6));
    controller.increment();
    expect(controller.counter.value, 6);
  });
}