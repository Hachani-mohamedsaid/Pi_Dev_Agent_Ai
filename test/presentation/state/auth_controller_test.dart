import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pi_dev_agentia/presentation/state/auth_controller.dart';
import 'package:pi_dev_agentia/domain/entities/user.dart';
import 'package:pi_dev_agentia/domain/usecases/login_usecase.dart';
import 'package:pi_dev_agentia/domain/usecases/register_usecase.dart';
import 'package:pi_dev_agentia/domain/usecases/reset_password_usecase.dart';
import 'package:pi_dev_agentia/domain/usecases/reset_password_confirm_usecase.dart';
import 'package:pi_dev_agentia/domain/usecases/get_current_user_usecase.dart';
import 'package:pi_dev_agentia/domain/usecases/social_login_usecase.dart';
import 'package:pi_dev_agentia/domain/usecases/get_profile_usecase.dart';
import 'package:pi_dev_agentia/domain/usecases/update_profile_usecase.dart';
import 'package:pi_dev_agentia/domain/usecases/change_password_usecase.dart';
import 'package:pi_dev_agentia/domain/usecases/request_email_verification_usecase.dart';
import 'package:pi_dev_agentia/domain/usecases/confirm_email_verification_usecase.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {
  @override
  Future<User> call(LoginParams params) =>
      super.noSuchMethod(
        Invocation.method(#call, [params]),
        returnValue: Future.value(User(id: '', name: '', email: '')),
        returnValueForMissingStub: Future.value(User(id: '', name: '', email: '')),
      ) as Future<User>;
}

class MockRegisterUseCase extends Mock implements RegisterUseCase {}
class MockResetPasswordUseCase extends Mock implements ResetPasswordUseCase {}
class MockResetPasswordConfirmUseCase extends Mock implements ResetPasswordConfirmUseCase {}
class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}
class MockSocialLoginUseCase extends Mock implements SocialLoginUseCase {}
class MockGetProfileUseCase extends Mock implements GetProfileUseCase {}
class MockUpdateProfileUseCase extends Mock implements UpdateProfileUseCase {}
class MockChangePasswordUseCase extends Mock implements ChangePasswordUseCase {}
class MockRequestEmailVerificationUseCase extends Mock implements RequestEmailVerificationUseCase {}
class MockConfirmEmailVerificationUseCase extends Mock implements ConfirmEmailVerificationUseCase {}

void main() {
  late AuthController controller;
  late MockLoginUseCase loginUseCase;
  late MockRegisterUseCase registerUseCase;
  late MockResetPasswordUseCase resetPasswordUseCase;
  late MockResetPasswordConfirmUseCase resetPasswordConfirmUseCase;
  late MockGetCurrentUserUseCase getCurrentUserUseCase;
  late MockSocialLoginUseCase socialLoginUseCase;
  late MockGetProfileUseCase getProfileUseCase;
  late MockUpdateProfileUseCase updateProfileUseCase;
  late MockChangePasswordUseCase changePasswordUseCase;
  late MockRequestEmailVerificationUseCase requestEmailVerificationUseCase;
  late MockConfirmEmailVerificationUseCase confirmEmailVerificationUseCase;

  setUp(() {
    loginUseCase = MockLoginUseCase();
    registerUseCase = MockRegisterUseCase();
    resetPasswordUseCase = MockResetPasswordUseCase();
    resetPasswordConfirmUseCase = MockResetPasswordConfirmUseCase();
    getCurrentUserUseCase = MockGetCurrentUserUseCase();
    socialLoginUseCase = MockSocialLoginUseCase();
    getProfileUseCase = MockGetProfileUseCase();
    updateProfileUseCase = MockUpdateProfileUseCase();
    changePasswordUseCase = MockChangePasswordUseCase();
    requestEmailVerificationUseCase = MockRequestEmailVerificationUseCase();
    confirmEmailVerificationUseCase = MockConfirmEmailVerificationUseCase();
    controller = AuthController(
      loginUseCase: loginUseCase,
      registerUseCase: registerUseCase,
      resetPasswordUseCase: resetPasswordUseCase,
      resetPasswordConfirmUseCase: resetPasswordConfirmUseCase,
      getCurrentUserUseCase: getCurrentUserUseCase,
      socialLoginUseCase: socialLoginUseCase,
      getProfileUseCase: getProfileUseCase,
      updateProfileUseCase: updateProfileUseCase,
      changePasswordUseCase: changePasswordUseCase,
      requestEmailVerificationUseCase: requestEmailVerificationUseCase,
      confirmEmailVerificationUseCase: confirmEmailVerificationUseCase,
    );
  });

  test('initial state is correct', () {
    expect(controller.currentUser, isNull);
    expect(controller.isLoading, isFalse);
    expect(controller.error, isNull);
    expect(controller.isAuthenticated, isFalse);
  });

  test('login success updates user', () async {
    final user = User(id: '1', name: 'Test', email: 'test@test.com');
    when(loginUseCase.call(
      LoginParams(email: 'test@test.com', password: 'pass'),
    )).thenAnswer((_) async => user);

    final result = await controller.login('test@test.com', 'pass');
    expect(result, isTrue);
    expect(controller.currentUser, user);
    expect(controller.isAuthenticated, isTrue);
    expect(controller.error, isNull);
  });

  test('login failure sets error', () async {
    when(loginUseCase.call(
      LoginParams(email: 'test@test.com', password: 'pass'),
    )).thenThrow(Exception('fail'));

    final result = await controller.login('test@test.com', 'pass');
    expect(result, isFalse);
    expect(controller.currentUser, isNull);
    expect(controller.isAuthenticated, isFalse);
    expect(controller.error, isNotNull);
  });

  testWidgets('login triggers loading state and notifies listeners', (
    tester,
  ) async {
    final user = User(id: '1', name: 'Test', email: 'test@test.com');
    when(loginUseCase.call(
      LoginParams(email: 'test@test.com', password: 'pass'),
    )).thenAnswer((_) async => user);

    final states = <bool>[];
    controller.addListener(() {
      states.add(controller.isLoading);
    });

    // ignore: unawaited_futures
    controller.login('test@test.com', 'pass');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(states, contains(true));
    expect(states.last, isFalse);
  });

  testWidgets('AuthController notifies listeners on login', (tester) async {
    final user = User(id: '2', name: 'Widget', email: 'widget@test.com');
    when(loginUseCase.call(
      LoginParams(email: 'widget@test.com', password: 'pass'),
    )).thenAnswer((_) async => user);

    int notifyCount = 0;
    controller.addListener(() {
      notifyCount++;
    });

    await controller.login('widget@test.com', 'pass');
    await tester.pump(const Duration(milliseconds: 100));

    expect(notifyCount, greaterThan(0));
    expect(controller.currentUser, user);
  });
}