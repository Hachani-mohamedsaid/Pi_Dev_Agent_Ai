import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../state/auth_controller.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class EditProfilePage extends StatefulWidget {
  final AuthController controller;

  const EditProfilePage({
    super.key,
    required this.controller,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  late TextEditingController _bioController;
  late TextEditingController _birthDateController;

  @override
  void initState() {
    super.initState();
    final user = widget.controller.currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: '+1 (555) 123-4567');
    _locationController = TextEditingController(text: 'San Francisco, CA');
    _bioController = TextEditingController(text: 'AI Enthusiast | Tech Explorer');
    _birthDateController = TextEditingController(text: '1990-01-15');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      // Handle save logic
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? 24.0 : 32.0;
    final user = widget.controller.currentUser;
    final initials = user?.name
            .split(' ')
            .map((n) => n.isNotEmpty ? n[0].toUpperCase() : '')
            .take(2)
            .join() ??
        'JD';

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
                      'Edit Profile',
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
                SizedBox(height: isMobile ? 24 : 32),

                // Avatar Section
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: isMobile ? 96 : 112,
                            height: isMobile ? 96 : 112,
                            decoration: BoxDecoration(
                              gradient: AppColors.logoGradient,
                              borderRadius: BorderRadius.circular(isMobile ? 24 : 28),
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: isMobile ? 36 : 42,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                // Handle photo change
                              },
                              child: Container(
                                padding: EdgeInsets.all(isMobile ? 8 : 10),
                                decoration: BoxDecoration(
                                  gradient: AppColors.buttonGradient,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primaryDark,
                                    width: 4,
                                  ),
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: AppColors.textWhite,
                                  size: isMobile ? 16 : 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 12 : 16),
                      Text(
                        'Tap to change photo',
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          color: AppColors.textCyan200.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 300.ms)
                    .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), duration: 300.ms),
                SizedBox(height: isMobile ? 24 : 32),

                // Form Fields
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomTextField(
                        label: 'Full Name',
                        hint: 'Enter your name',
                        icon: Icons.person_outline,
                        controller: _nameController,
                      )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 300.ms)
                          .slideY(begin: 0.2, end: 0, duration: 300.ms),
                      SizedBox(height: isMobile ? 20 : 24),
                      CustomTextField(
                        label: 'Email Address',
                        hint: 'Enter your email',
                        icon: Icons.mail_outline,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      )
                          .animate()
                          .fadeIn(delay: 250.ms, duration: 300.ms)
                          .slideY(begin: 0.2, end: 0, duration: 300.ms),
                      SizedBox(height: isMobile ? 20 : 24),
                      CustomTextField(
                        label: 'Phone Number',
                        hint: 'Enter your phone',
                        icon: Icons.phone_outlined,
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                      )
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 300.ms)
                          .slideY(begin: 0.2, end: 0, duration: 300.ms),
                      SizedBox(height: isMobile ? 20 : 24),
                      CustomTextField(
                        label: 'Location',
                        hint: 'Enter your location',
                        icon: Icons.location_on_outlined,
                        controller: _locationController,
                      )
                          .animate()
                          .fadeIn(delay: 350.ms, duration: 300.ms)
                          .slideY(begin: 0.2, end: 0, duration: 300.ms),
                      SizedBox(height: isMobile ? 20 : 24),
                      GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            _birthDateController.text =
                                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                          }
                        },
                        child: CustomTextField(
                          label: 'Birth Date',
                          hint: 'Select date',
                          icon: Icons.calendar_today_outlined,
                          controller: _birthDateController,
                          onChanged: (value) {},
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 300.ms)
                          .slideY(begin: 0.2, end: 0, duration: 300.ms),
                      SizedBox(height: isMobile ? 20 : 24),
                      // Bio TextArea
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              left: isMobile ? 4 : 8,
                              bottom: isMobile ? 6 : 8,
                            ),
                            child: Text(
                              'Bio',
                              style: TextStyle(
                                color: AppColors.textCyan200,
                                fontSize: isMobile ? 14 : 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
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
                                child: TextField(
                                  controller: _bioController,
                                  maxLines: 3,
                                  style: TextStyle(
                                    color: AppColors.textWhite,
                                    fontSize: isMobile ? 15 : 16,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Tell us about yourself...',
                                    hintStyle: TextStyle(
                                      color: AppColors.textCyan200.withOpacity(0.3),
                                      fontSize: isMobile ? 15 : 16,
                                    ),
                                    contentPadding: EdgeInsets.all(isMobile ? 16 : 20),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                          .animate()
                          .fadeIn(delay: 450.ms, duration: 300.ms)
                          .slideY(begin: 0.2, end: 0, duration: 300.ms),
                    ],
                  ),
                ),
                SizedBox(height: isMobile ? 32 : 40),

                // Save Button
                CustomButton(
                  text: 'Save Changes',
                  onPressed: _handleSave,
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 300.ms)
                    .slideY(begin: 0.2, end: 0, duration: 300.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
