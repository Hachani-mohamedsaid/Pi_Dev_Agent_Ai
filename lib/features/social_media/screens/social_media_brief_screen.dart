import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../models/campaign_brief_model.dart';
import 'social_media_generating_screen.dart';

class SocialMediaBriefScreen extends StatefulWidget {
  const SocialMediaBriefScreen({super.key});

  @override
  State<SocialMediaBriefScreen> createState() => _SocialMediaBriefScreenState();
}

class _SocialMediaBriefScreenState extends State<SocialMediaBriefScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productNameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _audienceCtrl = TextEditingController();

  String _tone = 'Professional';
  final _tones = ['Professional', 'Friendly', 'Bold', 'Luxurious'];

  final _allPlatforms = [
    'Instagram',
    'Twitter/X',
    'Facebook',
    'TikTok',
    'YouTube',
  ];
  final Set<String> _selectedPlatforms = {'Instagram', 'Twitter/X'};

  @override
  void dispose() {
    _productNameCtrl.dispose();
    _descriptionCtrl.dispose();
    _audienceCtrl.dispose();
    super.dispose();
  }

  void _generate() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPlatforms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one platform.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final brief = CampaignBriefModel(
      productName: _productNameCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      targetAudience: _audienceCtrl.text.trim(),
      toneOfVoice: _tone,
      platforms: _selectedPlatforms.toList(),
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SocialMediaGeneratingScreen(brief: brief),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F2940)
          : const Color(0xFFF3F8FC),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [
                    Color(0xFF0f2940),
                    Color(0xFF1a3a52),
                    Color(0xFF0f2940),
                  ]
                : const [
                    Color(0xFFF8FCFF),
                    Color(0xFFEAF4FB),
                    Color(0xFFF3F8FC),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, isDark),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('Product / App Name'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          isDark: isDark,
                          controller: _productNameCtrl,
                          hint: 'e.g. Ava AI Assistant',
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 20),
                        _sectionLabel('Short Description'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          isDark: isDark,
                          controller: _descriptionCtrl,
                          hint: 'Describe your product in a few sentences…',
                          maxLines: 4,
                          maxLength: 300,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 20),
                        _sectionLabel('Target Audience'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          isDark: isDark,
                          controller: _audienceCtrl,
                          hint: 'e.g. Business professionals aged 25–45',
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 20),
                        _sectionLabel('Tone of Voice'),
                        const SizedBox(height: 8),
                        _buildDropdown(isDark),
                        const SizedBox(height: 20),
                        _sectionLabel('Platforms to Target'),
                        const SizedBox(height: 12),
                        _buildPlatformChips(isDark),
                        const SizedBox(height: 32),
                        _buildGenerateButton(isDark),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.07)
                    : const Color(0xFF0EA5C6).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? AppColors.cyan500.withOpacity(0.2)
                      : const Color(0xFF0EA5C6).withOpacity(0.25),
                ),
              ),
              child: Icon(
                LucideIcons.arrowLeft,
                color: isDark ? Colors.white : const Color(0xFF12344C),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Social Media Campaign',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF12344C),
                  ),
                ),
                Text(
                  'Fill in the brief to generate your campaign',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textCyan200.withOpacity(0.7)
                        : const Color(0xFF3B6D8C),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFFEC4899).withOpacity(0.15)
                  : const Color(0xFFEC4899).withOpacity(0.09),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? const Color(0xFFEC4899).withOpacity(0.3)
                    : const Color(0xFFEC4899).withOpacity(0.35),
              ),
            ),
            child: const Icon(
              LucideIcons.megaphone,
              color: Color(0xFFEC4899),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textCyan200.withOpacity(0.85),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildTextField({
    required bool isDark,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      inputFormatters: maxLength != null
          ? [LengthLimitingTextInputFormatter(maxLength)]
          : null,
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF12344C),
        fontSize: 14,
      ),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark
              ? Colors.white.withOpacity(0.3)
              : const Color(0xFF577F97),
          fontSize: 14,
        ),
        counterStyle: TextStyle(
          color: isDark
              ? AppColors.textCyan200.withOpacity(0.5)
              : const Color(0xFF4E7891),
          fontSize: 11,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.05)
            : const Color(0xFFDDEDF8).withOpacity(0.9),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark
                ? AppColors.cyan500.withOpacity(0.2)
                : const Color(0xFF0EA5C6).withOpacity(0.28),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.cyan400.withOpacity(0.6),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
      ),
    );
  }

  Widget _buildDropdown(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : const Color(0xFFDDEDF8).withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? AppColors.cyan500.withOpacity(0.2)
              : const Color(0xFF0EA5C6).withOpacity(0.28),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _tone,
          isExpanded: true,
          dropdownColor: isDark
              ? const Color(0xFF1a3a52)
              : const Color(0xFFEAF4FB),
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF12344C),
            fontSize: 14,
          ),
          iconEnabledColor: isDark
              ? AppColors.cyan400
              : const Color(0xFF0E86AA),
          items: _tones.map((t) {
            return DropdownMenuItem(
              value: t,
              child: Text(
                t,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF12344C),
                ),
              ),
            );
          }).toList(),
          onChanged: (v) => setState(() => _tone = v ?? _tone),
        ),
      ),
    );
  }

  Widget _buildPlatformChips(bool isDark) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _allPlatforms.map((p) {
        final selected = _selectedPlatforms.contains(p);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (selected) {
                _selectedPlatforms.remove(p);
              } else {
                _selectedPlatforms.add(p);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                      colors: [
                        AppColors.cyan500.withOpacity(0.35),
                        AppColors.cyan400.withOpacity(0.2),
                      ],
                    )
                  : null,
              color: selected ? null : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: selected
                    ? AppColors.cyan400.withOpacity(0.7)
                    : AppColors.cyan500.withOpacity(0.15),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  Icon(LucideIcons.check, size: 13, color: AppColors.cyan400),
                  const SizedBox(width: 6),
                ],
                Text(
                  p,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected
                        ? (isDark ? AppColors.cyan400 : const Color(0xFF0E86AA))
                        : (isDark
                              ? Colors.white.withOpacity(0.6)
                              : const Color(0xFF4E7891)),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGenerateButton(bool isDark) {
    return GestureDetector(
      onTap: _generate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEC4899), Color(0xFFA855F7)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEC4899).withOpacity(isDark ? 0.4 : 0.28),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.sparkles, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              'Generate Campaign',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
