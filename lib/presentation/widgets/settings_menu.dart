import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../state/auth_controller.dart';

class SettingsMenu extends StatefulWidget {
  final AuthController controller;

  const SettingsMenu({
    super.key,
    required this.controller,
  });

  @override
  State<SettingsMenu> createState() => _SettingsMenuState();
}

class _SettingsMenuState extends State<SettingsMenu> {
  bool _darkMode = true;
  OverlayEntry? _overlayEntry;

  void _handleLogout() {
    _hideMenu();
    widget.controller.logout();
    context.go('/login');
  }

  void _handleLanguageChange() {
    _hideMenu();
    context.push('/language');
  }

  void _handleEditProfile() {
    _hideMenu();
    context.push('/edit-profile');
  }

  void _handleNotifications() {
    _hideMenu();
    context.push('/notifications');
  }

  void _handlePrivacySecurity() {
    _hideMenu();
    context.push('/privacy-security');
  }

  void _showMenu() {
    final overlay = Overlay.of(context);
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => _SettingsMenuOverlay(
        position: Offset(offset.dx, offset.dy + size.height + 8),
        onDismiss: _hideMenu,
        darkMode: _darkMode,
        onDarkModeChanged: (value) {
          setState(() {
            _darkMode = value;
          });
        },
        onEditProfile: _handleEditProfile,
        onLanguageChange: _handleLanguageChange,
        onNotifications: _handleNotifications,
        onPrivacySecurity: _handlePrivacySecurity,
        onLogout: _handleLogout,
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _hideMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _hideMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return GestureDetector(
      onTap: () {
        if (_overlayEntry == null) {
          _showMenu();
        } else {
          _hideMenu();
        }
      },
      child: Container(
        padding: EdgeInsets.all(isMobile ? 10 : 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryLight.withOpacity(0.6),
              AppColors.primaryDarker.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
          border: Border.all(
            color: AppColors.cyan500.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Icon(
              Icons.settings,
              color: AppColors.cyan400,
              size: isMobile ? 20 : 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsMenuOverlay extends StatelessWidget {
  final Offset position;
  final VoidCallback onDismiss;
  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final VoidCallback onEditProfile;
  final VoidCallback onLanguageChange;
  final VoidCallback onNotifications;
  final VoidCallback onPrivacySecurity;
  final VoidCallback onLogout;

  const _SettingsMenuOverlay({
    required this.position,
    required this.onDismiss,
    required this.darkMode,
    required this.onDarkModeChanged,
    required this.onEditProfile,
    required this.onLanguageChange,
    required this.onNotifications,
    required this.onPrivacySecurity,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final menuWidth = isMobile ? 280.0 : 320.0;
    final rightPadding = isMobile ? 16.0 : 24.0;
    final leftPosition = screenWidth - menuWidth - rightPadding;

    return GestureDetector(
      onTap: onDismiss,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned(
              left: leftPosition,
              top: position.dy,
              child: GestureDetector(
                onTap: () {}, // Prevent dismissing when tapping menu
                child: _SettingsMenuContent(
                  isMobile: isMobile,
                  darkMode: darkMode,
                  onDarkModeChanged: onDarkModeChanged,
                  onEditProfile: onEditProfile,
                  onLanguageChange: onLanguageChange,
                  onNotifications: onNotifications,
                  onPrivacySecurity: onPrivacySecurity,
                  onLogout: onLogout,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsMenuContent extends StatelessWidget {
  final bool isMobile;
  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final VoidCallback onEditProfile;
  final VoidCallback onLanguageChange;
  final VoidCallback onNotifications;
  final VoidCallback onPrivacySecurity;
  final VoidCallback onLogout;

  const _SettingsMenuContent({
    required this.isMobile,
    required this.darkMode,
    required this.onDarkModeChanged,
    required this.onEditProfile,
    required this.onLanguageChange,
    required this.onNotifications,
    required this.onPrivacySecurity,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isMobile ? 280 : 320,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryLight.withOpacity(0.95),
            AppColors.primaryDarker.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        border: Border.all(
          color: AppColors.cyan500.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 20,
                  vertical: isMobile ? 12 : 16,
                ),
                child: Row(
                  children: [
                    Text(
                      'SETTINGS',
                      style: TextStyle(
                        fontSize: isMobile ? 10 : 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textCyan200.withOpacity(0.7),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                color: AppColors.cyan500.withOpacity(0.2),
                height: 1,
                thickness: 1,
              ),

              // Dark Mode Toggle
              _SettingsMenuItem(
                icon: darkMode ? Icons.dark_mode : Icons.light_mode,
                label: 'Dark Mode',
                isMobile: isMobile,
                isToggle: true,
                toggleValue: darkMode,
                onToggle: onDarkModeChanged,
              ),

              Divider(
                color: AppColors.cyan500.withOpacity(0.2),
                height: 1,
                thickness: 1,
              ),

              // Edit Profile
              _SettingsMenuItem(
                icon: Icons.person,
                label: 'Edit Profile',
                isMobile: isMobile,
                onTap: onEditProfile,
              ),

              // Change Language
              _SettingsMenuItem(
                icon: Icons.language,
                label: 'Change Language',
                isMobile: isMobile,
                onTap: onLanguageChange,
              ),

              // Notifications
              _SettingsMenuItem(
                icon: Icons.notifications,
                label: 'Notifications',
                isMobile: isMobile,
                onTap: onNotifications,
              ),

              // Privacy & Security
              _SettingsMenuItem(
                icon: Icons.security,
                label: 'Privacy & Security',
                isMobile: isMobile,
                onTap: onPrivacySecurity,
              ),

              Divider(
                color: AppColors.cyan500.withOpacity(0.2),
                height: 1,
                thickness: 1,
              ),

              // Help & Support
              _SettingsMenuItem(
                icon: Icons.help_outline,
                label: 'Help & Support',
                isMobile: isMobile,
                onTap: () {},
              ),

              Divider(
                color: AppColors.cyan500.withOpacity(0.2),
                height: 1,
                thickness: 1,
              ),

              // Logout
              _SettingsMenuItem(
                icon: Icons.logout,
                label: 'Log Out',
                isMobile: isMobile,
                isDestructive: true,
                onTap: onLogout,
              ),

              SizedBox(height: isMobile ? 8 : 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsMenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isMobile;
  final VoidCallback? onTap;
  final bool isDestructive;
  final bool isToggle;
  final bool? toggleValue;
  final ValueChanged<bool>? onToggle;

  const _SettingsMenuItem({
    required this.icon,
    required this.label,
    required this.isMobile,
    this.onTap,
    this.isDestructive = false,
    this.isToggle = false,
    this.toggleValue,
    this.onToggle,
  });

  @override
  State<_SettingsMenuItem> createState() => _SettingsMenuItemState();
}

class _SettingsMenuItemState extends State<_SettingsMenuItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final iconColor = widget.isDestructive
        ? Colors.red.shade400
        : AppColors.cyan400;
    final textColor = widget.isDestructive
        ? Colors.red.shade400
        : AppColors.textWhite;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (widget.onTap != null) {
          widget.onTap!();
        }
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 20,
          vertical: isMobile ? 12 : 14,
        ),
        decoration: BoxDecoration(
          color: _isPressed
              ? AppColors.cyan500.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              widget.icon,
              size: isMobile ? 16 : 18,
              color: iconColor,
            ),
            SizedBox(width: isMobile ? 12 : 16),
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 15,
                  color: textColor,
                ),
              ),
            ),
            if (widget.isToggle)
              Switch(
                value: widget.toggleValue ?? false,
                onChanged: widget.onToggle,
                activeColor: AppColors.cyan500,
              )
            else if (!widget.isDestructive)
              Icon(
                Icons.chevron_right,
                size: isMobile ? 16 : 18,
                color: AppColors.cyan400.withOpacity(0.5),
              ),
          ],
        ),
      ),
    );
  }
}
