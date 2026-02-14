import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/l10n/app_strings.dart';

class NavigationBarWidget extends StatelessWidget {
  final String currentPath;

  const NavigationBarWidget({
    super.key,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isHomeActive = currentPath == '/home';
    final isProfileActive = currentPath == '/profile';
    final isVoiceActive = currentPath == '/voice-assistant';
    final isFinanceActive = currentPath == '/finance';
    final isWorkProposalsActive = currentPath == '/work-proposals';
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = isMobile ? 16.0 : 24.0;

    return Container(
      padding: EdgeInsets.only(
        bottom: isMobile ? 16 : 20,
        top: isMobile ? 12 : 16,
        left: horizontalPadding,
        right: horizontalPadding,
      ),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isMobile ? screenWidth - (horizontalPadding * 2) : 400,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: isMobile ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryDark.withOpacity(0.6),
            borderRadius: BorderRadius.circular(isMobile ? 30 : 35),
            border: Border.all(
              color: AppColors.cyan500.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyan500.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isMobile ? 30 : 35),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: _NavButton(
                      icon: Icons.home,
                      label: AppStrings.tr(context, 'home'),
                      isActive: isHomeActive,
                      onTap: () => context.go('/home'),
                      isMobile: isMobile,
                    ),
                  ),
                  SizedBox(width: isMobile ? 8 : 12),
                  Flexible(
                    child: _NavButton(
                      icon: LucideIcons.dollarSign,
                      label: 'Finance',
                      isActive: isFinanceActive,
                      onTap: () => context.go('/finance'),
                      isMobile: isMobile,
                      activeGradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF10B981).withOpacity(0.3),
                          const Color(0xFF06B6D4).withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: isMobile ? 8 : 12),
                  Flexible(
                    child: _NavButton(
                      icon: Icons.mic,
                      label: AppStrings.tr(context, 'voice'),
                      isActive: isVoiceActive,
                      onTap: () => context.go('/voice-assistant'),
                      isMobile: isMobile,
                      activeGradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF9333EA).withOpacity(0.3),
                          const Color(0xFFEC4899).withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: isMobile ? 8 : 12),
                  Flexible(
                    child: _NavButton(
                      icon: LucideIcons.briefcase,
                      label: 'Propositions',
                      isActive: isWorkProposalsActive,
                      onTap: () => context.go('/work-proposals'),
                      isMobile: isMobile,
                      activeGradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF10B981).withOpacity(0.3),
                          const Color(0xFF059669).withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: isMobile ? 8 : 12),
                  Flexible(
                    child: _NavButton(
                      icon: Icons.person,
                      label: AppStrings.tr(context, 'profile'),
                      isActive: isProfileActive,
                      onTap: () => context.go('/profile'),
                      isMobile: isMobile,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isMobile;
  final LinearGradient? activeGradient;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.isMobile,
    this.activeGradient,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: widget.isActive ? 1.0 : (_isPressed ? 0.95 : 1.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isMobile ? 12 : 16,
                  vertical: widget.isMobile ? 8 : 10,
                ),
                decoration: BoxDecoration(
                  gradient: widget.isActive
                      ? (widget.activeGradient ??
                          LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.cyan500.withOpacity(0.3),
                              AppColors.blue500.withOpacity(0.3),
                            ],
                          ))
                      : null,
                  color: widget.isActive ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(widget.isMobile ? 12 : 16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.icon,
                      size: widget.isMobile ? 20 : 22,
                      color: widget.isActive
                          ? AppColors.cyan400
                          : AppColors.textCyan200.withOpacity(0.5),
                    ),
                    if (widget.isActive) ...[
                      SizedBox(height: widget.isMobile ? 4 : 6),
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: widget.isMobile ? 10 : 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.cyan400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
