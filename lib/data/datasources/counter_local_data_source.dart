abstract class CounterLocalDataSource {
  int read();
  int increment();
}

/// Simple in-memory data source (replace with SharedPreferences/SQLite later).
class InMemoryCounterLocalDataSource implements CounterLocalDataSource {
  InMemoryCounterLocalDataSource({int initialValue = 0}) : _value = initialValue;

  int _value;

  @override
  int read() => _value;

  @override
  int increment() {
    _value += 1;
    return _value;
  }
}


