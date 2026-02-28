import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../data/demo_products_data_source.dart';
import '../models/business_product.dart';
import '../models/business_session.dart';
import 'dashboard_style_screen.dart';

/// Main dashboard: overview, products (add/delete), analytics, AI insights.
class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key, required this.session});

  final BusinessSession session;

  @override
  State<BusinessDashboardScreen> createState() => _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> {
  static int _initialTabForStyle(int styleIndex) {
    switch (styleIndex) {
      case 0: return 1;
      case 1: return 2;
      case 2: return 3;
      case 3: return 0;
      default: return 0;
    }
  }

  late int _selectedIndex;
  List<BusinessProduct> _products = [];
  bool _demoLoading = false;
  final _productNameController = TextEditingController();
  final _productPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedIndex = _initialTabForStyle(widget.session.styleIndex);
    _products = _mockProducts();
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _productPriceController.dispose();
    super.dispose();
  }

  List<BusinessProduct> _mockProducts() {
    return [
      const BusinessProduct(id: '1', name: 'Produit A', price: 29.99, quantity: 12),
      const BusinessProduct(id: '2', name: 'Produit B', price: 49.50, quantity: 8),
      const BusinessProduct(id: '3', name: 'Produit C', price: 19.00, quantity: 25),
    ];
  }

  double get _totalRevenue => _products.fold(0.0, (sum, p) => sum + (p.price ?? 0) * p.quantity);
  double get _totalCost => _totalRevenue * 0.55;
  double get _profit => _totalRevenue - _totalCost;
  BusinessProduct? get _topProductByRevenue {
    if (_products.isEmpty) return null;
    return _products.reduce((a, b) {
      final va = (a.price ?? 0) * a.quantity;
      final vb = (b.price ?? 0) * b.quantity;
      return vb > va ? b : a;
    });
  }
  void _addProduct() {
    final name = _productNameController.text.trim();
    if (name.isEmpty) return;
    final price = double.tryParse(_productPriceController.text.trim());
    setState(() {
      _products = [
        ..._products,
        BusinessProduct(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          price: price,
          quantity: 0,
        ),
      ];
    });
    _productNameController.clear();
    _productPriceController.clear();
    if (mounted) Navigator.of(context).pop(true);
  }

  void _deleteProduct(String id) {
    setState(() => _products = _products.where((p) => p.id != id).toList());
  }

  /// Charge les produits depuis l’API publique Fake Store (internet). Compatible avec l’interface.
  Future<void> _loadDemoFromInternet() async {
    if (_demoLoading) return;
    setState(() => _demoLoading = true);
    try {
      final list = await fetchDemoProducts();
      if (!mounted) return;
      setState(() {
        _products = list;
        _demoLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(list.isEmpty ? 'Aucune donnée reçue' : '${list.length} produits chargés depuis Internet'),
            backgroundColor: AppColors.cyan500,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _demoLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur de chargement'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAddProductSheet() {
    _productNameController.clear();
    _productPriceController.clear();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16384d),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          Responsive.getResponsiveValue(context, mobile: 20.0, tablet: 24.0, desktop: 28.0),
          24,
          Responsive.getResponsiveValue(context, mobile: 20.0, tablet: 24.0, desktop: 28.0),
          MediaQuery.of(ctx).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Ajouter un produit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textWhite)),
            const SizedBox(height: 16),
            TextField(
              controller: _productNameController,
              style: const TextStyle(color: AppColors.textWhite),
              decoration: InputDecoration(
                hintText: 'Nom du produit',
                hintStyle: TextStyle(color: AppColors.textCyan200.withOpacity(0.5)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.06),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.cyan500.withOpacity(0.2))),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _productPriceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textWhite),
              decoration: InputDecoration(
                hintText: 'Prix (optionnel)',
                hintStyle: TextStyle(color: AppColors.textCyan200.withOpacity(0.5)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.06),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.cyan500.withOpacity(0.2))),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final styleInfo = DashboardStyleScreen.styles[widget.session.styleIndex.clamp(0, DashboardStyleScreen.styles.length - 1)];

    const tabLabels = ['Vue d\'ensemble', 'Produits', 'Analytics', 'Insights IA'];
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
                title: Text(styleInfo['title'] as String),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/my-business');
                  }
                },
              ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: List.generate(4, (i) {
                    final selected = _selectedIndex == i;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => setState(() => _selectedIndex = i),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.cyan500.withOpacity(0.25) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selected ? AppColors.cyan400 : AppColors.cyan500.withOpacity(0.2),
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              tabLabels[i],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                                color: selected ? AppColors.cyan400 : AppColors.textCyan200.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (Widget child, Animation<double> animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey<int>(_selectedIndex),
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: [
                        _buildOverviewTab(context, isMobile),
                        _buildProductsTab(context, isMobile),
                        _buildAnalyticsTab(context, isMobile),
                        _buildAiInsightsTab(context, isMobile),
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

  Widget _buildOverviewTab(BuildContext context, bool isMobile) {
    final pad = Responsive.getResponsiveValue(context, mobile: 12.0, tablet: 16.0, desktop: 20.0);
    return SingleChildScrollView(
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSiteLine(context).animate().fadeIn(duration: 280.ms).slideY(begin: 0.03, end: 0, duration: 280.ms, curve: Curves.easeOut),
          SizedBox(height: pad),
          _buildKpiCardsRow(context, isMobile),
          SizedBox(height: pad),
          if (isMobile) ...[
            _buildBarChartCard(context).animate().fadeIn(delay: 150.ms, duration: 350.ms).slideY(begin: 0.06, end: 0, delay: 150.ms, duration: 350.ms, curve: Curves.easeOut),
            SizedBox(height: pad),
            _buildDoughnutCard(context).animate().fadeIn(delay: 220.ms, duration: 350.ms).slideY(begin: 0.06, end: 0, delay: 220.ms, duration: 350.ms, curve: Curves.easeOut),
            SizedBox(height: pad),
            _buildMiniLineChartCard(context).animate().fadeIn(delay: 290.ms, duration: 350.ms).slideY(begin: 0.06, end: 0, delay: 290.ms, duration: 350.ms, curve: Curves.easeOut),
            SizedBox(height: pad),
            _buildProductsByRevenueList(context).animate().fadeIn(delay: 360.ms, duration: 350.ms).slideY(begin: 0.06, end: 0, delay: 360.ms, duration: 350.ms, curve: Curves.easeOut),
            SizedBox(height: pad),
            _buildMonthlySummaryCard(context).animate().fadeIn(delay: 430.ms, duration: 350.ms).slideY(begin: 0.06, end: 0, delay: 430.ms, duration: 350.ms, curve: Curves.easeOut),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildBarChartCard(context).animate().fadeIn(delay: 120.ms, duration: 380.ms).slideX(begin: -0.04, end: 0, delay: 120.ms, duration: 380.ms, curve: Curves.easeOut)),
                SizedBox(width: pad),
                Expanded(child: _buildDoughnutCard(context).animate().fadeIn(delay: 200.ms, duration: 380.ms).slideX(begin: 0.04, end: 0, delay: 200.ms, duration: 380.ms, curve: Curves.easeOut)),
              ],
            ),
            SizedBox(height: pad),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildMiniLineChartCard(context).animate().fadeIn(delay: 280.ms, duration: 380.ms).slideY(begin: 0.05, end: 0, delay: 280.ms, duration: 380.ms, curve: Curves.easeOut)),
                SizedBox(width: pad),
                Expanded(flex: 2, child: _buildProductsByRevenueList(context).animate().fadeIn(delay: 360.ms, duration: 380.ms).slideY(begin: 0.05, end: 0, delay: 360.ms, duration: 380.ms, curve: Curves.easeOut)),
                SizedBox(width: pad),
                Expanded(child: _buildMonthlySummaryCard(context).animate().fadeIn(delay: 440.ms, duration: 380.ms).slideY(begin: 0.05, end: 0, delay: 440.ms, duration: 380.ms, curve: Curves.easeOut)),
              ],
            ),
          ],
          SizedBox(height: pad),
        ],
      ),
    );
  }

  Widget _buildSiteLine(BuildContext context) {
    return Row(
      children: [
        Icon(LucideIcons.globe, color: AppColors.cyan400, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.session.websiteUrl,
            style: TextStyle(fontSize: 13, color: AppColors.textCyan200.withOpacity(0.8)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCardsRow(BuildContext context, bool isMobile) {
    final kpis = [
      {'label': 'Total Produits', 'value': '${_products.length}', 'icon': LucideIcons.package, 'color': const Color(0xFF8B5CF6)},
      {'label': 'Valeur Stock', 'value': _totalRevenue.toStringAsFixed(0), 'icon': LucideIcons.trendingUp, 'color': const Color(0xFF3B82F6)},
      {'label': 'Revenus est.', 'value': _totalRevenue >= 1000 ? '${(_totalRevenue / 1000).toStringAsFixed(1)}k' : _totalRevenue.toStringAsFixed(0), 'icon': LucideIcons.dollarSign, 'color': const Color(0xFFF59E0B)},
      {'label': 'Profit', 'value': '${_profit >= 0 ? '+' : ''}${_profit.toStringAsFixed(0)}', 'icon': _profit >= 0 ? LucideIcons.trendingUp : LucideIcons.trendingDown, 'color': _profit >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)},
    ];
    return Row(
      children: List.generate(kpis.length, (i) {
        final k = kpis[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < kpis.length - 1 ? 8 : 0),
            child: _kpiCard(context, k['value'] as String, k['label'] as String, k['icon'] as IconData, k['color'] as Color)
                .animate()
                .fadeIn(delay: Duration(milliseconds: 60 + i * 50), duration: 320.ms)
                .slideY(begin: 0.08, end: 0, delay: Duration(milliseconds: 60 + i * 50), duration: 320.ms, curve: Curves.easeOut),
          ),
        );
      }),
    );
  }

  Widget _kpiCard(BuildContext context, String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 22),
              Icon(LucideIcons.moreHorizontal, color: AppColors.textCyan200.withOpacity(0.5), size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textWhite)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.textCyan200.withOpacity(0.8))),
        ],
      ),
    );
  }

  static const Color _barPurple = Color(0xFF8B5CF6);
  static const Color _barGreen = Color(0xFF10B981);

  Widget _buildBarChartCard(BuildContext context) {
    final sorted = List<BusinessProduct>.from(_products)
      ..sort((a, b) => ((b.price ?? 0) * b.quantity).compareTo((a.price ?? 0) * a.quantity));
    final top = sorted.take(6).toList();
    if (top.isEmpty) return _emptyChartCard(context, 'CA par produit');
    final maxY = top.fold<double>(0, (m, p) => (m > (p.price ?? 0) * p.quantity ? m : (p.price ?? 0) * p.quantity));
    final spots = top.asMap().entries.map((e) => BarChartGroupData(
      x: e.key,
      barRods: [BarChartRodData(toY: maxY > 0 ? ((e.value.price ?? 0) * e.value.quantity) / maxY * 4 : 0, color: e.key.isEven ? _barPurple : _barGreen, width: 14, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))],
      showingTooltipIndicators: [0],
    )).toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CA par produit', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textWhite)),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 4.5,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        if (groupIndex >= top.length) return null;
                        final ca = (top[groupIndex].price ?? 0) * top[groupIndex].quantity;
                        return BarTooltipItem(
                          ca.toStringAsFixed(ca == ca.truncateToDouble() ? 0 : 2),
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                        );
                      },
                      getTooltipColor: (group) {
                        if (group.barRods.isEmpty) return _barPurple.withOpacity(0.9);
                        final c = group.barRods.first.gradient?.colors.first ?? group.barRods.first.color;
                        return (c ?? _barPurple).withOpacity(0.9);
                      },
                      tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      tooltipRoundedRadius: 6,
                      maxContentWidth: 80,
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) => Text('P${v.toInt() + 1}', style: TextStyle(fontSize: 10, color: AppColors.textCyan200.withOpacity(0.8))))),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: spots,
                ),
                duration: Duration.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoughnutCard(BuildContext context) {
    final sorted = List<BusinessProduct>.from(_products)
      ..sort((a, b) => ((b.price ?? 0) * b.quantity).compareTo((a.price ?? 0) * a.quantity));
    final top = sorted.take(4).toList();
    if (top.isEmpty) return _emptyChartCard(context, 'Répartition CA');
    final total = _totalRevenue;
    if (total <= 0) return _emptyChartCard(context, 'Répartition CA');
    final colors = [const Color(0xFF8B5CF6), const Color(0xFF10B981), const Color(0xFFF59E0B), const Color(0xFF3B82F6)];
    final sections = top.asMap().entries.map((e) => PieChartSectionData(
      value: ((e.value.price ?? 0) * e.value.quantity),
      color: colors[e.key % colors.length],
      radius: 28,
      showTitle: false,
    )).toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text('Répartition CA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textWhite)),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: PieChart(
              PieChartData(sections: sections, sectionsSpace: 2, centerSpaceRadius: 32),
              duration: Duration.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniLineChartCard(BuildContext context) {
    final mockSpots = [0.5, 1.2, 0.8, 1.5, 1.0, 1.8].asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tendance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textWhite)),
          const SizedBox(height: 8),
          SizedBox(
            height: 70,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(enabled: false),
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(spots: mockSpots, isCurved: true, color: AppColors.cyan400, barWidth: 2, dotData: FlDotData(show: false), belowBarData: BarAreaData(show: true, color: AppColors.cyan400.withOpacity(0.15))),
                ],
              ),
              duration: Duration.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsByRevenueList(BuildContext context) {
    final sorted = List<BusinessProduct>.from(_products)
      ..sort((a, b) => ((b.price ?? 0) * b.quantity).compareTo((a.price ?? 0) * a.quantity));
    final top = sorted.take(5).toList();
    if (top.isEmpty) return _emptyChartCard(context, 'Produits par CA');
    final icons = [LucideIcons.package, LucideIcons.box, LucideIcons.gift, LucideIcons.shoppingBag, LucideIcons.tag];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Produits par CA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textWhite)),
          const SizedBox(height: 10),
          ...top.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: AppColors.cyan400.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icons[e.key % icons.length], color: AppColors.cyan400, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(e.value.name, style: TextStyle(fontSize: 13, color: AppColors.textWhite), maxLines: 1, overflow: TextOverflow.ellipsis)),
                Text(((e.value.price ?? 0) * e.value.quantity).toStringAsFixed(0), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.cyan400)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildMonthlySummaryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ce mois', style: TextStyle(fontSize: 12, color: AppColors.textCyan200.withOpacity(0.8))),
          const SizedBox(height: 6),
          Text(_totalRevenue.toStringAsFixed(0), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textWhite)),
          Text('Revenus estim.', style: TextStyle(fontSize: 11, color: AppColors.textCyan200.withOpacity(0.8))),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(enabled: false),
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [const FlSpot(0, 1), const FlSpot(1, 1.5), const FlSpot(2, 1.2), const FlSpot(3, 1.8), const FlSpot(4, 1.6), const FlSpot(5, 2)],
                    isCurved: true,
                    color: AppColors.cyan400,
                    barWidth: 1.5,
                    dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 2, color: AppColors.cyan400)),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
              duration: Duration.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyChartCard(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textWhite)),
          const SizedBox(height: 12),
          Icon(LucideIcons.barChart2, size: 40, color: AppColors.cyan400.withOpacity(0.4)),
          const SizedBox(height: 6),
          Text('Ajoute des produits', style: TextStyle(fontSize: 12, color: AppColors.textCyan200.withOpacity(0.5))),
        ],
      ),
    );
  }

  Widget _buildProductsTab(BuildContext context, bool isMobile) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 20.0, desktop: 24.0),
            12,
            Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 20.0, desktop: 24.0),
            8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_products.length} produit(s)', style: TextStyle(fontSize: 14, color: AppColors.textCyan200.withOpacity(0.8))),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: _demoLoading ? null : _loadDemoFromInternet,
                    icon: _demoLoading ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyan400)) : Icon(LucideIcons.download, size: 18, color: AppColors.cyan400),
                    label: Text(_demoLoading ? 'Chargement...' : 'Données démo', style: TextStyle(color: AppColors.cyan400, fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                  TextButton.icon(
                    onPressed: _showAddProductSheet,
                    icon: Icon(LucideIcons.plus, size: 18, color: AppColors.cyan400),
                    label: Text('Ajouter', style: TextStyle(color: AppColors.cyan400, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.package, size: 48, color: AppColors.cyan400.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      Text('Aucun produit', style: TextStyle(fontSize: 15, color: AppColors.textCyan200.withOpacity(0.8))),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _showAddProductSheet,
                        icon: Icon(LucideIcons.plus, size: 18, color: AppColors.cyan400),
                        label: Text('Ajouter un produit', style: TextStyle(color: AppColors.cyan400)),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _demoLoading ? null : _loadDemoFromInternet,
                        icon: _demoLoading ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyan400)) : Icon(LucideIcons.globe, size: 18, color: AppColors.cyan400),
                        label: Text(_demoLoading ? 'Chargement...' : 'Charger données démo (Internet)', style: TextStyle(color: AppColors.cyan400, fontSize: 13)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 20.0, desktop: 24.0)),
                  itemCount: _products.length,
                  itemBuilder: (context, i) {
                    final p = _products[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 14.0, tablet: 16.0, desktop: 18.0)),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cyan500.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textWhite)),
                                const SizedBox(height: 4),
                                Text('Qté: ${p.quantity}${p.price != null ? " • ${p.price!.toStringAsFixed(2)}" : ""}', style: TextStyle(fontSize: 12, color: AppColors.textCyan200.withOpacity(0.8))),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _deleteProduct(p.id),
                            icon: Icon(LucideIcons.trash2, size: 20, color: Colors.red.withOpacity(0.9)),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: 40 * i), duration: 280.ms)
                        .slideX(begin: 0.04, end: 0, delay: Duration(milliseconds: 40 * i), duration: 280.ms, curve: Curves.easeOut);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab(BuildContext context, bool isMobile) {
    final pad = Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 20.0, desktop: 24.0);
    final sortedByRevenue = List<BusinessProduct>.from(_products)
      ..sort((a, b) => ((b.price ?? 0) * b.quantity).compareTo((a.price ?? 0) * a.quantity));
    return SingleChildScrollView(
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAnalyticsSummaryCard(context).animate().fadeIn(duration: 300.ms).slideY(begin: 0.04, end: 0, duration: 300.ms, curve: Curves.easeOut),
          SizedBox(height: pad),
          _buildAnalyticsRevenueCard(context).animate().fadeIn(delay: 80.ms, duration: 320.ms).slideY(begin: 0.04, end: 0, delay: 80.ms, duration: 320.ms, curve: Curves.easeOut),
          if (sortedByRevenue.isNotEmpty) SizedBox(height: pad),
          if (sortedByRevenue.isNotEmpty) _buildTopProductsList(context, sortedByRevenue.take(5).toList()).animate().fadeIn(delay: 160.ms, duration: 320.ms).slideY(begin: 0.04, end: 0, delay: 160.ms, duration: 320.ms, curve: Curves.easeOut),
          if (sortedByRevenue.isNotEmpty) SizedBox(height: pad),
          Container(
            padding: EdgeInsets.all(pad),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cyan500.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.info, color: AppColors.cyan400, size: 20),
                    const SizedBox(width: 8),
                    Text('Évolution', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textWhite)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Ajoute régulièrement tes ventes réelles pour voir les tendances. Plus tu renseignes de données, plus les statistiques et conseils seront précis.',
                  style: TextStyle(fontSize: 13, color: AppColors.textCyan200.withOpacity(0.8), height: 1.4),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 240.ms, duration: 320.ms).slideY(begin: 0.04, end: 0, delay: 240.ms, duration: 320.ms, curve: Curves.easeOut),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSummaryCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 20.0, tablet: 24.0, desktop: 28.0)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF1e4a66).withOpacity(0.6), const Color(0xFF16384d).withOpacity(0.6)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.barChart3, size: 40, color: AppColors.cyan400),
          const SizedBox(height: 12),
          Text('Tableau de bord analytics', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textWhite)),
          const SizedBox(height: 6),
          Text('Statistiques calculées à partir de tes produits.', style: TextStyle(fontSize: 13, color: AppColors.textCyan200.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _buildAnalyticsRevenueCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 18.0, tablet: 22.0, desktop: 26.0)),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chiffre d\'affaires (estim.)', style: TextStyle(fontSize: 13, color: AppColors.textCyan200.withOpacity(0.8))),
          const SizedBox(height: 6),
          Text(_totalRevenue.toStringAsFixed(2), style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF34D399))),
          const SizedBox(height: 8),
          Text('Coûts estim.: ${_totalCost.toStringAsFixed(2)} • Profit: ${_profit.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, color: AppColors.textCyan200.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _buildTopProductsList(BuildContext context, List<BusinessProduct> topList) {
    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 20.0, desktop: 24.0)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.arrowUpCircle, color: AppColors.cyan400, size: 20),
              const SizedBox(width: 8),
              Text('Top ${topList.length} produits (CA)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textWhite)),
            ],
          ),
          const SizedBox(height: 12),
          ...topList.asMap().entries.map((e) {
            final i = e.key + 1;
            final p = e.value;
            final ca = (p.price ?? 0) * p.quantity;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.cyan500.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: Text('$i', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.cyan400)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(p.name, style: TextStyle(fontSize: 14, color: AppColors.textWhite), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Text(ca.toStringAsFixed(0), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF34D399))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAiInsightsTab(BuildContext context, bool isMobile) {
    final pad = Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 20.0, desktop: 24.0);
    final top = _topProductByRevenue;
    final advice = <Map<String, String>>[
      {'title': 'Catalogue', 'text': 'Tu as ${_products.length} produit(s). Renseigne les prix et quantités pour des stats et conseils plus précis.'},
      {'title': 'Stocks', 'text': 'Révise tes stocks régulièrement pour éviter les ruptures et les surplus.'},
      {'title': 'Mise en avant', 'text': 'Mets en avant tes meilleurs produits (ex. ${top?.name ?? "top produit"}) sur la page d’accueil.'},
      {'title': 'Profit', 'text': _profit >= 0 ? 'Ton profit estimé est positif. Continue à suivre les coûts pour garder une bonne marge.' : 'Vérifie tes coûts et tes prix pour améliorer la rentabilité.'},
      {'title': 'Prochaines étapes', 'text': 'Connecte ton site ou importe tes ventes réelles pour des analytics encore plus utiles.'},
    ];
    return SingleChildScrollView(
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 20.0, tablet: 24.0, desktop: 28.0)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFF8B5CF6).withOpacity(0.25), const Color(0xFF06B6D4).withOpacity(0.18)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cyan500.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.sparkles, color: AppColors.cyan400, size: 28),
                    const SizedBox(width: 10),
                    Text('Insights IA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textWhite)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Recommandations et conseils pour ton activité.', style: TextStyle(fontSize: 13, color: AppColors.textCyan200.withOpacity(0.8))),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.04, end: 0, duration: 300.ms, curve: Curves.easeOut),
          SizedBox(height: pad),
          ...List.generate(advice.length, (i) {
            final a = advice[i];
            return Padding(
              padding: EdgeInsets.only(bottom: pad),
              child: Container(
                padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0)),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cyan500.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.lightbulb, color: const Color(0xFFFBBF24), size: 20),
                        const SizedBox(width: 8),
                        Text(a['title']!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.cyan400)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(a['text']!, style: TextStyle(fontSize: 13, color: AppColors.textCyan200.withOpacity(0.8), height: 1.4)),
                  ],
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: 80 + i * 70), duration: 320.ms).slideX(begin: 0.03, end: 0, delay: Duration(milliseconds: 80 + i * 70), duration: 320.ms, curve: Curves.easeOut),
            );
          }),
        ],
      ),
    );
  }
}
