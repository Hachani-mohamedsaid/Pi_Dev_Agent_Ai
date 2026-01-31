import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import 'google_icon.dart';
import 'google_sign_in_button_dom_helper_stub.dart'
    if (dart.library.html) 'google_sign_in_button_dom_helper_web.dart' as dom_helper;

/// Bouton Google Sign-In pour le web : même design que [SocialButton] (bordure cyan, fond sombre, "Google Account")
/// avec le bouton natif en overlay agrandi via [FittedBox] pour que toute la zone soit cliquable.
/// Écoute [authenticationEvents] pour récupérer l'idToken (Google Sign-In 7.x).
class WebGoogleSignInButton extends StatefulWidget {
  const WebGoogleSignInButton({
    super.key,
    required this.onIdToken,
    this.onPressed,
  });

  final void Function(String idToken) onIdToken;
  final VoidCallback? onPressed;

  @override
  State<WebGoogleSignInButton> createState() => _WebGoogleSignInButtonState();
}

class _WebGoogleSignInButtonState extends State<WebGoogleSignInButton> {
  StreamSubscription<GoogleSignInAuthenticationEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = GoogleSignIn.instance.authenticationEvents.listen(
      _onAuthenticationEvent,
      onError: (Object err, StackTrace? st) {
        debugPrint('Google Sign-In stream error: $err');
      },
    );
    // Étendre le bouton Google dans le DOM pour que toute la zone soit cliquable
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 300), () {
        dom_helper.expandGoogleSignInButtonInDom();
      });
      Future<void>.delayed(const Duration(milliseconds: 1200), () {
        dom_helper.expandGoogleSignInButtonInDom();
      });
    });
  }

  void _onAuthenticationEvent(GoogleSignInAuthenticationEvent event) {
    if (event is GoogleSignInAuthenticationEventSignIn) {
      final auth = event.user.authentication;
      final idToken = auth.idToken;
      if (idToken != null && idToken.isNotEmpty) {
        widget.onIdToken(idToken);
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final height = isMobile ? 52.0 : 56.0;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Design aligné sur SocialButton : bordure cyan, fond sombre, "Google Account" (ignoré au clic)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                border: Border.all(
                  color: AppColors.borderCyan,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: isMobile ? 20 : 22,
                    height: isMobile ? 20 : 22,
                    child: GoogleIcon(size: isMobile ? 20 : 22),
                  ),
                  SizedBox(width: isMobile ? 6 : 10),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Google Account',
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: isMobile ? 13 : 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
          // Bouton natif invisible en pleine largeur/hauteur ; expandGoogleSignInButtonInDom() étend le conteneur dans le DOM
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: SizedBox.expand(
                child: renderButton(
                  configuration: GSIButtonConfiguration(
                    size: GSIButtonSize.medium,
                    theme: GSIButtonTheme.filledBlack,
                    type: GSIButtonType.standard,
                    text: GSIButtonText.signinWith,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
