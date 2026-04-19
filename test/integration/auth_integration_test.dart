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
import 'package:pi_dev_agentia/domain/repositories/auth_repository.dart';

// --- Fakes ---
class FakeAuthRepository extends Mock implements AuthRepository {}
class FakeLoginUseCase extends Mock implements LoginUseCase {}
class FakeRegisterUseCase extends Mock implements RegisterUseCase {}
class FakeResetPasswordUseCase extends Mock implements ResetPasswordUseCase {}
class FakeResetPasswordConfirmUseCase extends Mock implements ResetPasswordConfirmUseCase {}
class FakeGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}
class FakeSocialLoginUseCase extends Mock implements SocialLoginUseCase {}
class FakeGetProfileUseCase extends Mock implements GetProfileUseCase {}
class FakeUpdateProfileUseCase extends Mock implements UpdateProfileUseCase {}
class FakeChangePasswordUseCase extends Mock implements ChangePasswordUseCase {}
class FakeRequestEmailVerificationUseCase extends Mock implements RequestEmailVerificationUseCase {}
class FakeConfirmEmailVerificationUseCase extends Mock implements ConfirmEmailVerificationUseCase {}

void main() {
  test('Integration: login via controller and repository', () async {
    final repo = FakeAuthRepository();
    final useCase = LoginUseCase(repo);
    final controller = AuthController(
      loginUseCase: useCase,
      registerUseCase: FakeRegisterUseCase(),
      resetPasswordUseCase: FakeResetPasswordUseCase(),
      resetPasswordConfirmUseCase: FakeResetPasswordConfirmUseCase(),
      getCurrentUserUseCase: FakeGetCurrentUserUseCase(),
      socialLoginUseCase: FakeSocialLoginUseCase(),
      getProfileUseCase: FakeGetProfileUseCase(),
      updateProfileUseCase: FakeUpdateProfileUseCase(),
      changePasswordUseCase: FakeChangePasswordUseCase(),
      requestEmailVerificationUseCase: FakeRequestEmailVerificationUseCase(),
      confirmEmailVerificationUseCase: FakeConfirmEmailVerificationUseCase(),
    );

    final user = User(id: '99', name: 'Integration', email: 'int@test.com');
    when(repo.login('int@test.com', 'pass')).thenAnswer((_) async => user);

    final result = await controller.login('int@test.com', 'pass');
    expect(result, isTrue);
    expect(controller.currentUser, user);
  });
}