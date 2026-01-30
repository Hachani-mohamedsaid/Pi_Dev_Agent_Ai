import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../data/models/profile_model.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/usecases/reset_password_confirm_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/social_login_usecase.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/change_password_usecase.dart';
import '../../core/usecase/usecase.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required ResetPasswordUseCase resetPasswordUseCase,
    required ResetPasswordConfirmUseCase resetPasswordConfirmUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required SocialLoginUseCase socialLoginUseCase,
    required GetProfileUseCase getProfileUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
    required ChangePasswordUseCase changePasswordUseCase,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _resetPasswordUseCase = resetPasswordUseCase,
        _resetPasswordConfirmUseCase = resetPasswordConfirmUseCase,
        _getCurrentUserUseCase = getCurrentUserUseCase,
        _socialLoginUseCase = socialLoginUseCase,
        _getProfileUseCase = getProfileUseCase,
        _updateProfileUseCase = updateProfileUseCase,
        _changePasswordUseCase = changePasswordUseCase;

  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;
  final ResetPasswordConfirmUseCase _resetPasswordConfirmUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final SocialLoginUseCase _socialLoginUseCase;
  final GetProfileUseCase _getProfileUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final ChangePasswordUseCase _changePasswordUseCase;

  User? _currentUser;
  User? get currentUser => _currentUser;

  ProfileModel? _currentProfile;
  ProfileModel? get currentProfile => _currentProfile;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool get isAuthenticated => _currentUser != null;

  /// Évite "notification during build" quand la page appelle loadCurrentUser/loadProfile dans initState.
  void _safeNotifyListeners() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) notifyListeners();
    });
  }

  Future<void> loadCurrentUser() async {
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      _currentUser = await _getCurrentUserUseCase(const NoParams());
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      _currentUser = await _loginUseCase(LoginParams(
        email: email,
        password: password,
      ));
      _isLoading = false;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _safeNotifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      _currentUser = await _registerUseCase(RegisterParams(
        name: name,
        email: email,
        password: password,
      ));
      _isLoading = false;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _safeNotifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      await _resetPasswordUseCase(ResetPasswordParams(email: email));
      _isLoading = false;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _safeNotifyListeners();
      return false;
    }
  }

  /// POST /auth/reset-password/confirm – définit le nouveau mot de passe avec le token du lien email.
  Future<bool> setNewPassword({required String token, required String newPassword}) async {
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      await _resetPasswordConfirmUseCase(ResetPasswordConfirmParams(
        token: token,
        newPassword: newPassword,
      ));
      _isLoading = false;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _safeNotifyListeners();
      return false;
    }
  }

  Future<bool> loginWithSocial(SocialProvider provider) async {
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      _currentUser = await _socialLoginUseCase(SocialLoginParams(
        provider: provider,
      ));
      _isLoading = false;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _safeNotifyListeners();
      return false;
    }
  }

  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      final profile = await _getProfileUseCase(const NoParams());
      _currentProfile = profile is ProfileModel ? profile : null;
    } catch (e) {
      _error = e.toString();
      _currentProfile = null;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? avatarUrl,
    String? role,
    String? location,
    String? phone,
    String? birthDate,
    String? bio,
    int? conversationsCount,
    int? hoursSaved,
  }) async {
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      await _updateProfileUseCase(UpdateProfileParams(
        name: name,
        avatarUrl: avatarUrl,
        role: role,
        location: location,
        phone: phone,
        birthDate: birthDate,
        bio: bio,
        conversationsCount: conversationsCount,
        hoursSaved: hoursSaved,
      ));
      await loadProfile();
      _isLoading = false;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _safeNotifyListeners();
      return false;
    }
  }

  /// POST /auth/change-password – changer le mot de passe (utilisateur connecté).
  Future<bool> changePassword({required String currentPassword, required String newPassword}) async {
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      await _changePasswordUseCase(ChangePasswordParams(
        currentPassword: currentPassword,
        newPassword: newPassword,
      ));
      _isLoading = false;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _safeNotifyListeners();
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    _currentProfile = null;
    _error = null;
    _isLoading = false;
    _safeNotifyListeners();
  }

  void clearError() {
    _error = null;
    _safeNotifyListeners();
  }
}
