import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pi_dev_agentia/data/repositories/auth_repository_impl.dart';
import 'package:pi_dev_agentia/domain/entities/user.dart';
import 'package:pi_dev_agentia/data/datasources/auth_local_data_source.dart';
import 'package:pi_dev_agentia/data/datasources/auth_remote_data_source.dart';
import 'package:pi_dev_agentia/data/models/profile_model.dart';

class MockRemote extends Mock implements AuthRemoteDataSource {}

class MockLocal extends Mock implements AuthLocalDataSource {}

void main() {
  late MockRemote remote;
  late MockLocal local;
  late AuthRepositoryImpl repo;

  setUp(() {
    remote = MockRemote();
    local = MockLocal();
    repo = AuthRepositoryImpl(remoteDataSource: remote, localDataSource: local);
  });

  test('login caches user and saves token', () async {
    final user = User(id: '1', name: 'Test', email: 'test@test.com');
    final res = {'user': user, 'accessToken': 'token'};
    when(remote.login(any, any)).thenAnswer((_) async => res);
    when(local.cacheUser(any)).thenAnswer((_) async => null);
    when(local.saveAccessToken(any)).thenAnswer((_) async => null);
    final result = await repo.login('test@test.com', 'pass');
    expect(result, user);
    verify(local.cacheUser(user)).called(1);
    verify(local.saveAccessToken('token')).called(1);
  });

  test('getCurrentUser returns cached user', () async {
    final user = User(id: '2', name: 'Alice', email: 'alice@mail.com');
    when(local.getCachedUser()).thenAnswer((_) async => user);
    final result = await repo.getCurrentUser();
    expect(result, user);
  });
}
