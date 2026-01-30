import 'data/datasources/counter_local_data_source.dart';
import 'data/repositories/counter_repository_impl.dart';
import 'domain/repositories/counter_repository.dart';
import 'domain/usecases/get_counter.dart';
import 'domain/usecases/increment_counter.dart';
import 'presentation/state/counter_controller.dart';

import 'data/datasources/auth_local_data_source.dart';
import 'data/datasources/auth_remote_data_source.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/usecases/login_usecase.dart';
import 'domain/usecases/register_usecase.dart';
import 'domain/usecases/reset_password_usecase.dart';
import 'domain/usecases/get_current_user_usecase.dart';
import 'domain/usecases/social_login_usecase.dart';
import 'presentation/state/auth_controller.dart';

/// Very small manual DI container (no external packages).
class InjectionContainer {
  InjectionContainer._();

  static final InjectionContainer instance = InjectionContainer._();

  // Counter dependencies
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

  // Auth dependencies
  late final AuthLocalDataSource _authLocalDataSource =
      InMemoryAuthLocalDataSource();

  late final AuthRemoteDataSource _authRemoteDataSource =
      MockAuthRemoteDataSource();

  late final AuthRepository _authRepository = AuthRepositoryImpl(
    remoteDataSource: _authRemoteDataSource,
    localDataSource: _authLocalDataSource,
  );

  late final LoginUseCase _loginUseCase = LoginUseCase(_authRepository);
  late final RegisterUseCase _registerUseCase = RegisterUseCase(_authRepository);
  late final ResetPasswordUseCase _resetPasswordUseCase =
      ResetPasswordUseCase(_authRepository);
  late final GetCurrentUserUseCase _getCurrentUserUseCase =
      GetCurrentUserUseCase(_authRepository);
  late final SocialLoginUseCase _socialLoginUseCase =
      SocialLoginUseCase(_authRepository);

  AuthController buildAuthController() {
    return AuthController(
      loginUseCase: _loginUseCase,
      registerUseCase: _registerUseCase,
      resetPasswordUseCase: _resetPasswordUseCase,
      getCurrentUserUseCase: _getCurrentUserUseCase,
      socialLoginUseCase: _socialLoginUseCase,
    );
  }
}


