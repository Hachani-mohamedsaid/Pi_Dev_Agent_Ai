import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';

/// First step: user enters their website URL. Then chooses dashboard style.
class BusinessUrlScreen extends StatefulWidget {
  const BusinessUrlScreen({super.key});

  @override
  State<BusinessUrlScreen> createState() => _BusinessUrlScreenState();
}

class _BusinessUrlScreenState extends State<BusinessUrlScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _continue() {
    final url = _controller.text.trim();
    if (url.isEmpty) return;
    context.push('/my-business/style', extra: url);
  }

  @override
  Widget build(BuildContext context) {
    const padUnit = 8.0;
    final padding = padUnit * 3; // 24
    final isMobile = Responsive.isMobile(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0f2940), Color(0xFF1a3a52), Color(0xFF0f2940)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: const Text('Mon business'),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHero(context, isMobile),
                      SizedBox(height: padUnit * 3),
                      _buildUrlCard(context, isMobile),
                      SizedBox(height: padUnit * 3),
                      _buildContinueButton(context, isMobile),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, bool isMobile) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cyan500.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.cyan400.withOpacity(0.3), width: 1),
          ),
          child: Icon(
            LucideIcons.globe,
            size: Responsive.getResponsiveValue(context, mobile: 44.0, tablet: 52.0, desktop: 56.0),
            color: AppColors.cyan400,
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms)
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 400.ms),
        SizedBox(height: Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 20.0, desktop: 24.0)),
        Text(
          'Lien de ton site web',
          style: TextStyle(
            fontSize: Responsive.getResponsiveValue(context, mobile: 20.0, tablet: 22.0, desktop: 24.0),
            fontWeight: FontWeight.bold,
            color: AppColors.textWhite,
          ),
          textAlign: TextAlign.center,
        )
            .animate()
            .fadeIn(delay: 150.ms, duration: 350.ms)
            .slideY(begin: 0.2, end: 0, delay: 150.ms, duration: 350.ms),
        SizedBox(height: Responsive.getResponsiveValue(context, mobile: 8.0, tablet: 10.0, desktop: 12.0)),
        Text(
          'Entre l’URL de ton site ou boutique. On te proposera des styles de dashboard adaptés à ton activité.',
          style: TextStyle(
            fontSize: Responsive.getResponsiveValue(context, mobile: 13.0, tablet: 14.0, desktop: 15.0),
            color: AppColors.textCyan200.withOpacity(0.9),
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        )
            .animate()
            .fadeIn(delay: 250.ms, duration: 350.ms),
      ],
    );
  }

  Widget _buildUrlCard(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 18.0, tablet: 22.0, desktop: 26.0)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1e4a66).withOpacity(0.5),
            const Color(0xFF16384d).withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0)),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.link, color: AppColors.cyan400, size: Responsive.getResponsiveValue(context, mobile: 20.0, tablet: 22.0, desktop: 24.0)),
              SizedBox(width: Responsive.getResponsiveValue(context, mobile: 10.0, tablet: 12.0, desktop: 14.0)),
              Text(
                'URL du site',
                style: TextStyle(
                  fontSize: Responsive.getResponsiveValue(context, mobile: 15.0, tablet: 16.0, desktop: 17.0),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textWhite,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.getResponsiveValue(context, mobile: 14.0, tablet: 16.0, desktop: 18.0)),
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: TextInputType.url,
            autocorrect: false,
            style: TextStyle(color: AppColors.textWhite, fontSize: Responsive.getResponsiveValue(context, mobile: 15.0, tablet: 16.0, desktop: 17.0)),
            decoration: InputDecoration(
              hintText: 'https://mon-site.com ou https://ma-boutique.com',
              hintStyle: TextStyle(color: AppColors.textCyan200.withOpacity(0.5), fontSize: 14),
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.cyan500.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.cyan500.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.cyan400, width: 1.5),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: Responsive.getResponsiveValue(context, mobile: 14.0, tablet: 16.0, desktop: 18.0),
                vertical: Responsive.getResponsiveValue(context, mobile: 14.0, tablet: 16.0, desktop: 18.0),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0, delay: 300.ms, duration: 400.ms);
  }

  Widget _buildContinueButton(BuildContext context, bool isMobile) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _continue,
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(context, mobile: 14.0, tablet: 16.0, desktop: 18.0)),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: Responsive.getResponsiveValue(context, mobile: 14.0, tablet: 16.0, desktop: 18.0),
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
            ),
            borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(context, mobile: 14.0, tablet: 16.0, desktop: 18.0)),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyan500.withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.layoutDashboard, color: Colors.white, size: Responsive.getResponsiveValue(context, mobile: 20.0, tablet: 22.0, desktop: 24.0)),
              SizedBox(width: Responsive.getResponsiveValue(context, mobile: 10.0, tablet: 12.0, desktop: 14.0)),
              Text(
                'Voir les styles de dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: Responsive.getResponsiveValue(context, mobile: 15.0, tablet: 16.0, desktop: 17.0),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0, delay: 400.ms, duration: 400.ms);
  }
}
