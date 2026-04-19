import 'package:flutter_test/flutter_test.dart';
import 'package:pi_dev_agentia/data/models/user_model.dart';

void main() {
  test('fromJson parses correctly', () {
    final json = {'id': '1', 'name': 'Test', 'email': 'test@test.com'};
    final user = UserModel.fromJson(json);
    expect(user.id, '1');
    expect(user.name, 'Test');
    expect(user.email, 'test@test.com');
  });

  test('toJson returns correct map', () {
    final user = UserModel(id: '2', name: 'Alice', email: 'alice@mail.com');
    final map = user.toJson();
    expect(map['id'], '2');
    expect(map['name'], 'Alice');
    expect(map['email'], 'alice@mail.com');
  });
}
