import 'package:flutter/material.dart';

/// AVA / Meeting Setup — dark + gold palette (Page 2).
class AvaColors {
  AvaColors._();

  static const Color bg = Color(0xFF0a0f18);
  static const Color card = Color(0xFF141c26);
  static const Color border = Color(0xFF1e293b);
  static const Color border2 = Color(0xFF334155);
  static const Color gold = Color(0xFFD4AF37);
  /// Orb radial gradient stops (lighter → base → deeper gold).
  static const Color gold2 = Color(0xFFF0D78C);
  static const Color gold3 = Color(0xFFB8860B);
  static const Color text = Color(0xFFF8FAFC);
  static const Color muted = Color(0xFF94A3B8);
  static const Color faint = Color(0xFF64748B);
  static const Color blue = Color(0xFF38BDF8);
  static const Color amber = Color(0xFFF59E0B);
  static const Color green = Color(0xFF22C55E);
  static const Color red = Color(0xFFEF4444);
}

class AvaText {
  AvaText._();

  static const TextStyle label = TextStyle(
    fontSize: 10,
    letterSpacing: 1.6,
    fontWeight: FontWeight.w600,
    color: AvaColors.muted,
  );

  static const TextStyle display = TextStyle(
    fontFamily: 'Georgia',
    fontSize: 26,
    height: 1.15,
    fontWeight: FontWeight.w600,
    color: AvaColors.text,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    height: 1.45,
    color: AvaColors.text,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AvaColors.muted,
  );
}

Widget avaAvatar({double size = 22}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: AvaColors.gold.withValues(alpha: 0.5)),
      color: AvaColors.card,
    ),
    child: Center(
      child: Text(
        'A',
        style: TextStyle(
          fontSize: size * 0.45,
          fontWeight: FontWeight.w800,
          color: AvaColors.gold,
        ),
      ),
    ),
  );
}

/// Gold primary button; [onPressed] null shows loading.
Widget avaGoldBtn(
  String label,
  VoidCallback? onPressed, {
  bool loading = false,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: loading ? null : onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: loading
                ? [AvaColors.gold.withValues(alpha: 0.5), AvaColors.gold.withValues(alpha: 0.4)]
                : const [Color(0xFFE8C547), AvaColors.gold],
          ),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF0a0f18),
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0a0f18),
                  ),
                ),
        ),
      ),
    ),
  );
}

/// Overrides the app-wide cyan [ColorScheme] so AVA surfaces match
/// [MeetingSetupScreen] / briefing (no blue tint on scaffold or inputs).
ThemeData themeForAvaFlow(BuildContext context) {
  final base = Theme.of(context);
  final cs = base.colorScheme;
  return base.copyWith(
    scaffoldBackgroundColor: AvaColors.bg,
    canvasColor: AvaColors.bg,
    colorScheme: cs.copyWith(
      surface: AvaColors.card,
      onSurface: AvaColors.text,
      primary: AvaColors.gold,
      onPrimary: AvaColors.bg,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AvaColors.bg,
      foregroundColor: AvaColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontFamily: 'Georgia',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AvaColors.text,
      ),
    ),
    dividerTheme: const DividerThemeData(color: AvaColors.border),
    iconTheme: const IconThemeData(color: AvaColors.muted),
  );
}
