import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../widgets/navigation_bar.dart';
// NEW: n8n finance service for real data
import '../../services/n8n_finance_service.dart';
import '../../services/ml_prediction_service.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  // NEW: API integration state
  bool _isLoading = true;
  String? _errorMessage;
  final _financeService = N8nFinanceService();
  final _mlService = MlPredictionService();

  // NEW: Data from n8n webhooks
  Map<String, dynamic>? _monthStats;
  List<dynamic>? _vendors;
  List<dynamic>? _categories;
  List<dynamic>? _daySpending;
  SpendingPredictionResult? _mlPrediction;


  // NEW: Load data from n8n webhooks on init
  @override
  void initState() {
    super.initState();
    _loadFinanceData();
  }

  // NEW: Load all finance data from n8n webhooks
  Future<void> _loadFinanceData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch all finance data + ML prediction in parallel
      final results = await Future.wait([
        _financeService.getCurrentMonthStats(),
        _financeService.getVendorBreakdown(),
        _financeService.getCategoryBreakdown(),
        _financeService.getSpendingByDay(),
      ]);

      // ML prediction fetched separately so a failure doesn't block the page
      SpendingPredictionResult? ml;
      try {
        ml = await _mlService.getSpendingPrediction();
      } catch (mlErr) {
        // ML is optional — page still works without it
        print('⚠️ ML prediction unavailable: $mlErr');
      }

      if (!mounted) return;

      setState(() {
        _monthStats = results[0];
        _vendors = (results[1]['vendors'] as List?) ?? [];
        _categories = (results[2]['breakdown'] as List?) ?? [];
        _daySpending = (results[3]['byDay'] as List?) ?? [];
        _mlPrediction = ml;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading finance data: $e');
      if (!mounted) return;
      
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // NEW: Safe numeric parsing for webhook values (num or string)
  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // NEW: Format YYYY-MM as "Month YYYY"
  String _formatMonthLabel(dynamic rawMonth) {
    if (rawMonth is! String || rawMonth.isEmpty) return 'N/A';
    final parts = rawMonth.split('-');
    if (parts.length != 2) return rawMonth;
    final year = parts[0];
    final monthNum = int.tryParse(parts[1]) ?? 0;
    const monthNames = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    if (monthNum < 1 || monthNum > 12) return rawMonth;
    return '${monthNames[monthNum]} $year';
  }

  // MODIFIED: Update Telegram bot link to Rocco4xbot
  Future<void> _handleTelegramBot() async {
    final uri = Uri.parse('https://t.me/Rocco4xbot');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.getResponsiveValue(
      context,
      mobile: 24.0,
      tablet: 28.0,
      desktop: 32.0,
    );
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0f2940),
              Color(0xFF1a3a52),
              Color(0xFF0f2940),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // NEW: Loading state
              if (_isLoading)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading finance data...',
                        style: TextStyle(
                          color: AppColors.textCyan200.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              // NEW: Error state
              else if (_errorMessage != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.alertCircle,
                          size: 64,
                          color: Color(0xFFEF4444),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Failed to load finance data',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textCyan200.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadFinanceData,
                          icon: const Icon(LucideIcons.refreshCw),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              // Main Content with Pull-to-Refresh
              else
                RefreshIndicator(
                  onRefresh: _loadFinanceData,
                  color: const Color(0xFF10B981),
                  child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: padding,
                  right: padding,
                  top: padding,
                  bottom: Responsive.getResponsiveValue(
                    context,
                    mobile: 100.0,
                    tablet: 120.0,
                    desktop: 140.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Finance',
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveValue(
                          context,
                          mobile: 28.0,
                          tablet: 32.0,
                          desktop: 36.0,
                        ),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textWhite,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: -0.2, end: 0, duration: 500.ms),

                    SizedBox(height: Responsive.getResponsiveValue(
                      context,
                      mobile: 24.0,
                      tablet: 28.0,
                      desktop: 32.0,
                    )),

                    // Monthly Summary Card
                    _buildMonthlySummaryCard(context, isMobile),

                    SizedBox(height: Responsive.getResponsiveValue(
                      context,
                      mobile: 24.0,
                      tablet: 28.0,
                      desktop: 32.0,
                    )),

                    // Vendor Breakdown
                    _buildVendorBreakdown(context, isMobile),

                    SizedBox(height: Responsive.getResponsiveValue(
                      context,
                      mobile: 24.0,
                      tablet: 28.0,
                      desktop: 32.0,
                    )),

                    // Category Insights
                    _buildCategoryInsights(context, isMobile),

                    SizedBox(height: Responsive.getResponsiveValue(
                      context,
                      mobile: 24.0,
                      tablet: 28.0,
                      desktop: 32.0,
                    )),

                    // Time Analysis
                    _buildTimeAnalysis(context, isMobile),

                    SizedBox(height: Responsive.getResponsiveValue(
                      context,
                      mobile: 24.0,
                      tablet: 28.0,
                      desktop: 32.0,
                    )),

                    // ML: Spending Prediction (static for now; dynamic later)
                    _buildSpendingPredictionSection(context, isMobile),
                  ],
                ),
                  ), // MODIFIED: Close RefreshIndicator
                ), // MODIFIED: Close else statement

              // Navigation Bar (always visible, including during loading)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: NavigationBarWidget(currentPath: '/finance'),
              ),

              // Floating Telegram Button
              Positioned(
                right: Responsive.getResponsiveValue(
                  context,
                  mobile: 24.0,
                  tablet: 32.0,
                  desktop: 40.0,
                ),
                bottom: Responsive.getResponsiveValue(
                  context,
                  mobile: 120.0,
                  tablet: 140.0,
                  desktop: 160.0,
                ),
                child: _buildTelegramButton(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlySummaryCard(BuildContext context, bool isMobile) {
    final income = _monthStats?['income']?.toString() ?? '0.00';
    final expenses = _monthStats?['expenses']?.toString() ?? '0.00';
    final profit = _monthStats?['profit']?.toString() ?? '0.00';
    final savingsRate = _asDouble(_monthStats?['savingsRate']);

    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(
        context,
        mobile: 24.0,
        tablet: 28.0,
        desktop: 32.0,
      )),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1e4a66).withOpacity(0.6),
            const Color(0xFF16384d).withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Month Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: null,
                icon: const Icon(LucideIcons.chevronLeft),
                color: const Color(0xFF10B981),
                iconSize: 20,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                ),
              ),
            Row(
              children: [
                const Icon(LucideIcons.calendar, color: Color(0xFF10B981), size: 20),
                const SizedBox(width: 8),
                Text(
                  // MODIFIED: Use real month from API (no static fallback)
                  _formatMonthLabel(_monthStats?['month']),
                  style: TextStyle(
                      fontSize: Responsive.getResponsiveValue(
                        context,
                        mobile: 18.0,
                        tablet: 20.0,
                        desktop: 22.0,
                      ),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textWhite,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: null,
                icon: const Icon(LucideIcons.chevronRight),
                color: const Color(0xFF10B981),
                iconSize: 20,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                ),
              ),
            ],
          ),

          SizedBox(height: Responsive.getResponsiveValue(
            context,
            mobile: 20.0,
            tablet: 24.0,
            desktop: 28.0,
          )),

          // Financial Summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFinancialStat(
                context,
                LucideIcons.trendingUp,
                'Income',
                // MODIFIED: Use real API data only
                '\$$income',
                const Color(0xFF22C55E),
              ),
              _buildFinancialStat(
                context,
                LucideIcons.trendingDown,
                'Expenses',
                // MODIFIED: Use real API data only
                '\$$expenses',
                const Color(0xFFEF4444),
              ),
              _buildFinancialStat(
                context,
                LucideIcons.dollarSign,
                'Profit',
                // MODIFIED: Use real API data only
                '\$$profit',
                const Color(0xFF10B981),
              ),
            ],
          ),

          SizedBox(height: Responsive.getResponsiveValue(
            context,
            mobile: 24.0,
            tablet: 28.0,
            desktop: 32.0,
          )),

          // Circular Progress - Savings Rate
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    // MODIFIED: Use real API data only
                    value: (savingsRate.clamp(0, 100)) / 100,
                    strokeWidth: 12,
                    backgroundColor: const Color(0xFF06B6D4).withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      // MODIFIED: Use real API data only
                      '${savingsRate.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Savings Rate',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF06B6D4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 100.ms, duration: 500.ms)
        .slideY(begin: 0.2, end: 0, delay: 100.ms, duration: 500.ms);
  }

  Widget _buildFinancialStat(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: Responsive.getResponsiveValue(
                  context,
                  mobile: 11.0,
                  tablet: 12.0,
                  desktop: 13.0,
                ),
                color: const Color(0xFF06B6D4).withOpacity(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: Responsive.getResponsiveValue(
              context,
              mobile: 18.0,
              tablet: 20.0,
              desktop: 22.0,
            ),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildVendorBreakdown(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(
        context,
        mobile: 20.0,
        tablet: 24.0,
        desktop: 28.0,
      )),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1e4a66).withOpacity(0.4),
            const Color(0xFF16384d).withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.cyan500.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.arrowUpRight, color: Color(0xFF06B6D4), size: 20),
              const SizedBox(width: 8),
              Text(
                'Top Vendors by Spend',
                style: TextStyle(
                  fontSize: Responsive.getResponsiveValue(
                    context,
                    mobile: 16.0,
                    tablet: 18.0,
                    desktop: 20.0,
                  ),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textWhite,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.getResponsiveValue(
            context,
            mobile: 16.0,
            tablet: 18.0,
            desktop: 20.0,
          )),
          // MODIFIED: Use real vendor data only
          ...List.generate(
            (_vendors ?? []).length.clamp(0, 10),
            (index) {
              final vendor = _vendors![index];

              final vendorName = vendor['vendor'] as String? ?? 'Unknown';
              final amount = vendor['amount'] as String? ?? '0.00';
              final percentage = double.tryParse(vendor['percentage'] as String? ?? '0') ?? 0.0;

              return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            vendorName,
                            style: TextStyle(
                            fontSize: Responsive.getResponsiveValue(
                              context,
                              mobile: 13.0,
                              tablet: 14.0,
                              desktop: 15.0,
                            ),
                            fontWeight: FontWeight.w500,
                            color: AppColors.textWhite,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFF06B6D4).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Stack(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 600),
                                    curve: Curves.easeOut,
                                    width: constraints.maxWidth * (percentage / 100),
                                    height: 24,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 50,
                        child: Text(
                          '${percentage.toStringAsFixed(1)}%',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: Responsive.getResponsiveValue(
                              context,
                              mobile: 13.0,
                              tablet: 14.0,
                              desktop: 15.0,
                            ),
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF06B6D4),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '\$$amount',
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveValue(
                          context,
                          mobile: 11.0,
                          tablet: 12.0,
                          desktop: 13.0,
                        ),
                        color: const Color(0xFF06B6D4).withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: Duration(milliseconds: 300 + index * 50), duration: 500.ms)
                .slideX(begin: -0.2, end: 0, delay: Duration(milliseconds: 300 + index * 50), duration: 500.ms);
          }),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 500.ms)
        .slideY(begin: 0.2, end: 0, delay: 200.ms, duration: 500.ms);
  }

  Widget _buildCategoryInsights(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(
        context,
        mobile: 20.0,
        tablet: 24.0,
        desktop: 28.0,
      )),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1e4a66).withOpacity(0.4),
            const Color(0xFF16384d).withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.cyan500.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Insights',
            style: TextStyle(
              fontSize: Responsive.getResponsiveValue(
                context,
                mobile: 16.0,
                tablet: 18.0,
                desktop: 20.0,
              ),
              fontWeight: FontWeight.w600,
              color: AppColors.textWhite,
            ),
          ),
          SizedBox(height: Responsive.getResponsiveValue(
            context,
            mobile: 16.0,
            tablet: 20.0,
            desktop: 24.0,
          )),

          // Donut Chart
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 60,
                // MODIFIED: Use real category data only
                sections: (_categories ?? []).asMap().entries.map((entry) {
                  final index = entry.key;
                  final category = entry.value;
                  final categoryName = category['category'] as String? ?? 'Unknown';
                  final percentage = double.tryParse(category['percentage'] as String? ?? '0') ?? 0.0;
                  
                  return PieChartSectionData(
                    value: percentage,
                    color: _getCategoryColor(categoryName, index),
                    radius: 30,
                    showTitle: false,
                  );
                }).toList(),
              ),
            ),
          ),

          SizedBox(height: Responsive.getResponsiveValue(
            context,
            mobile: 16.0,
            tablet: 20.0,
            desktop: 24.0,
          )),

          // Budget vs Actual
          Text(
            'Budget vs Actual',
            style: TextStyle(
              fontSize: Responsive.getResponsiveValue(
                context,
                mobile: 13.0,
                tablet: 14.0,
                desktop: 15.0,
              ),
              fontWeight: FontWeight.w500,
              color: const Color(0xFF06B6D4).withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),

          // MODIFIED: Use real category data only
          ...List.generate(
            (_categories ?? []).length,
            (index) {
              final category = _categories![index];

              final categoryName = category['category'] as String? ?? 'Unknown';
              final percentage = double.tryParse(category['percentage'] as String? ?? '0') ?? 0.0;
              
              // MODIFIED: Use the SAME color as pie chart for this category
              final categoryColor = _getCategoryColor(categoryName, index);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            // MODIFIED: Color indicator matching pie chart
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: categoryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              categoryName,
                              style: TextStyle(
                                fontSize: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 12.0,
                                  tablet: 13.0,
                                  desktop: 14.0,
                                ),
                                color: const Color(0xFF06B6D4).withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: Responsive.getResponsiveValue(
                              context,
                              mobile: 12.0,
                              tablet: 13.0,
                              desktop: 14.0,
                            ),
                            color: categoryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6D4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOut,
                            width: constraints.maxWidth * (percentage / 100),
                            height: 8,
                            decoration: BoxDecoration(
                              // MODIFIED: Use category color from pie chart
                              color: categoryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              )
                .animate()
                .fadeIn(delay: Duration(milliseconds: 400 + index * 100), duration: 500.ms);
          }),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: 500.ms)
        .slideY(begin: 0.2, end: 0, delay: 300.ms, duration: 500.ms);
  }

  // MODIFIED: Dynamic color generator - each category gets a unique color
  Color _getCategoryColor(String category, int index) {
    // Predefined colors for common categories
    final predefinedColors = {
      'Food': const Color(0xFFEF4444),
      'Food & Dining': const Color(0xFFEF4444),
      'Transport': const Color(0xFF06B6D4),
      'Transportation': const Color(0xFF06B6D4),
      'Shopping': const Color(0xFF22C55E),
      'Utilities': const Color(0xFFF59E0B),
      'Entertainment': const Color(0xFFA855F7),
      'Healthcare': const Color(0xFFEC4899),
      'Services': const Color(0xFF6366F1),
      'Other': const Color(0xFF9CA3AF),
    };
    
    // If category is predefined, use its color
    if (predefinedColors.containsKey(category)) {
      return predefinedColors[category]!;
    }
    
    // Otherwise, generate a unique color based on index
    final dynamicColors = [
      const Color(0xFFEF4444), // Red
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF22C55E), // Green
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFA855F7), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFF14B8A6), // Teal
      const Color(0xFFF97316), // Orange
      const Color(0xFF84CC16), // Lime
      const Color(0xFF0EA5E9), // Sky
    ];
    
    return dynamicColors[index % dynamicColors.length];
  }

  Widget _buildTimeAnalysis(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(
        context,
        mobile: 20.0,
        tablet: 24.0,
        desktop: 28.0,
      )),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1e4a66).withOpacity(0.4),
            const Color(0xFF16384d).withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.cyan500.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time Analysis',
            style: TextStyle(
              fontSize: Responsive.getResponsiveValue(
                context,
                mobile: 16.0,
                tablet: 18.0,
                desktop: 20.0,
              ),
              fontWeight: FontWeight.w600,
              color: AppColors.textWhite,
            ),
          ),
          SizedBox(height: Responsive.getResponsiveValue(
            context,
            mobile: 12.0,
            tablet: 14.0,
            desktop: 16.0,
          )),

          // Spending by Day of Week - Heatmap
          Text(
            'Spending by Day of Week',
            style: TextStyle(
              fontSize: Responsive.getResponsiveValue(
                context,
                mobile: 13.0,
                tablet: 14.0,
                desktop: 15.0,
              ),
              color: const Color(0xFF06B6D4).withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            // MODIFIED: Use real spending by day data only
            children: List.generate(
              (_daySpending ?? []).length,
              (index) {
                final day = _daySpending![index];

                final dayName = day['day'] as String? ?? '';
                final total = double.tryParse(day['total'] as String? ?? '0') ?? 0.0;
                
                // Calculate intensity for heatmap (relative to max spending)
                final maxSpending = _daySpending != null
                    ? _daySpending!.map((d) => double.tryParse(d['total'] as String? ?? '0') ?? 0.0).fold(0.0, (a, b) => a > b ? a : b)
                    : 120.0;
                final intensity = maxSpending > 0 ? total / maxSpending : 0.0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        padding: EdgeInsets.all(Responsive.getResponsiveValue(
                          context,
                          mobile: 8.0,
                          tablet: 10.0,
                          desktop: 12.0,
                        )),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(
                          16,
                          185,
                          129,
                          (intensity * 0.8).clamp(0.1, 1.0),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '\$${total.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.getResponsiveValue(
                              context,
                              mobile: 11.0,
                              tablet: 12.0,
                              desktop: 13.0,
                            ),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      // MODIFIED: Handle full day names (Monday) or short (Mon)
                      dayName.length > 3 ? dayName.substring(0, 3) : dayName,
                      style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 10.0,
                            tablet: 11.0,
                            desktop: 12.0,
                          ),
                          color: const Color(0xFF06B6D4).withOpacity(0.6),
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 500 + index * 50), duration: 500.ms)
                      .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), delay: Duration(milliseconds: 500 + index * 50), duration: 500.ms),
                ),
              );
            }),
          ),

          SizedBox(height: Responsive.getResponsiveValue(
            context,
            mobile: 20.0,
            tablet: 24.0,
            desktop: 28.0,
          )),

          // Monthly Comparison
          Text(
            'Monthly Comparison',
            style: TextStyle(
              fontSize: Responsive.getResponsiveValue(
                context,
                mobile: 13.0,
                tablet: 14.0,
                desktop: 15.0,
              ),
              color: const Color(0xFF06B6D4).withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(Responsive.getResponsiveValue(
                    context,
                    mobile: 16.0,
                    tablet: 18.0,
                    desktop: 20.0,
                  )),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06B6D4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF06B6D4).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Month',
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 11.0,
                            tablet: 12.0,
                            desktop: 13.0,
                          ),
                          color: const Color(0xFF06B6D4).withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        // MODIFIED: Use real expenses from API
                        '\$${_monthStats?['expenses']?.toString() ?? '0.00'}',
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 20.0,
                            tablet: 22.0,
                            desktop: 24.0,
                          ),
                          fontWeight: FontWeight.bold,
                          color: AppColors.textWhite,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        // MODIFIED: Show transaction count from API
                        '${_monthStats?['transactionCount'] ?? 0} transactions',
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 11.0,
                            tablet: 12.0,
                            desktop: 13.0,
                          ),
                          color: const Color(0xFF06B6D4).withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(Responsive.getResponsiveValue(
                    context,
                    mobile: 16.0,
                    tablet: 18.0,
                    desktop: 20.0,
                  )),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06B6D4).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF06B6D4).withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Spending',
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 11.0,
                            tablet: 12.0,
                            desktop: 13.0,
                          ),
                          color: const Color(0xFF06B6D4).withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        // MODIFIED: Show total from vendor or category breakdown
                        '\$${_vendors != null ? (_vendors!.fold<double>(0, (sum, v) => sum + (double.tryParse(v['amount'] ?? '0') ?? 0))).toStringAsFixed(2) : '0.00'}',
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 20.0,
                            tablet: 22.0,
                            desktop: 24.0,
                          ),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF06B6D4).withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        // MODIFIED: Show current month from API
                        _monthStats?['month'] ?? 'N/A',
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 11.0,
                            tablet: 12.0,
                            desktop: 13.0,
                          ),
                          color: const Color(0xFF06B6D4).withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: 500.ms)
        .slideY(begin: 0.2, end: 0, delay: 400.ms, duration: 500.ms);
  }

  /// ML Spending Prediction section — real data from NestJS /ml/spending-prediction.
  /// Falls back to a friendly loading/unavailable state if backend isn't ready yet.
  Widget _buildSpendingPredictionSection(BuildContext context, bool isMobile) {
    // While ML data is still null, show a subtle loading placeholder
    if (_mlPrediction == null) {
      return Container(
        padding: EdgeInsets.all(Responsive.getResponsiveValue(
          context, mobile: 20.0, tablet: 24.0, desktop: 28.0,
        )),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1e4a66).withOpacity(0.4),
              const Color(0xFF16384d).withOpacity(0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cyan500.withOpacity(0.1), width: 1),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.brain, color: Color(0xFFA855F7), size: 20),
            const SizedBox(width: 10),
            Text(
              'Spending Prediction — loading…',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textCyan200.withOpacity(0.7),
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(delay: 500.ms, duration: 400.ms);
    }

    final nextMonthLabel = _mlPrediction!.nextMonthLabel;
    final overBudgetCount = _mlPrediction!.overBudgetCount;
    final isOverBudget = overBudgetCount > 0;
    final predictions = _mlPrediction!.predictions;

    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(
        context,
        mobile: 20.0,
        tablet: 24.0,
        desktop: 28.0,
      )),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1e4a66).withOpacity(0.4),
            const Color(0xFF16384d).withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.cyan500.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.brain, color: Color(0xFFA855F7), size: 20),
              const SizedBox(width: 8),
              Text(
                'Spending Prediction',
                style: TextStyle(
                  fontSize: Responsive.getResponsiveValue(
                    context,
                    mobile: 16.0,
                    tablet: 18.0,
                    desktop: 20.0,
                  ),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textWhite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Next month ($nextMonthLabel) • Simple linear regression',
            style: TextStyle(
              fontSize: Responsive.getResponsiveValue(
                context,
                mobile: 11.0,
                tablet: 12.0,
                desktop: 13.0,
              ),
              color: const Color(0xFF06B6D4).withOpacity(0.7),
            ),
          ),
          SizedBox(height: Responsive.getResponsiveValue(
            context,
            mobile: 16.0,
            tablet: 18.0,
            desktop: 20.0,
          )),

          // Over budget alert
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isOverBudget
                  ? const Color(0xFFF59E0B).withOpacity(0.15)
                  : const Color(0xFF22C55E).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isOverBudget
                    ? const Color(0xFFF59E0B).withOpacity(0.4)
                    : const Color(0xFF22C55E).withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isOverBudget ? LucideIcons.alertTriangle : LucideIcons.checkCircle,
                  size: 18,
                  color: isOverBudget ? const Color(0xFFF59E0B) : const Color(0xFF22C55E),
                ),
                const SizedBox(width: 8),
                Text(
                  isOverBudget
                      ? '$overBudgetCount category(ies) trending over budget'
                      : 'On track — predicted within budget',
                  style: TextStyle(
                    fontSize: Responsive.getResponsiveValue(
                      context,
                      mobile: 12.0,
                      tablet: 13.0,
                      desktop: 14.0,
                    ),
                    fontWeight: FontWeight.w500,
                    color: isOverBudget ? const Color(0xFFF59E0B) : const Color(0xFF22C55E),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: Responsive.getResponsiveValue(
            context,
            mobile: 16.0,
            tablet: 18.0,
            desktop: 20.0,
          )),

          Text(
            'Predicted by category',
            style: TextStyle(
              fontSize: Responsive.getResponsiveValue(
                context,
                mobile: 13.0,
                tablet: 14.0,
                desktop: 15.0,
              ),
              fontWeight: FontWeight.w500,
              color: const Color(0xFF06B6D4).withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),

          ...List.generate(predictions.length, (index) {
            final p = predictions[index];
            final category = p.category;
            final predicted = p.predicted;
            final budget = p.budget;
            final overBudget = p.overBudget;
            final trend = p.trend; // 'up' | 'down' | 'stable'

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveValue(
                          context,
                          mobile: 12.0,
                          tablet: 13.0,
                          desktop: 14.0,
                        ),
                        color: AppColors.textWhite.withOpacity(0.9),
                      ),
                    ),
                  ),
                  Icon(
                    trend == 'up'
                        ? LucideIcons.trendingUp
                        : trend == 'down'
                            ? LucideIcons.trendingDown
                            : LucideIcons.minus,
                    size: 14,
                    color: trend == 'up'
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF22C55E),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '\$${predicted.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveValue(
                        context,
                        mobile: 13.0,
                        tablet: 14.0,
                        desktop: 15.0,
                      ),
                      fontWeight: FontWeight.w600,
                      color: overBudget ? const Color(0xFFF59E0B) : const Color(0xFF06B6D4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: overBudget
                          ? const Color(0xFFF59E0B).withOpacity(0.2)
                          : const Color(0xFF22C55E).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      overBudget ? 'Over' : 'OK',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: overBudget ? const Color(0xFFF59E0B) : const Color(0xFF22C55E),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 500.ms, duration: 500.ms)
        .slideY(begin: 0.2, end: 0, delay: 500.ms, duration: 500.ms);
  }

  Widget _buildTelegramButton(BuildContext context) {
    return GestureDetector(
      onTap: _handleTelegramBot,
      child: Container(
        width: Responsive.getResponsiveValue(
          context,
          mobile: 60.0,
          tablet: 64.0,
          desktop: 68.0,
        ),
        height: Responsive.getResponsiveValue(
          context,
          mobile: 60.0,
          tablet: 64.0,
          desktop: 68.0,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0088cc), Color(0xFF0077b5)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF06B6D4).withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
          border: Border.all(
            color: const Color(0xFF06B6D4).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SvgPicture.string(
            // Telegram paper-plane logo glyph (white) inside existing blue circle
            '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <path fill="#FFFFFF" d="M21.9 4.6c.3-1.4-1-2.5-2.3-2L2.7 8.6c-1.4.5-1.3 2.4.1 2.8l4.2 1.3 1.6 5.1c.4 1.3 2 1.7 3 .8l2.4-2.2 4.4 3.2c1 .7 2.4.2 2.6-1L21.9 4.6zM9.6 12.3l8-5.1c.3-.2.6.2.3.4l-6.7 6.1-.3 2.8-1.3-4.2z"/>
</svg>
''',
            width: 24,
            height: 24,
            fit: BoxFit.contain,
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 600.ms, duration: 500.ms)
        .scale(begin: const Offset(0, 0), end: const Offset(1, 1), delay: 600.ms, duration: 500.ms, curve: Curves.elasticOut);
  }
}
