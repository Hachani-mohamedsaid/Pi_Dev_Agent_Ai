import 'package:flutter/foundation.dart';

import '../../domain/entities/user.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
<<<<<<< HEAD
=======
import '../../domain/usecases/confirm_reset_password_usecase.dart';
>>>>>>> c3cf2c9 ( Flutter project v1)
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/social_login_usecase.dart';
import '../../core/usecase/usecase.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required ResetPasswordUseCase resetPasswordUseCase,
<<<<<<< HEAD
=======
    required ConfirmResetPasswordUseCase confirmResetPasswordUseCase,
>>>>>>> c3cf2c9 ( Flutter project v1)
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required SocialLoginUseCase socialLoginUseCase,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _resetPasswordUseCase = resetPasswordUseCase,
<<<<<<< HEAD
=======
        _confirmResetPasswordUseCase = confirmResetPasswordUseCase,
>>>>>>> c3cf2c9 ( Flutter project v1)
        _getCurrentUserUseCase = getCurrentUserUseCase,
        _socialLoginUseCase = socialLoginUseCase;

  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;
<<<<<<< HEAD
=======
  final ConfirmResetPasswordUseCase _confirmResetPasswordUseCase;
>>>>>>> c3cf2c9 ( Flutter project v1)
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final SocialLoginUseCase _socialLoginUseCase;

  User? _currentUser;
  User? get currentUser => _currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool get isAuthenticated => _currentUser != null;

  Future<void> loadCurrentUser() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _getCurrentUserUseCase(const NoParams());
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _loginUseCase(LoginParams(
        email: email,
        password: password,
      ));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _registerUseCase(RegisterParams(
        name: name,
        email: email,
        password: password,
      ));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _resetPasswordUseCase(ResetPasswordParams(email: email));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

<<<<<<< HEAD
=======
  Future<bool> confirmResetPassword(String token, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _confirmResetPasswordUseCase(ConfirmResetPasswordParams(
        token: token,
        newPassword: newPassword,
      ));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

>>>>>>> c3cf2c9 ( Flutter project v1)
  Future<bool> loginWithSocial(SocialProvider provider) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _socialLoginUseCase(SocialLoginParams(
        provider: provider,
      ));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
