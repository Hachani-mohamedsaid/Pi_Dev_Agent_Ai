import 'data/datasources/counter_local_data_source.dart';
import 'data/repositories/counter_repository_impl.dart';
import 'domain/repositories/counter_repository.dart';
import 'domain/usecases/get_counter.dart';
import 'domain/usecases/increment_counter.dart';
import 'presentation/state/counter_controller.dart';

import 'data/datasources/auth_local_data_source.dart';
import 'data/datasources/auth_remote_data_source.dart';
import 'data/datasources/api_auth_remote_data_source.dart';
import 'data/datasources/chat_remote_data_source.dart';
import 'core/config/google_oauth_config.dart';
import 'data/datasources/social_auth_credentials_provider.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/services/social_auth_credentials_provider.dart' as domain;
import 'domain/repositories/auth_repository.dart';
import 'domain/usecases/login_usecase.dart';
import 'domain/usecases/register_usecase.dart';
import 'domain/usecases/reset_password_usecase.dart';
import 'domain/usecases/get_current_user_usecase.dart';
import 'domain/usecases/social_login_usecase.dart';
import 'domain/usecases/get_profile_usecase.dart';
import 'domain/usecases/update_profile_usecase.dart';
import 'domain/usecases/reset_password_confirm_usecase.dart';
import 'domain/usecases/change_password_usecase.dart';
import 'domain/usecases/request_email_verification_usecase.dart';
import 'domain/usecases/confirm_email_verification_usecase.dart';
import 'presentation/state/auth_controller.dart';

// N8N Chat
import 'data/services/n8n_chat_service.dart';
import 'presentation/state/chat_provider.dart';

/// Very small manual DI container (no external packages).
class InjectionContainer {
  InjectionContainer._();

  static final InjectionContainer instance = InjectionContainer._();

  // Counter dependencies
  late final CounterLocalDataSource _counterLocalDataSource =
      InMemoryCounterLocalDataSource();

  late final CounterRepository _counterRepository = CounterRepositoryImpl(
    _counterLocalDataSource,
  );

  late final GetCounter _getCounter = GetCounter(_counterRepository);
  late final IncrementCounter _incrementCounter = IncrementCounter(
    _counterRepository,
  );

  CounterController buildCounterController() {
    return CounterController(
      getCounter: _getCounter,
      incrementCounter: _incrementCounter,
    );
  }

  // Auth dependencies – SharedPreferences pour que token et user survivent au refresh / redémarrage
  late final AuthLocalDataSource _authLocalDataSource =
      SharedPreferencesAuthLocalDataSource();

  late final AuthRemoteDataSource _authRemoteDataSource =
      ApiAuthRemoteDataSource(); // ou MockAuthRemoteDataSource() pour tests sans backend

  late final domain.SocialAuthCredentialsProvider _socialCredentialsProvider =
      DefaultSocialAuthCredentialsProvider(webClientId: googleOAuthWebClientId);

  late final AuthRepository _authRepository = AuthRepositoryImpl(
    remoteDataSource: _authRemoteDataSource,
    localDataSource: _authLocalDataSource,
  );

  late final LoginUseCase _loginUseCase = LoginUseCase(_authRepository);
  late final RegisterUseCase _registerUseCase = RegisterUseCase(
    _authRepository,
  );
  late final ResetPasswordUseCase _resetPasswordUseCase = ResetPasswordUseCase(
    _authRepository,
  );
  late final ResetPasswordConfirmUseCase _resetPasswordConfirmUseCase =
      ResetPasswordConfirmUseCase(_authRepository);
  late final GetCurrentUserUseCase _getCurrentUserUseCase =
      GetCurrentUserUseCase(_authRepository);
  late final SocialLoginUseCase _socialLoginUseCase = SocialLoginUseCase(
    _authRepository,
    _socialCredentialsProvider,
  );
  late final GetProfileUseCase _getProfileUseCase = GetProfileUseCase(
    _authRepository,
  );
  late final UpdateProfileUseCase _updateProfileUseCase = UpdateProfileUseCase(
    _authRepository,
  );
  late final ChangePasswordUseCase _changePasswordUseCase =
      ChangePasswordUseCase(_authRepository);
  late final RequestEmailVerificationUseCase _requestEmailVerificationUseCase =
      RequestEmailVerificationUseCase(_authRepository);
  late final ConfirmEmailVerificationUseCase _confirmEmailVerificationUseCase =
      ConfirmEmailVerificationUseCase(_authRepository);

  ChatRemoteDataSource buildChatDataSource() =>
      ApiChatRemoteDataSource(authLocalDataSource: _authLocalDataSource);

  AuthController? _authController;

  /// Une seule instance d'AuthController partagée par toutes les routes (login, profile, edit-profile, etc.)
  /// pour que currentUser et currentProfile soient conservés à la navigation.
  AuthController buildAuthController() {
    _authController ??= AuthController(
      loginUseCase: _loginUseCase,
      registerUseCase: _registerUseCase,
      resetPasswordUseCase: _resetPasswordUseCase,
      resetPasswordConfirmUseCase: _resetPasswordConfirmUseCase,
      getCurrentUserUseCase: _getCurrentUserUseCase,
      socialLoginUseCase: _socialLoginUseCase,
      getProfileUseCase: _getProfileUseCase,
      updateProfileUseCase: _updateProfileUseCase,
      changePasswordUseCase: _changePasswordUseCase,
      requestEmailVerificationUseCase: _requestEmailVerificationUseCase,
      confirmEmailVerificationUseCase: _confirmEmailVerificationUseCase,
    );
    return _authController!;
  }

  // N8N Chat dependencies
  late final N8nChatService _n8nChatService = N8nChatService(
    webhookUrl: 'https://n8n-production-1e13.up.railway.app/webhook/2429d011-049b-424b-9708-bf415bc682e1',
  );

  ChatProvider? _chatProvider;

  /// Build ChatProvider for n8n webhook integration.
  /// Singleton to maintain conversation history across navigation.
  ChatProvider buildChatProvider() {
    _chatProvider ??= ChatProvider(chatService: _n8nChatService);
    return _chatProvider!;
  }

  /// Get the n8n chat service directly if needed
  N8nChatService getN8nChatService() => _n8nChatService;
}
