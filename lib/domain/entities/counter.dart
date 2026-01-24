class Counter {
  const Counter(this.value);
  final int value;

  Counter copyWith({int? value}) => Counter(value ?? this.value);
}


