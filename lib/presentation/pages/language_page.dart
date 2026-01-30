import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  String _selectedLanguage = 'en';

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'nativeName': 'English', 'flag': '🇺🇸'},
    {'code': 'es', 'name': 'Spanish', 'nativeName': 'Español', 'flag': '🇪🇸'},
    {'code': 'fr', 'name': 'French', 'nativeName': 'Français', 'flag': '🇫🇷'},
    {'code': 'de', 'name': 'German', 'nativeName': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'it', 'name': 'Italian', 'nativeName': 'Italiano', 'flag': '🇮🇹'},
    {'code': 'pt', 'name': 'Portuguese', 'nativeName': 'Português', 'flag': '🇵🇹'},
    {'code': 'ru', 'name': 'Russian', 'nativeName': 'Русский', 'flag': '🇷🇺'},
    {'code': 'zh', 'name': 'Chinese', 'nativeName': '中文', 'flag': '🇨🇳'},
    {'code': 'ja', 'name': 'Japanese', 'nativeName': '日本語', 'flag': '🇯🇵'},
    {'code': 'ko', 'name': 'Korean', 'nativeName': '한국어', 'flag': '🇰🇷'},
    {'code': 'ar', 'name': 'Arabic', 'nativeName': 'العربية', 'flag': '🇸🇦'},
    {'code': 'hi', 'name': 'Hindi', 'nativeName': 'हिन्दी', 'flag': '🇮🇳'},
  ];

  void _handleLanguageSelect(String code) {
    setState(() {
      _selectedLanguage = code;
    });
    // Handle language change
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? 24.0 : 32.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
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
                              Icons.arrow_back,
                              color: AppColors.cyan400,
                              size: isMobile ? 20 : 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      'Language',
                      style: TextStyle(
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textWhite,
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
                    gradient: LinearGradient(
                      colors: [
                        AppColors.cyan500.withOpacity(0.1),
                        AppColors.blue500.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                    border: Border.all(
                      color: AppColors.cyan500.withOpacity(0.2),
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
                            color: AppColors.cyan400,
                            size: isMobile ? 20 : 24,
                          ),
                          SizedBox(width: isMobile ? 12 : 16),
                          Expanded(
                            child: Text(
                              'Select your preferred language for the app',
                              style: TextStyle(
                                fontSize: isMobile ? 13 : 14,
                                color: AppColors.textCyan200.withOpacity(0.7),
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
                    child: GestureDetector(
                      onTap: () => _handleLanguageSelect(language['code']!),
                      child: Container(
                        padding: EdgeInsets.all(isMobile ? 16 : 20),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    AppColors.cyan500.withOpacity(0.2),
                                    AppColors.blue500.withOpacity(0.2),
                                  ],
                                )
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primaryLight.withOpacity(0.4),
                                    AppColors.primaryDarker.withOpacity(0.4),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.cyan500.withOpacity(0.5)
                                : AppColors.cyan500.withOpacity(0.1),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      language['flag']!,
                                      style: const TextStyle(fontSize: 32),
                                    ),
                                    SizedBox(width: isMobile ? 16 : 20),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          language['name']!,
                                          style: TextStyle(
                                            fontSize: isMobile ? 16 : 18,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textWhite,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          language['nativeName']!,
                                          style: TextStyle(
                                            fontSize: isMobile ? 13 : 14,
                                            color: AppColors.textCyan200.withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check,
                                    color: AppColors.cyan400,
                                    size: isMobile ? 20 : 24,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: 100 + (index * 50)), duration: 300.ms)
                        .slideX(begin: -0.2, end: 0, delay: Duration(milliseconds: 100 + (index * 50)), duration: 300.ms),
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
