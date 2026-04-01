import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../data/services/open_weather_service.dart';

class SavedTravelRequest {
  const SavedTravelRequest({
    required this.from,
    required this.to,
    required this.createdAt,
    required this.scheduleCount,
  });

  final String from;
  final String to;
  final DateTime createdAt;
  final int scheduleCount;
}

class TravelScheduleSlot {
  static const Object _noChange = Object();
  static const Object _noDateChange = Object();

  const TravelScheduleSlot({
    required this.time,
    required this.weekdays,
    required this.enabled,
    this.adjustedTime,
    this.lastSyncedAt,
    this.ruleId,
  });

  final TimeOfDay time;
  final Set<int> weekdays;
  final bool enabled;
  final TimeOfDay? adjustedTime;
  final DateTime? lastSyncedAt;
  final String? ruleId;

  TravelScheduleSlot copyWith({
    TimeOfDay? time,
    Set<int>? weekdays,
    bool? enabled,
    Object? adjustedTime = _noChange,
    Object? lastSyncedAt = _noDateChange,
    String? ruleId,
  }) {
    return TravelScheduleSlot(
      time: time ?? this.time,
      weekdays: weekdays ?? this.weekdays,
      enabled: enabled ?? this.enabled,
      adjustedTime: adjustedTime == _noChange
          ? this.adjustedTime
          : adjustedTime as TimeOfDay?,
      lastSyncedAt: lastSyncedAt == _noDateChange
          ? this.lastSyncedAt
          : lastSyncedAt as DateTime?,
      ruleId: ruleId ?? this.ruleId,
    );
  }
}

class TravelSchedulePlan {
  const TravelSchedulePlan({
    required this.fromLocation,
    required this.toLocation,
    required this.slots,
    required this.bestPriceWindowEnabled,
    required this.bestPriceWindowMinutes,
    required this.savedRequests,
  });

  final String fromLocation;
  final String toLocation;
  final List<TravelScheduleSlot> slots;
  final bool bestPriceWindowEnabled;
  final int bestPriceWindowMinutes;
  final List<SavedTravelRequest> savedRequests;
}

class TravelSchedulePage extends StatefulWidget {
  const TravelSchedulePage({
    required this.initialFromLocation,
    required this.initialToLocation,
    required this.initialSlots,
    required this.initialBestPriceWindowEnabled,
    required this.initialBestPriceWindowMinutes,
    required this.initialSavedRequests,
    required this.baseMinPrice,
    required this.baseMaxPrice,
    required this.baseEtaMinutes,
    super.key,
  });

  final String initialFromLocation;
  final String initialToLocation;
  final List<TravelScheduleSlot> initialSlots;
  final bool initialBestPriceWindowEnabled;
  final int initialBestPriceWindowMinutes;
  final List<SavedTravelRequest> initialSavedRequests;
  final double? baseMinPrice;
  final double? baseMaxPrice;
  final int? baseEtaMinutes;

  @override
  State<TravelSchedulePage> createState() => _TravelSchedulePageState();
}

class _TravelSchedulePageState extends State<TravelSchedulePage> {
  static const Map<int, String> _weekdayShortLabel = <int, String>{
    DateTime.monday: 'Mon',
    DateTime.tuesday: 'Tue',
    DateTime.wednesday: 'Wed',
    DateTime.thursday: 'Thu',
    DateTime.friday: 'Fri',
    DateTime.saturday: 'Sat',
    DateTime.sunday: 'Sun',
  };

  static final Set<int> _defaultWorkdays = <int>{
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
  };

  late final TextEditingController _fromController;
  late final TextEditingController _toController;
  late List<TravelScheduleSlot> _slots;
  late bool _bestPriceWindowEnabled;
  late int _bestPriceWindowMinutes;
  late List<SavedTravelRequest> _savedRequests;
  late bool _fromUsesCurrentLocationPlaceholder;

  bool _loadingFromSuggestions = false;
  bool _loadingToSuggestions = false;
  List<CitySuggestion> _fromSuggestions = const <CitySuggestion>[];
  List<CitySuggestion> _toSuggestions = const <CitySuggestion>[];

  @override
  void initState() {
    super.initState();
    final initialFrom = widget.initialFromLocation.trim();
    _fromUsesCurrentLocationPlaceholder =
        initialFrom.toLowerCase() == 'current location';
    _fromController = TextEditingController(
      text: _fromUsesCurrentLocationPlaceholder
          ? ''
          : widget.initialFromLocation,
    );
    _toController = TextEditingController(text: widget.initialToLocation);
    _slots = widget.initialSlots.isEmpty
        ? <TravelScheduleSlot>[
            TravelScheduleSlot(
              time: const TimeOfDay(hour: 8, minute: 0),
              weekdays: Set<int>.from(_defaultWorkdays),
              enabled: true,
            ),
          ]
        : widget.initialSlots
              .map(
                (slot) => TravelScheduleSlot(
                  time: slot.time,
                  weekdays: Set<int>.from(slot.weekdays),
                  enabled: slot.enabled,
                  adjustedTime: slot.adjustedTime,
                  lastSyncedAt: slot.lastSyncedAt,
                  ruleId: slot.ruleId,
                ),
              )
              .toList(growable: true);
    _bestPriceWindowEnabled = widget.initialBestPriceWindowEnabled;
    _bestPriceWindowMinutes = widget.initialBestPriceWindowMinutes <= 0
        ? 30
        : widget.initialBestPriceWindowMinutes;
    _savedRequests = widget.initialSavedRequests.toList(growable: true);
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<void> _loadFromSuggestions(String query) async {
    if (query.trim().length < 2) {
      if (!mounted) return;
      setState(() {
        _fromSuggestions = const <CitySuggestion>[];
        _loadingFromSuggestions = false;
      });
      return;
    }

    setState(() => _loadingFromSuggestions = true);
    final results = await OpenWeatherService.getCitySuggestions(query);
    if (!mounted) return;
    if (_fromController.text.trim() != query.trim()) return;
    setState(() {
      _fromSuggestions = results;
      _loadingFromSuggestions = false;
    });
  }

  Future<void> _loadToSuggestions(String query) async {
    if (query.trim().length < 2) {
      if (!mounted) return;
      setState(() {
        _toSuggestions = const <CitySuggestion>[];
        _loadingToSuggestions = false;
      });
      return;
    }

    setState(() => _loadingToSuggestions = true);
    final results = await OpenWeatherService.getCitySuggestions(query);
    if (!mounted) return;
    if (_toController.text.trim() != query.trim()) return;
    setState(() {
      _toSuggestions = results;
      _loadingToSuggestions = false;
    });
  }

  void _selectFromSuggestion(CitySuggestion suggestion) {
    setState(() {
      _fromController.text = suggestion.displayName;
      _fromSuggestions = const <CitySuggestion>[];
    });
  }

  void _selectToSuggestion(CitySuggestion suggestion) {
    setState(() {
      _toController.text = suggestion.displayName;
      _toSuggestions = const <CitySuggestion>[];
    });
  }

  String _formatRequestDateTime(DateTime value) {
    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final hh = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$dd/$mm $hh:$min';
  }

  Future<void> _pickScheduleTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _slots[index].time,
    );
    if (picked == null) return;
    setState(() {
      _slots[index] = _slots[index].copyWith(
        time: picked,
        adjustedTime: null,
        lastSyncedAt: null,
      );
    });
  }

  String _formatTime24(TimeOfDay time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _formatSyncedDateTime(DateTime value) {
    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final yyyy = value.year.toString();
    final hh = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }

  Color _syncedFreshnessColor(DateTime syncedAt) {
    final age = DateTime.now().difference(syncedAt);
    if (age < const Duration(hours: 1)) {
      return Colors.lightGreenAccent;
    }
    if (age < const Duration(hours: 24)) {
      return Colors.orangeAccent;
    }
    return Colors.redAccent;
  }

  String _syncedFreshnessLabel(DateTime syncedAt) {
    final age = DateTime.now().difference(syncedAt);
    if (age < const Duration(hours: 1)) {
      return 'Fresh';
    }
    if (age < const Duration(hours: 24)) {
      return 'Aging';
    }
    return 'Stale';
  }

  int _minutesOfDay(TimeOfDay time) => time.hour * 60 + time.minute;

  String _adjustmentDeltaLabel(TimeOfDay planned, TimeOfDay adjusted) {
    var delta = _minutesOfDay(adjusted) - _minutesOfDay(planned);
    if (delta > 720) delta -= 1440;
    if (delta < -720) delta += 1440;
    if (delta == 0) return 'no shift';
    final sign = delta > 0 ? '+' : '';
    return '$sign${delta} min';
  }

  double _priceMultiplier(TravelScheduleSlot slot) {
    final hour = slot.time.hour;
    final isPeak = (hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 20);
    final isNight = hour >= 22 || hour <= 5;
    final includesWeekend =
        slot.weekdays.contains(DateTime.friday) ||
        slot.weekdays.contains(DateTime.saturday) ||
        slot.weekdays.contains(DateTime.sunday);

    var multiplier = 1.0;
    if (isPeak) multiplier += 0.22;
    if (isNight) multiplier += 0.10;
    if (includesWeekend) multiplier += 0.08;
    return multiplier;
  }

  String? _estimatedPriceLabel(TravelScheduleSlot slot) {
    final minPrice = widget.baseMinPrice;
    final maxPrice = widget.baseMaxPrice;
    if (minPrice == null || maxPrice == null) {
      return null;
    }

    final factor = _priceMultiplier(slot);
    final adjustedMin = minPrice * factor;
    final adjustedMax = maxPrice * factor;
    return '${adjustedMin.toStringAsFixed(1)}-${adjustedMax.toStringAsFixed(1)} AED';
  }

  String? _estimatedEtaLabel(TravelScheduleSlot slot) {
    final eta = widget.baseEtaMinutes;
    if (eta == null) return null;

    final hour = slot.time.hour;
    final trafficPenalty =
        ((hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 20)) ? 4 : 0;
    final weekendPenalty =
        slot.weekdays.contains(DateTime.friday) ||
            slot.weekdays.contains(DateTime.saturday)
        ? 2
        : 0;
    return '${eta + trafficPenalty + weekendPenalty} min';
  }

  String _daySummary(Set<int> weekdays) {
    if (weekdays.length == 7) return 'Every day';
    final ordered = weekdays.toList()..sort();
    return ordered
        .map((day) => _weekdayShortLabel[day] ?? day.toString())
        .join(', ');
  }

  void _toggleWeekday(int index, int day, bool selected) {
    final next = Set<int>.from(_slots[index].weekdays);
    if (selected) {
      next.add(day);
    } else {
      next.remove(day);
    }

    if (next.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select at least one day.')));
      return;
    }

    setState(() {
      _slots[index] = _slots[index].copyWith(
        weekdays: next,
        adjustedTime: null,
        lastSyncedAt: null,
      );
    });
  }

  void _setSlotEnabled(int index, bool enabled) {
    setState(() {
      _slots[index] = _slots[index].copyWith(
        enabled: enabled,
        adjustedTime: null,
        lastSyncedAt: null,
      );
    });
  }

  void _addSlot() {
    setState(() {
      _slots.add(
        TravelScheduleSlot(
          time: const TimeOfDay(hour: 8, minute: 0),
          weekdays: Set<int>.from(_defaultWorkdays),
          enabled: true,
          adjustedTime: null,
          lastSyncedAt: null,
        ),
      );
    });
  }

  void _removeSlot(int index) {
    if (_slots.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one schedule is required.')),
      );
      return;
    }

    setState(() {
      _slots.removeAt(index);
    });
  }

  void _loadSavedRequest(SavedTravelRequest request) {
    setState(() {
      _fromController.text = request.from;
      _toController.text = request.to;
      _fromSuggestions = const <CitySuggestion>[];
      _toSuggestions = const <CitySuggestion>[];
    });
  }

  void _deleteSavedRequest(int index) {
    setState(() {
      _savedRequests.removeAt(index);
    });
  }

  void _saveSchedule() {
    final from =
        _fromController.text.trim().isEmpty &&
            _fromUsesCurrentLocationPlaceholder
        ? widget.initialFromLocation.trim()
        : _fromController.text.trim();
    final to = _toController.text.trim();
    if (from.isEmpty || to.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('From and To are required.')),
      );
      return;
    }

    if (_slots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one schedule.')),
      );
      return;
    }

    final nextSaved = <SavedTravelRequest>[
      SavedTravelRequest(
        from: from,
        to: to,
        createdAt: DateTime.now(),
        scheduleCount: _slots.length,
      ),
      ..._savedRequests,
    ];

    Navigator.of(context).pop(
      TravelSchedulePlan(
        fromLocation: from,
        toLocation: to,
        slots: _slots,
        bestPriceWindowEnabled: _bestPriceWindowEnabled,
        bestPriceWindowMinutes: _bestPriceWindowMinutes,
        savedRequests: nextSaved,
      ),
    );
  }

  void _handleBackPressed() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Widget _buildSuggestions(
    List<CitySuggestion> suggestions,
    bool loading,
    ValueChanged<CitySuggestion> onTap,
  ) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: LinearProgressIndicator(
          minHeight: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan400),
          backgroundColor: Colors.transparent,
        ),
      );
    }
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryMedium.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderCyan),
      ),
      child: Column(
        children: suggestions
            .take(5)
            .map(
              (item) => ListTile(
                dense: true,
                leading: const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: AppColors.cyan400,
                ),
                title: Text(
                  item.displayName,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () => onTap(item),
                hoverColor: AppColors.primaryLight.withOpacity(0.5),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  Widget _buildSavedRequestsPanel() {
    if (_savedRequests.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderCyan),
        ),
        child: Text(
          'Saved requests list is empty.',
          style: TextStyle(color: Colors.white.withOpacity(0.85)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderCyan),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saved requests',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.cyan400,
            ),
          ),
          const SizedBox(height: 8),
          ..._savedRequests
              .asMap()
              .entries
              .take(8)
              .map((entry) {
                final index = entry.key;
                final item = entry.value;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.bookmark_added_outlined,
                    size: 18,
                    color: AppColors.cyan400,
                  ),
                  title: Text(
                    '${item.from} → ${item.to}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '${item.scheduleCount} schedules • ${_formatRequestDateTime(item.createdAt)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _loadSavedRequest(item),
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.cyan400,
                        ),
                        tooltip: 'Load (edit)',
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _deleteSavedRequest(index),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        tooltip: 'Delete',
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                );
              })
              .toList(growable: false),
        ],
      ),
    );
  }

  Widget _buildSlotCard(int index) {
    final slot = _slots[index];
    final estimatedPrice = _estimatedPriceLabel(slot);
    final estimatedEta = _estimatedEtaLabel(slot);
    final activeBorderColor = slot.enabled
        ? AppColors.cyan400.withOpacity(0.65)
        : AppColors.borderCyan;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: activeBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.cyan500.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.borderCyan),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: AppColors.cyan400,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Schedule',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.cyan400,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _daySummary(slot.weekdays),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.72),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    slot.enabled ? 'Active' : 'Paused',
                    style: TextStyle(
                      color: slot.enabled
                          ? Colors.lightGreenAccent
                          : Colors.white.withOpacity(0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Switch.adaptive(
                    value: slot.enabled,
                    onChanged: (value) => _setSlotEnabled(index, value),
                  ),
                ],
              ),
              if (_slots.length > 1)
                IconButton(
                  onPressed: () => _removeSlot(index),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  tooltip: 'Remove schedule',
                ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _pickScheduleTime(index),
              icon: const Icon(Icons.schedule, color: AppColors.cyan400),
              label: Text(
                'Departure at ${slot.time.format(context)}',
                style: const TextStyle(
                  color: AppColors.cyan400,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.cyan400),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _weekdayShortLabel.entries
                .map((entry) {
                  final selected = slot.weekdays.contains(entry.key);
                  return FilterChip(
                    label: Text(
                      entry.value,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: selected,
                    selectedColor: AppColors.cyan500.withOpacity(0.52),
                    backgroundColor: Colors.black.withOpacity(0.22),
                    side: BorderSide(
                      color: selected
                          ? AppColors.cyan400
                          : AppColors.borderCyan,
                    ),
                    showCheckmark: false,
                    onSelected: (isSelected) =>
                        _toggleWeekday(index, entry.key, isSelected),
                  );
                })
                .toList(growable: false),
          ),
          if (estimatedPrice != null || estimatedEta != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (estimatedPrice != null)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderCyan),
                      ),
                      child: Text(
                        'Est. price\n$estimatedPrice',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.88),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                if (estimatedPrice != null && estimatedEta != null)
                  const SizedBox(width: 10),
                if (estimatedEta != null)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderCyan),
                      ),
                      child: Text(
                        'ETA\n$estimatedEta',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.88),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Text(
            'Days: ${_daySummary(slot.weekdays)}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              fontSize: 12,
            ),
          ),
          if (slot.adjustedTime != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.lightGreenAccent.withOpacity(0.18),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.lightGreenAccent.withOpacity(0.55),
                ),
              ),
              child: Text(
                'Final synced: ${_formatTime24(slot.adjustedTime!)} (${_adjustmentDeltaLabel(slot.time, slot.adjustedTime!)})',
                style: const TextStyle(
                  color: Colors.lightGreenAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
          if (slot.lastSyncedAt != null) ...[
            const SizedBox(height: 6),
            Builder(
              builder: (context) {
                final freshnessColor = _syncedFreshnessColor(
                  slot.lastSyncedAt!,
                );
                final freshnessLabel = _syncedFreshnessLabel(
                  slot.lastSyncedAt!,
                );
                return Row(
                  children: [
                    Icon(Icons.cloud_done, size: 16, color: freshnessColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Synced ${_formatSyncedDateTime(slot.lastSyncedAt!)}',
                        style: TextStyle(
                          color: freshnessColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: freshnessColor.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: freshnessColor.withOpacity(0.6),
                        ),
                      ),
                      child: Text(
                        freshnessLabel,
                        style: TextStyle(
                          color: freshnessColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: _handleBackPressed,
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: Colors.white,
        ),
        title: const Text(
          'Taxi Clock Planner',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            children: [
              Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppColors.cardGradient,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.borderCyan),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.route_outlined,
                              color: AppColors.cyan400,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Route details',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.cyan400,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose pickup and destination. Suggestions appear as you type.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.72),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'From',
                          style: TextStyle(
                            color: AppColors.cyan400,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _fromController,
                          onChanged: (value) => _loadFromSuggestions(value),
                          decoration: InputDecoration(
                            hintText: _fromUsesCurrentLocationPlaceholder
                                ? widget.initialFromLocation
                                : 'Type city name (ex: Tunis, Dubai)',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                            ),
                            filled: true,
                            fillColor: Colors.black.withOpacity(0.14),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.borderCyan,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: AppColors.cyan400,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        _buildSuggestions(
                          _fromSuggestions,
                          _loadingFromSuggestions,
                          _selectFromSuggestion,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'To',
                          style: TextStyle(
                            color: AppColors.cyan400,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _toController,
                          onChanged: (value) => _loadToSuggestions(value),
                          decoration: InputDecoration(
                            hintText: 'Type city name (ex: Dubai Marina)',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                            ),
                            filled: true,
                            fillColor: Colors.black.withOpacity(0.14),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.borderCyan,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: AppColors.cyan400,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        _buildSuggestions(
                          _toSuggestions,
                          _loadingToSuggestions,
                          _selectToSuggestion,
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: const Duration(milliseconds: 400))
                  .slideY(
                    begin: 0.2,
                    end: 0,
                    duration: const Duration(milliseconds: 400),
                  ),
              const SizedBox(height: 14),
              Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppColors.cardGradient,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.borderCyan),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.calendar_month_outlined,
                              color: AppColors.cyan400,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Departure rules',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.cyan400,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Create one or more schedules for your regular taxi rides.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.72),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...List<Widget>.generate(_slots.length, _buildSlotCard),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _addSlot,
                            icon: const Icon(
                              Icons.add_alarm,
                              color: AppColors.cyan400,
                            ),
                            label: const Text(
                              'Add another schedule',
                              style: TextStyle(
                                color: AppColors.cyan400,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.cyan400),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 100),
                  )
                  .slideY(
                    begin: 0.2,
                    end: 0,
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 100),
                  ),
              const SizedBox(height: 14),
              Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppColors.cardGradient,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.borderCyanFocus),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.tune_outlined,
                              color: AppColors.cyan400,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Best price window',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.cyan400,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderCyan),
                          ),
                          child: SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            value: _bestPriceWindowEnabled,
                            onChanged: (value) {
                              setState(() => _bestPriceWindowEnabled = value);
                            },
                            title: const Text(
                              'Enable cost optimization',
                              style: TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              'Try nearby times before saving rules to reduce estimated cost.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        if (_bestPriceWindowEnabled) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: [15, 30, 45]
                                .map(
                                  (minutes) => ChoiceChip(
                                    label: Text('±$minutes min'),
                                    selected:
                                        _bestPriceWindowMinutes == minutes,
                                    selectedColor: AppColors.cyan500
                                        .withOpacity(0.7),
                                    labelStyle: TextStyle(
                                      color: _bestPriceWindowMinutes == minutes
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.85),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                        color: AppColors.borderCyan,
                                      ),
                                    ),
                                    onSelected: (_) {
                                      setState(
                                        () => _bestPriceWindowMinutes = minutes,
                                      );
                                    },
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        ],
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 200),
                  )
                  .slideY(
                    begin: 0.2,
                    end: 0,
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 200),
                  ),
              const SizedBox(height: 14),
              Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppColors.cardGradient,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.borderCyan),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: AppColors.cyan400,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'How estimates work',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.cyan400,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Price and ETA are computed per schedule based on selected time and days.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.78),
                            fontSize: 12,
                          ),
                        ),
                        if (_bestPriceWindowEnabled) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Best price window active: the app checks ${_bestPriceWindowMinutes} min before and after each time.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.84),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 300),
                  )
                  .slideY(
                    begin: 0.2,
                    end: 0,
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 300),
                  ),
              const SizedBox(height: 18),
              Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.buttonGradient,
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                    child: FilledButton.icon(
                      onPressed: _saveSchedule,
                      icon: const Icon(Icons.alarm_on),
                      label: const Text(
                        'Save all schedules',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 15,
                        ),
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 400),
                  )
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.0, 1.0),
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 400),
                  ),
              const SizedBox(height: 12),
              _buildSavedRequestsPanel()
                  .animate()
                  .fadeIn(
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 500),
                  )
                  .slideY(
                    begin: 0.2,
                    end: 0,
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 500),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
