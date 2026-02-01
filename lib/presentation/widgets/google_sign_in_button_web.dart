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
  bool _isPressed = false;

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
      // Multiple delays to ensure the button is rendered and expanded
      Future<void>.delayed(const Duration(milliseconds: 100), () {
        dom_helper.expandGoogleSignInButtonInDom();
      });
      Future<void>.delayed(const Duration(milliseconds: 500), () {
        dom_helper.expandGoogleSignInButtonInDom();
      });
      Future<void>.delayed(const Duration(milliseconds: 1000), () {
        dom_helper.expandGoogleSignInButtonInDom();
      });
      Future<void>.delayed(const Duration(milliseconds: 2000), () {
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
        clipBehavior: Clip.none,
        children: [
          // Visual design matching SocialButton exactly: cyan border, dark background, "Google Account"
          // This provides the visual appearance with press state
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: double.infinity,
            height: height,
            decoration: BoxDecoration(
              color: _isPressed 
                  ? AppColors.backgroundDark.withOpacity(0.8)
                  : AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
              border: Border.all(
                color: _isPressed
                    ? AppColors.cyan400
                    : AppColors.borderCyan,
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
          // Native Google button invisible overlay - expandGoogleSignInButtonInDom() makes it fill the container
          // This handles the actual Google Sign-In and must be on top to receive clicks
          Positioned.fill(
            child: Listener(
              onPointerDown: (_) {
                setState(() => _isPressed = true);
              },
              onPointerUp: (_) {
                setState(() => _isPressed = false);
              },
              onPointerCancel: (_) {
                setState(() => _isPressed = false);
              },
              behavior: HitTestBehavior.translucent,
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
          ),
        ],
      ),
    );
  }
}
