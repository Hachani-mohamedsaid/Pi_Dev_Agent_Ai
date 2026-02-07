import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Illustration animée pour l'intro - supporte Lottie (.json) et GIF (.gif).
/// Placez votre fichier dans assets/lottie/ ou assets/images/ selon le format.
class IntroIllustration extends StatelessWidget {
  const IntroIllustration({
    super.key,
    required this.assetPath,
    this.size = 200,
  });

  /// Chemin vers l'asset: assets/lottie/xxx.json (Lottie) ou assets/images/xxx.gif (GIF)
  final String assetPath;
  final double size;

  bool get _isLottie => assetPath.toLowerCase().endsWith('.json');
  bool get _isGif => assetPath.toLowerCase().endsWith('.gif');

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: _isLottie
            ? _buildLottie()
            : _isGif
                ? _buildGif()
                : _buildFallback(),
      ),
    );
  }

  Widget _buildLottie() {
    return Lottie.asset(
      assetPath,
      fit: BoxFit.contain,
      repeat: true,
      width: size,
      height: size,
      animate: true,
      errorBuilder: (context, error, stackTrace) => _buildFallback(),
    );
  }

  Widget _buildGif() {
    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace) => _buildFallback(),
    );
  }

  Widget _buildFallback() {
    return Icon(
      Icons.smart_toy_rounded,
      size: size * 0.6,
      color: Colors.white.withOpacity(0.6),
    );
  }
}
