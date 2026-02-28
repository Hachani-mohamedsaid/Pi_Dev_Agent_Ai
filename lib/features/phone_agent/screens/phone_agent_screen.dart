import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../data/phone_agent_mock_data.dart';
import '../models/phone_call_model.dart';

class PhoneAgentScreen extends StatefulWidget {
  const PhoneAgentScreen({super.key});

  @override
  State<PhoneAgentScreen> createState() => _PhoneAgentScreenState();
}

class _PhoneAgentScreenState extends State<PhoneAgentScreen> {
  String _filter = 'all'; // all, pending, scheduled, important

  List<PhoneCallModel> get _filteredCalls {
    final list = mockPhoneCalls;
    switch (_filter) {
      case 'pending':
        return list.where((c) => c.status == 'pending').toList();
      case 'scheduled':
        return list.where((c) => c.status == 'scheduled').toList();
      case 'important':
        return list.where((c) => c.priority == 'high').toList();
      default:
        return list;
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.getResponsiveValue(context, mobile: 18.0, tablet: 22.0, desktop: 26.0);
    final stats = _Stats.fromCalls(mockPhoneCalls);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0f2940), Color(0xFF1a3a52), Color(0xFF0f2940)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, padding),
              SizedBox(height: padding),
              _buildStatsGrid(context, stats, padding),
              SizedBox(height: 16),
              _buildFilterTabs(context),
              SizedBox(height: 12),
              Expanded(
                child: _filteredCalls.isEmpty
                    ? _buildEmpty(context)
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: padding, vertical: 8),
                        itemCount: _filteredCalls.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _filteredCalls.length) {
                            return _buildInsightCard(context, padding).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0, delay: 400.ms);
                          }
                          final call = _filteredCalls[index];
                          return _CallCard(
                            call: call,
                            onTap: () => context.push('/phone-agent-call', extra: call),
                          )
                              .animate()
                              .fadeIn(delay: Duration(milliseconds: 50 * index))
                              .slideY(begin: 0.08, end: 0, delay: Duration(milliseconds: 50 * index));
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double padding) {
    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 16, padding, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.cyan400),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            style: IconButton.styleFrom(
              backgroundColor: AppColors.cyan500.withOpacity(0.1),
              side: BorderSide(color: AppColors.cyan500.withOpacity(0.2)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.phone, color: AppColors.cyan400, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Phone Agent',
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveValue(context, mobile: 20.0, tablet: 22.0, desktop: 24.0),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'AI-powered call management',
                  style: TextStyle(fontSize: 12, color: AppColors.textCyan200.withOpacity(0.7)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, _Stats stats, double padding) {
    final items = [
      _StatItem('Total Calls', stats.total, LucideIcons.phone, const Color(0xFF06B6D4)),
      _StatItem('Pending', stats.pending, LucideIcons.clock, const Color(0xFFF97316)),
      _StatItem('Scheduled', stats.scheduled, LucideIcons.calendar, const Color(0xFF3B82F6)),
      _StatItem('Important', stats.important, LucideIcons.alertCircle, const Color(0xFFEF4444)),
    ];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
        physics: const NeverScrollableScrollPhysics(),
        children: items.asMap().entries.map((e) {
          final item = e.value;
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1e4a66).withOpacity(0.4),
                  const Color(0xFF16384d).withOpacity(0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cyan500.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(item.icon, color: item.color, size: 18),
                    Text(
                      '${item.value}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: item.color),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(fontSize: 12, color: AppColors.textCyan200.withOpacity(0.7)),
                ),
              ],
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: 50 * e.key)).slideY(begin: 0.1, end: 0, delay: Duration(milliseconds: 50 * e.key));
        }).toList(),
      ),
    );
  }

  Widget _buildFilterTabs(BuildContext context) {
    final tabs = [
      ('all', 'All Calls'),
      ('pending', 'Pending'),
      ('scheduled', 'Scheduled'),
      ('important', 'Important'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: tabs.map((t) {
          final selected = _filter == t.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _filter = t.$1),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.cyan500.withOpacity(0.3) : AppColors.cyan500.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? AppColors.cyan400.withOpacity(0.4) : AppColors.cyan500.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    t.$2,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: selected ? AppColors.textCyan200 : AppColors.textCyan200.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.phone, size: 64, color: AppColors.cyan400.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No calls in this category',
            style: TextStyle(color: AppColors.textCyan200.withOpacity(0.5), fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(BuildContext context, double padding) {
    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 16, padding, 24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFA855F7).withOpacity(0.2),
              const Color(0xFFEC4899).withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFA855F7).withOpacity(0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFA855F7).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.trendingUp, color: Color(0xFFC084FC), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Insight',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'You have 3 high-priority calls requiring immediate attention. Average response time: 2.5 hours. Most common inquiry: Pricing & Consultation.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.textCyan200.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stats {
  final int total;
  final int pending;
  final int scheduled;
  final int important;

  _Stats({required this.total, required this.pending, required this.scheduled, required this.important});

  static _Stats fromCalls(List<PhoneCallModel> calls) {
    return _Stats(
      total: calls.length,
      pending: calls.where((c) => c.status == 'pending').length,
      scheduled: calls.where((c) => c.status == 'scheduled').length,
      important: calls.where((c) => c.priority == 'high').length,
    );
  }
}

class _StatItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  _StatItem(this.label, this.value, this.icon, this.color);
}

class _CallCard extends StatelessWidget {
  final PhoneCallModel call;
  final VoidCallback onTap;

  const _CallCard({required this.call, required this.onTap});

  static Color _priorityColor(String p) {
    switch (p) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'medium':
        return const Color(0xFFFACC15);
      case 'low':
        return const Color(0xFF22C55E);
      default:
        return AppColors.cyan500;
    }
  }

  static Color _statusColor(String s) {
    switch (s) {
      case 'pending':
        return const Color(0xFFF97316);
      case 'scheduled':
        return const Color(0xFF3B82F6);
      case 'completed':
        return const Color(0xFF22C55E);
      case 'dismissed':
        return const Color(0xFF6B7280);
      default:
        return AppColors.cyan500;
    }
  }

  static String _categoryEmoji(String c) {
    switch (c) {
      case 'pricing':
        return '💰';
      case 'appointment':
        return '📅';
      case 'technical':
        return '⚙️';
      case 'general':
        return '💬';
      default:
        return '📞';
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor(call.priority);
    final statusColor = _statusColor(call.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1e4a66).withOpacity(0.4),
                  const Color(0xFF16384d).withOpacity(0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cyan500.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                call.callerName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              if (call.priority == 'high') ...[
                                const SizedBox(width: 6),
                                Icon(LucideIcons.star, size: 16, color: _priorityColor('high')),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            call.phoneNumber,
                            style: TextStyle(fontSize: 13, color: AppColors.textCyan200.withOpacity(0.6)),
                          ),
                        ],
                      ),
                    ),
                    Text(_categoryEmoji(call.category), style: const TextStyle(fontSize: 22)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  call.summary,
                  style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textCyan200.withOpacity(0.8)),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _chip(priorityColor, call.priority, hasDot: true),
                    _chip(statusColor, call.status, hasDot: false),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.clock, size: 12, color: AppColors.textCyan200.withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Text(
                          '${call.date} • ${call.time}',
                          style: TextStyle(fontSize: 11, color: AppColors.textCyan200.withOpacity(0.6)),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.phone, size: 12, color: AppColors.textCyan200.withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Text(
                          call.duration,
                          style: TextStyle(fontSize: 11, color: AppColors.textCyan200.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Icon(Icons.chevron_right, color: AppColors.cyan400.withOpacity(0.5), size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(Color bg, String label, {required bool hasDot}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bg.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasDot) ...[
            Container(width: 6, height: 6, decoration: BoxDecoration(color: bg, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: bg),
          ),
        ],
      ),
    );
  }
}
