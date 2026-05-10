import 'package:flutter_test/flutter_test.dart';
import 'package:pi_dev_agentia/domain/usecases/login_usecase.dart';
import 'package:pi_dev_agentia/domain/entities/user.dart';
import 'package:pi_dev_agentia/domain/repositories/auth_repository.dart';
import 'package:mockito/mockito.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late LoginUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = LoginUseCase(repository);
  });

  test('calls repository.login and returns user', () async {
    final user = User(id: '1', name: 'Test', email: 'test@test.com');
    when(
      repository.login('test@test.com', 'pass'),
    ).thenAnswer((_) async => user);
    final result = await useCase(
      LoginParams(email: 'test@test.com', password: 'pass'),
    );
    expect(result, user);
    verify(repository.login('test@test.com', 'pass')).called(1);
  });
}
