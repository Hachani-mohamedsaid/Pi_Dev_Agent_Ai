import 'package:flutter/material.dart';

import '../../core/utils/responsive.dart';
import 'google_icon.dart';
import 'social_button.dart';

/// Stub pour mobile : affiche le SocialButton classique (signIn()).
/// Sur le web, on utilise [WebGoogleSignInButton] avec renderButton + authenticationEvents.
class WebGoogleSignInButton extends StatelessWidget {
  const WebGoogleSignInButton({
    super.key,
    required this.onIdToken,
    this.onPressed,
  });

  /// Ignoré sur mobile (on utilise onPressed + signIn()).
  final void Function(String idToken) onIdToken;

  /// Appelé au clic sur le bouton (connexion via signIn()).
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    return SocialButton(
      icon: GoogleIcon(size: isMobile ? 20 : 22),
      text: 'Google Account',
      onPressed: onPressed ?? () {},
    );
  }
}
