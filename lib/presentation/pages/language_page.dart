import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/services/locale_service.dart';
import 'package:pi_dev_agentia/generated/l10n.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  late String _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = LocaleService.instance.languageCode;
  }

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'nativeName': 'English', 'flag': '🇺🇸'},
    {'code': 'fr', 'name': 'French', 'nativeName': 'Français', 'flag': '🇫🇷'},
    {'code': 'ar', 'name': 'Arabic', 'nativeName': 'العربية', 'flag': '🇸🇦'},
  ];

  Future<void> _handleLanguageSelect(String code) async {
    setState(() {
      _selectedLanguage = code;
    });
    await LocaleService.instance.setLocale(code);
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? 24.0 : 32.0;
    final brightness = Theme.of(context).brightness;
    final isLight = brightness == Brightness.light;

    // Dégradé adaptatif
    final BoxDecoration backgroundDecoration = isLight
        ? const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8FBFF), Color(0xFFE6F3FB)],
            ),
          )
        : const BoxDecoration(gradient: AppColors.primaryGradient);

    Color getTextPrimary() =>
        isLight ? const Color(0xFF1A3A52) : AppColors.textWhite;
    Color getTextSecondary() => isLight
        ? const Color(0xFF4B647A)
        : AppColors.textCyan200.withOpacity(0.7);
    Color getCardBg(bool selected) => isLight
        ? (selected ? const Color(0xFFD6F6FF) : Colors.white.withOpacity(0.85))
        : (selected
              ? AppColors.cyan500.withOpacity(0.2)
              : AppColors.primaryLight.withOpacity(0.4));
    Color getCardBorder(bool selected) => isLight
        ? (selected ? const Color(0xFF22D3EE) : const Color(0xFFE0F2FE))
        : (selected
              ? AppColors.cyan500.withOpacity(0.5)
              : AppColors.cyan500.withOpacity(0.1));
    Color getCheckColor() =>
        isLight ? const Color(0xFF06B6D4) : AppColors.cyan400;
    Color getIconColor() =>
        isLight ? const Color(0xFF06B6D4) : AppColors.cyan400;

    return Scaffold(
      body: Container(
        decoration: backgroundDecoration,
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: padding,
              right: padding,
              top: padding,
              bottom: padding + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            padding: EdgeInsets.all(isMobile ? 8 : 10),
                            decoration: BoxDecoration(
                              color: isLight ? Colors.white : null,
                              gradient: isLight
                                  ? null
                                  : LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.primaryLight.withOpacity(0.6),
                                        AppColors.primaryDarker.withOpacity(
                                          0.6,
                                        ),
                                      ],
                                    ),
                              borderRadius: BorderRadius.circular(
                                isMobile ? 12 : 14,
                              ),
                              border: Border.all(
                                color: isLight
                                    ? const Color(0xFFE0F2FE)
                                    : AppColors.cyan500.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                isMobile ? 12 : 14,
                              ),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 10,
                                  sigmaY: 10,
                                ),
                                child: Icon(
                                  Icons.arrow_back,
                                  color: getIconColor(),
                                  size: isMobile ? 20 : 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Text(
                          S.of(context).change_language,
                          style: TextStyle(
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            color: getTextPrimary(),
                          ),
                        ),
                        SizedBox(width: isMobile ? 40 : 48),
                      ],
                    )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: -0.2, end: 0, duration: 300.ms),
                SizedBox(height: isMobile ? 16 : 20),

                // Header Info
                Container(
                      padding: EdgeInsets.all(isMobile ? 16 : 20),
                      decoration: BoxDecoration(
                        color: isLight ? Colors.white : null,
                        gradient: isLight
                            ? null
                            : LinearGradient(
                                colors: [
                                  AppColors.cyan500.withOpacity(0.1),
                                  AppColors.blue500.withOpacity(0.1),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                        border: Border.all(
                          color: isLight
                              ? const Color(0xFFE0F2FE)
                              : AppColors.cyan500.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Row(
                            children: [
                              Icon(
                                Icons.language,
                                color: getIconColor(),
                                size: isMobile ? 20 : 24,
                              ),
                              SizedBox(width: isMobile ? 12 : 16),
                              Expanded(
                                child: Text(
                                  S.of(context).choose_language,
                                  style: TextStyle(
                                    fontSize: isMobile ? 13 : 14,
                                    color: getTextSecondary(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 300.ms)
                    .slideY(begin: 0.2, end: 0, duration: 300.ms),
                SizedBox(height: isMobile ? 24 : 32),

                // Language List
                ...List.generate(_languages.length, (index) {
                  final language = _languages[index];
                  final isSelected = _selectedLanguage == language['code'];
                  return Padding(
                    padding: EdgeInsets.only(bottom: isMobile ? 8 : 12),
                    child:
                        GestureDetector(
                              onTap: () =>
                                  _handleLanguageSelect(language['code']!),
                              child: Container(
                                padding: EdgeInsets.all(isMobile ? 16 : 20),
                                decoration: BoxDecoration(
                                  color: getCardBg(isSelected),
                                  borderRadius: BorderRadius.circular(
                                    isMobile ? 16 : 20,
                                  ),
                                  border: Border.all(
                                    color: getCardBorder(isSelected),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    isMobile ? 16 : 20,
                                  ),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 10,
                                      sigmaY: 10,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              language['flag']!,
                                              style: const TextStyle(
                                                fontSize: 32,
                                              ),
                                            ),
                                            SizedBox(width: isMobile ? 16 : 20),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  language['name']!,
                                                  style: TextStyle(
                                                    fontSize: isMobile
                                                        ? 16
                                                        : 18,
                                                    fontWeight: FontWeight.w500,
                                                    color: getTextPrimary(),
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  language['nativeName']!,
                                                  style: TextStyle(
                                                    fontSize: isMobile
                                                        ? 13
                                                        : 14,
                                                    color: getTextSecondary()
                                                        .withOpacity(0.7),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        if (isSelected)
                                          Icon(
                                            Icons.check,
                                            color: getCheckColor(),
                                            size: isMobile ? 20 : 24,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .animate()
                            .fadeIn(
                              delay: Duration(milliseconds: 100 + (index * 50)),
                              duration: 300.ms,
                            )
                            .slideX(
                              begin: -0.2,
                              end: 0,
                              delay: Duration(milliseconds: 100 + (index * 50)),
                              duration: 300.ms,
                            ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
