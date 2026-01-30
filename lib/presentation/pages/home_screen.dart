import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../state/auth_controller.dart';
import '../widgets/navigation_bar.dart';

class HomeScreen extends StatefulWidget {
  final AuthController controller;

  const HomeScreen({
    super.key,
    required this.controller,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load current user if not already loaded
    if (widget.controller.currentUser == null) {
      widget.controller.loadCurrentUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? 24.0 : 32.0;

    final placeholderCards = [
      _PlaceholderCard(
        id: 1,
        title: 'Recent Conversations',
        description: 'Your latest AI interactions',
        icon: Icons.message_outlined,
        gradient: const LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
        ),
      ),
      _PlaceholderCard(
        id: 2,
        title: 'Quick Actions',
        description: 'Frequently used commands',
        icon: Icons.auto_awesome,
        gradient: const LinearGradient(
          colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
        ),
      ),
      _PlaceholderCard(
        id: 3,
        title: 'Activity History',
        description: 'Track your usage patterns',
        icon: Icons.access_time,
        gradient: const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFEF4444)],
        ),
      ),
      _PlaceholderCard(
        id: 4,
        title: 'Insights & Stats',
        description: 'See your progress over time',
        icon: Icons.trending_up,
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
        ),
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Main Content
              SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: padding,
                  right: padding,
                  top: padding,
                  bottom: Responsive.getResponsiveValue(
                    context,
                    mobile: 100.0,
                    tablet: 120.0,
                    desktop: 140.0,
                  ), // Space for navigation bar
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back!',
                          style: TextStyle(
                            fontSize: isMobile ? 28 : 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textWhite,
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .slideY(begin: -0.2, end: 0, duration: 500.ms),
                        SizedBox(height: isMobile ? 8 : 12),
                        Text(
                          'How can I assist you today?',
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            color: AppColors.textCyan200.withOpacity(0.7),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 100.ms, duration: 500.ms),
                      ],
                    ),
                    SizedBox(height: isMobile ? 24 : 32),

                    // Featured Card
                    _FeaturedCard(isMobile: isMobile)
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 500.ms)
                        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), duration: 500.ms),
                    SizedBox(height: isMobile ? 24 : 32),

                    // Cards Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isMobile ? 2 : 2,
                        crossAxisSpacing: isMobile ? 12 : 16,
                        mainAxisSpacing: isMobile ? 12 : 16,
                        childAspectRatio: isMobile ? 0.85 : 0.9,
                      ),
                      itemCount: placeholderCards.length,
                      itemBuilder: (context, index) {
                        return placeholderCards[index]
                            .animate()
                            .fadeIn(delay: Duration(milliseconds: 300 + (index * 100)), duration: 500.ms)
                            .slideY(begin: 0.2, end: 0, delay: Duration(milliseconds: 300 + (index * 100)), duration: 500.ms);
                      },
                    ),
                    SizedBox(height: isMobile ? 24 : 32),

                    // Recent Activity Section
                    Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textWhite,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 700.ms, duration: 500.ms),
                    SizedBox(height: isMobile ? 12 : 16),
                    ...List.generate(3, (index) {
                      return _ActivityItem(
                        title: 'Sample Activity ${index + 1}',
                        time: '2 hours ago',
                        isMobile: isMobile,
                      )
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: 800 + (index * 100)), duration: 500.ms);
                    }),
                    SizedBox(height: isMobile ? 24 : 32),
                  ],
                ),
              ),

              // Navigation Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: NavigationBarWidget(currentPath: '/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final bool isMobile;

  const _FeaturedCard({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cyan500.withOpacity(0.2),
            AppColors.blue500.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 24 : 28),
        border: Border.all(
          color: AppColors.cyan500.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isMobile ? 24 : 28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 20 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start a New Conversation',
                            style: TextStyle(
                              fontSize: isMobile ? 18 : 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textWhite,
                            ),
                          ),
                          SizedBox(height: isMobile ? 8 : 12),
                          Text(
                            "Ask me anything and I'll help you out",
                            style: TextStyle(
                              fontSize: isMobile ? 13 : 14,
                              color: AppColors.textCyan200.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: isMobile ? 12 : 16),
                    Container(
                      width: isMobile ? 48 : 56,
                      height: isMobile ? 48 : 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.cyan400, AppColors.blue500],
                        ),
                        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: AppColors.textWhite,
                        size: isMobile ? 24 : 28,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 20 : 24),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.buttonGradient,
                      borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // Handle start chat
                        },
                        borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 14),
                          alignment: Alignment.center,
                          child: Text(
                            'Start Chat',
                            style: TextStyle(
                              color: AppColors.textWhite,
                              fontSize: isMobile ? 15 : 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  final int id;
  final String title;
  final String description;
  final IconData icon;
  final LinearGradient gradient;

  const _PlaceholderCard({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return GestureDetector(
      onTap: () {
        // Handle card tap
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryLight.withOpacity(0.6),
              AppColors.primaryDarker.withOpacity(0.6),
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
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: isMobile ? 48 : 56,
                    height: isMobile ? 48 : 56,
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.textWhite,
                      size: isMobile ? 24 : 28,
                    ),
                  ),
                  SizedBox(height: isMobile ? 12 : 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textWhite,
                    ),
                  ),
                  SizedBox(height: isMobile ? 4 : 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 13,
                      color: AppColors.textCyan200.withOpacity(0.6),
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

class _ActivityItem extends StatelessWidget {
  final String title;
  final String time;
  final bool isMobile;

  const _ActivityItem({
    required this.title,
    required this.time,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryLight.withOpacity(0.4),
            AppColors.primaryDarker.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
        border: Border.all(
          color: AppColors.cyan500.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: isMobile ? 40 : 48,
                      height: isMobile ? 40 : 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.cyan500.withOpacity(0.2),
                            AppColors.blue500.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                      ),
                      child: Icon(
                        Icons.message_outlined,
                        color: AppColors.cyan400,
                        size: isMobile ? 20 : 24,
                      ),
                    ),
                    SizedBox(width: isMobile ? 12 : 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textWhite,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 13,
                            color: AppColors.textCyan200.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.cyan400,
                  size: isMobile ? 20 : 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
