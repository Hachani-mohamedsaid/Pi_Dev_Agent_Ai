import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/network/request_headers.dart';
import '../../core/observability/sentry_api.dart';
import '../../injection_container.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/mobility_api_service.dart';
import 'travel_schedule_page.dart';
import '../widgets/navigation_bar.dart';

class TravelPage extends StatefulWidget {
  const TravelPage({super.key});

  @override
  State<TravelPage> createState() => _TravelPageState();
}

class _TravelPageState extends State<TravelPage> with WidgetsBindingObserver {
  static const Duration _providerPendingTimeout = Duration(seconds: 90);
  static const LatLng _defaultTestHub = LatLng(
    25.20485,
    55.27078,
  ); // Downtown Dubai

  final TextEditingController _destinationController = TextEditingController();
  final MapController _mapController = MapController();
  final MobilityApiService _mobilityApiService = InjectionContainer.instance
      .buildMobilityApiService();

  Position? _currentPosition;
  LatLng? _pickupLatLng;
  LatLng? _destinationLatLng;

  // Autocomplete suggestions
  List<Map<String, dynamic>> _placeSuggestions = const [];
  bool _loadingSuggestions = false;
  Timer? _suggestionDebounce;

  // Instant vs scheduled
  bool _rideNow = true;

  bool _loadingLocation = true;
  bool _loadingRoute = false;
  bool _loadingEstimate = false;
  bool _confirmingBooking = false;
  bool _syncingDailyRule = false;
  bool _dailyRuleEnabled = false;
  bool _bestPriceWindowEnabled = false;
  int _bestPriceWindowMinutes = 30;
  bool _selectingFromOnMap = false;
  bool _estimateRetryPending = false;
  String? _errorMessage;
  String? _bookingStatusMessage;
  String? _estimateInfoMessage;
  String? _lastMobilityErrorCode;
  String? _lastMobilityErrorBody;
  String? _lastBookingBackendStatus;
  bool _pollingProposalStatus = false;
  bool _refreshingProposalStatus = false;
  bool _submittingDriverDecision = false;
  DateTime? _proposalPendingSince;
  final Set<String> _locallyDecidedBookingIds = <String>{};
  final List<String> _proposalStatusHistory = <String>[];
  List<LatLng> _nearbyTaxiPoints = const <LatLng>[];
  bool _loadingNearbyTaxis = false;
  final Distance _distanceCalc = const Distance();

  List<LatLng> _routePoints = const <LatLng>[];
  double? _distanceKm;
  double? _durationMin;
  MobilityEstimateResponse? _estimate;
  MobilityProposal? _latestProposal;
  MobilityBooking? _latestBooking;
  String? _latestProposalOfferLabel;
  String _plannedFromLocation = 'Current location';
  List<SavedTravelRequest> _savedScheduleRequests =
      const <SavedTravelRequest>[];
  TimeOfDay _plannedTime = const TimeOfDay(hour: 8, minute: 0);
  List<TravelScheduleSlot> _scheduleSlots = <TravelScheduleSlot>[
    TravelScheduleSlot(
      time: TimeOfDay(hour: 8, minute: 0),
      weekdays: <int>{
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
      },
      enabled: false,
      adjustedTime: null,
      lastSyncedAt: null,
    ),
  ];
  int _estimateRetryAttempts = 0;

  StreamSubscription<Position>? _positionSubscription;
  Timer? _estimateRetryTimer;
  Timer? _proposalStatusTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLocation();
    _loadDailyRule();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionSubscription?.cancel();
    _estimateRetryTimer?.cancel();
    _proposalStatusTimer?.cancel();
    _suggestionDebounce?.cancel();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _fetchPlaceSuggestions(String query) async {
    if (query.length < 2) {
      setState(() => _placeSuggestions = const []);
      return;
    }
    setState(() => _loadingSuggestions = true);
    try {
      final center = _currentPosition == null
          ? _defaultTestHub
          : LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeQueryComponent(query)}'
        '&format=json&limit=5'
        '&viewbox=${center.longitude - 0.5},${center.latitude + 0.5},${center.longitude + 0.5},${center.latitude - 0.5}'
        '&bounded=0',
      );
      final response = await http
          .get(
            uri,
            headers: const {
              'Accept-Language': 'en',
              'User-Agent': 'pi_dev_agentia',
            },
          )
          .timeout(const Duration(seconds: 6));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          _placeSuggestions = list.whereType<Map<String, dynamic>>().toList(
            growable: false,
          );
          _loadingSuggestions = false;
        });
      } else {
        setState(() {
          _placeSuggestions = const [];
          _loadingSuggestions = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _placeSuggestions = const [];
        _loadingSuggestions = false;
      });
    }
  }

  void _selectSuggestion(Map<String, dynamic> place) {
    final lat = double.tryParse(place['lat']?.toString() ?? '');
    final lon = double.tryParse(place['lon']?.toString() ?? '');
    final name = (place['display_name'] as String? ?? '')
        .split(',')
        .take(2)
        .join(', ');
    if (lat == null || lon == null) return;
    setState(() {
      _destinationLatLng = LatLng(lat, lon);
      _destinationController.text = name;
      _placeSuggestions = const [];
    });
    _mapController.move(LatLng(lat, lon), 14.0);
    unawaited(_buildRoute());
    unawaited(_fetchMobilityEstimate());
  }

  Future<void> _useCurrentLocationAsPickup() async {
    await _loadLocation();

    if (!mounted) return;

    final current = _currentPosition;
    if (current == null) {
      final errorMessage =
          _errorMessage ?? 'Impossible de récupérer ta localisation.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          action: SnackBarAction(
            label: 'Réglages',
            textColor: Colors.white,
            onPressed: () => openAppSettings(),
          ),
        ),
      );
      return;
    }

    setState(() {
      _pickupLatLng = LatLng(current.latitude, current.longitude);
      _selectingFromOnMap = false;
      _errorMessage = null;
    });

    _mapController.move(_pickupLatLng!, 15.5);
    unawaited(_buildRoute());
    unawaited(_fetchMobilityEstimate());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Ta position actuelle a été utilisée comme pickup.',
        ),
        backgroundColor: AppColors.cyan400.withValues(alpha: 0.95),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  DateTime _effectivePickupDateTime() {
    if (_rideNow) return DateTime.now().add(const Duration(minutes: 2));
    return _nextPickupDateTime();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;

    if (_latestProposal == null || _latestProposal!.id.isEmpty) {
      unawaited(_recoverLatestProposalFromBackend(silent: true));
      return;
    }

    unawaited(_refreshLatestProposalStatus(silent: true));
  }

  Future<void> _loadLocation() async {
    setState(() {
      _loadingLocation = true;
      _errorMessage = null;
    });

    try {
      // Fast path: center map instantly on last known position while accurate
      // GPS loads in the background.
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && mounted) {
        setState(() => _currentPosition = lastKnown);
        _mapController.move(
          LatLng(lastKnown.latitude, lastKnown.longitude),
          15.0,
        );
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _loadingLocation = false;
          _errorMessage = 'Active la localisation sur ton téléphone.';
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _loadingLocation = false;
          _errorMessage = permission == LocationPermission.deniedForever
              ? 'La localisation est bloquée. Ouvre les réglages iPhone pour autoriser l’app.'
              : 'Autorise la localisation pour utiliser "My location" ou ouvre les réglages iPhone.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _loadingLocation = false;
        _errorMessage = null;
      });

      _startLiveLocationStream();
      _mapController.move(LatLng(position.latitude, position.longitude), 15.0);
      unawaited(_fetchNearbyTaxiStations());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingLocation = false;
        _errorMessage =
            'Impossible de récupérer ta localisation sur iPhone. Vérifie les réglages de localisation.';
      });
    }
  }

  void _startLiveLocationStream() {
    _positionSubscription?.cancel();
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 15,
          ),
        ).listen((position) {
          if (!mounted) return;
          setState(() => _currentPosition = position);
        });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _plannedTime,
    );
    if (picked != null) {
      setState(() {
        _plannedTime = picked;
        if (_scheduleSlots.isNotEmpty) {
          _scheduleSlots[0] = _scheduleSlots[0].copyWith(
            time: picked,
            adjustedTime: null,
            lastSyncedAt: null,
          );
        }
      });
      if (_dailyRuleEnabled) {
        unawaited(_syncDailyRule(enabled: true));
      }
    }
  }

  Future<void> _buildRoute() async {
    final from =
        _pickupLatLng ??
        (_currentPosition == null
            ? null
            : LatLng(_currentPosition!.latitude, _currentPosition!.longitude));

    if (from == null || _destinationLatLng == null) {
      return;
    }

    setState(() {
      _loadingRoute = true;
      _errorMessage = null;
    });

    try {
      final origin = '${from.longitude},${from.latitude}';
      final destination =
          '${_destinationLatLng!.longitude},${_destinationLatLng!.latitude}';

      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$origin;$destination?overview=full&geometries=geojson',
      );
      final response = await http.get(uri, headers: buildJsonHeaders());

      if (response.statusCode != 200) {
        reportHttpResponseError(
          feature: 'travel.route.osrm',
          response: response,
        );
        throw Exception('Routing failed: ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = decoded['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) {
        setState(() {
          _loadingRoute = false;
          _errorMessage = 'No route found for this destination.';
        });
        return;
      }

      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>?;
      final coordinates = geometry?['coordinates'] as List<dynamic>?;

      if (coordinates == null || coordinates.isEmpty) {
        throw Exception('No polyline coordinates returned.');
      }

      final points = coordinates
          .map((coord) {
            final lon = (coord as List<dynamic>)[0] as num;
            final lat = coord[1] as num;
            return LatLng(lat.toDouble(), lon.toDouble());
          })
          .toList(growable: false);

      final distanceMeters = (route['distance'] as num?)?.toDouble() ?? 0;
      final durationSeconds = (route['duration'] as num?)?.toDouble() ?? 0;

      if (!mounted) return;
      setState(() {
        _routePoints = points;
        _distanceKm = distanceMeters / 1000;
        _durationMin = durationSeconds / 60;
        _loadingRoute = false;
      });
    } catch (error, stackTrace) {
      reportApiException(
        feature: 'travel.route.osrm',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      setState(() {
        _loadingRoute = false;
        _errorMessage = 'Failed to build route.';
      });
    }
  }

  DateTime _nextPickupDateTime() {
    final now = DateTime.now();
    var dt = DateTime(
      now.year,
      now.month,
      now.day,
      _plannedTime.hour,
      _plannedTime.minute,
    );
    if (dt.isBefore(now)) {
      dt = dt.add(const Duration(days: 1));
    }
    return dt;
  }

  Future<void> _fetchMobilityEstimate() async {
    final destination = _destinationController.text.trim();
    if (destination.isEmpty || _distanceKm == null || _durationMin == null) {
      return;
    }

    final fromPoint =
        _pickupLatLng ??
        (_currentPosition == null
            ? null
            : LatLng(_currentPosition!.latitude, _currentPosition!.longitude));

    if (fromPoint == null) {
      return;
    }

    setState(() {
      _loadingEstimate = true;
      _errorMessage = null;
      _bookingStatusMessage = null;
      _estimateInfoMessage = null;
      _lastMobilityErrorCode = null;
      _lastMobilityErrorBody = null;
    });

    try {
      final estimate = await _mobilityApiService.estimateQuotes(
        from: _pickupLatLng == null
            ? 'Current location'
            : 'Map selected pickup',
        to: destination,
        pickupAt: _effectivePickupDateTime(),
        fromLatitude: fromPoint.latitude,
        fromLongitude: fromPoint.longitude,
        toLatitude: _destinationLatLng?.latitude,
        toLongitude: _destinationLatLng?.longitude,
      );
      if (!mounted) return;
      setState(() {
        _estimate = estimate;
        _loadingEstimate = false;
        _estimateRetryPending = false;
        _estimateRetryAttempts = 0;
        _estimateInfoMessage = 'Live estimate loaded from backend.';
      });
      _estimateRetryTimer?.cancel();
    } on MobilityApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingEstimate = false;
        _estimate = null;
        _estimateInfoMessage = 'No live estimate available (${e.code}).';
        _errorMessage = _mobilityErrorMessage(e);
        _lastMobilityErrorCode = e.code;
        _lastMobilityErrorBody = _truncateForDebug(e.body);
      });
      if (_shouldAutoRetryEstimate(e.code)) {
        _scheduleEstimateRetry();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingEstimate = false;
        _estimate = null;
        _estimateInfoMessage = 'Unable to fetch backend live estimates.';
        _errorMessage = 'Unable to fetch backend live estimates.';
        _lastMobilityErrorCode = 'unknown_exception';
        _lastMobilityErrorBody = null;
      });
      _scheduleEstimateRetry();
    }
  }

  String? _truncateForDebug(String? value) {
    if (value == null || value.isEmpty) return null;
    const maxLen = 280;
    if (value.length <= maxLen) return value;
    return '${value.substring(0, maxLen)}...';
  }

  void _scheduleEstimateRetry() {
    if (_estimateRetryPending || _estimateRetryAttempts >= 3) {
      return;
    }

    _estimateRetryPending = true;
    _estimateRetryAttempts += 1;
    final attempt = _estimateRetryAttempts;

    if (mounted) {
      setState(() {
        _estimateInfoMessage =
            '${_estimateInfoMessage ?? 'No live estimate available.'} Auto-retry in 10s (#$attempt).';
      });
    }

    _estimateRetryTimer?.cancel();
    _estimateRetryTimer = Timer(const Duration(seconds: 10), () {
      _estimateRetryPending = false;
      if (!mounted) return;
      if (_estimate == null && !_loadingEstimate) {
        unawaited(_fetchMobilityEstimate());
      }
    });
  }

  bool _shouldAutoRetryEstimate(String code) {
    final normalized = code.toLowerCase();
    if (normalized == 'login_required' ||
        normalized == 'unauthorized' ||
        normalized == 'http_401') {
      return false;
    }

    if (normalized.startsWith('http_')) {
      final status = int.tryParse(normalized.replaceFirst('http_', ''));
      if (status != null && status >= 400 && status < 500) {
        return false;
      }
    }

    return true;
  }

  String _mobilityErrorMessage(MobilityApiException e) {
    switch (e.code) {
      case 'login_required':
        return 'Please log in to use live mobility backend.';
      case 'unauthorized':
      case 'http_401':
        return 'Session expired or invalid token. Please log out and log in again.';
      default:
        return 'Mobility backend error (${e.code}).';
    }
  }

  String _toCron(TimeOfDay t, Set<int> weekdays) {
    if (weekdays.isEmpty || weekdays.length == 7) {
      return '${t.minute} ${t.hour} * * *';
    }

    final dayValues =
        weekdays.map((day) => day == DateTime.sunday ? 0 : day).toList()
          ..sort();
    final dayExpr = dayValues.join(',');
    return '${t.minute} ${t.hour} * * $dayExpr';
  }

  String _weekdaysLabel(Set<int> weekdays) {
    if (weekdays.length == 7) return 'Every day';
    const labels = <int, String>{
      DateTime.monday: 'Mon',
      DateTime.tuesday: 'Tue',
      DateTime.wednesday: 'Wed',
      DateTime.thursday: 'Thu',
      DateTime.friday: 'Fri',
      DateTime.saturday: 'Sat',
      DateTime.sunday: 'Sun',
    };
    final ordered = weekdays.toList()..sort();
    return ordered.map((day) => labels[day] ?? day.toString()).join(', ');
  }

  void _syncPrimaryPickupFromSchedules() {
    if (_scheduleSlots.isEmpty) return;
    final preferred = _scheduleSlots.firstWhere(
      (slot) => slot.enabled,
      orElse: () => _scheduleSlots.first,
    );
    _plannedTime = preferred.time;
  }

  Set<int>? _cronDayExprToWeekdays(String dayExpr) {
    if (dayExpr == '*') {
      return <int>{
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
        DateTime.saturday,
        DateTime.sunday,
      };
    }

    final parts = dayExpr.split(',').map((e) => e.trim()).toList();
    final days = <int>{};
    for (final part in parts) {
      final value = int.tryParse(part);
      if (value == null || value < 0 || value > 7) {
        return null;
      }
      days.add(value == 0 || value == 7 ? DateTime.sunday : value);
    }
    return days.isEmpty ? null : days;
  }

  TravelScheduleSlot? _slotFromRule(MobilityRule rule) {
    final segments = rule.cron.trim().split(RegExp(r'\s+'));
    if (segments.length < 5) return null;

    final minute = int.tryParse(segments[0]);
    final hour = int.tryParse(segments[1]);
    final weekdays = _cronDayExprToWeekdays(segments[4]);
    if (minute == null || hour == null || weekdays == null) {
      return null;
    }
    if (minute < 0 || minute > 59 || hour < 0 || hour > 23) {
      return null;
    }

    return TravelScheduleSlot(
      ruleId: rule.id,
      time: TimeOfDay(hour: hour, minute: minute),
      adjustedTime: TimeOfDay(hour: hour, minute: minute),
      lastSyncedAt: null,
      weekdays: weekdays,
      enabled: rule.enabled,
    );
  }

  void _setAllScheduleEnabled(bool enabled) {
    _dailyRuleEnabled = enabled;
    _scheduleSlots = _scheduleSlots
        .map(
          (slot) => slot.copyWith(
            enabled: enabled,
            adjustedTime: null,
            lastSyncedAt: null,
          ),
        )
        .toList(growable: true);
    _syncPrimaryPickupFromSchedules();
  }

  TimeOfDay _offsetTime(TimeOfDay value, int deltaMinutes) {
    final total = (value.hour * 60 + value.minute + deltaMinutes) % 1440;
    final normalized = total < 0 ? total + 1440 : total;
    return TimeOfDay(hour: normalized ~/ 60, minute: normalized % 60);
  }

  DateTime _slotPickupDateTime(TimeOfDay time) {
    final now = DateTime.now();
    var dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (dt.isBefore(now)) {
      dt = dt.add(const Duration(days: 1));
    }
    return dt;
  }

  Future<TimeOfDay> _resolveBestWindowTime({
    required TravelScheduleSlot slot,
    required String destination,
    required int windowMinutes,
  }) async {
    if (windowMinutes <= 0) return slot.time;

    final candidates = <TimeOfDay>[
      _offsetTime(slot.time, -windowMinutes),
      slot.time,
      _offsetTime(slot.time, windowMinutes),
    ];

    final uniqueCandidates = <TimeOfDay>[];
    final seen = <String>{};
    for (final candidate in candidates) {
      final key = '${candidate.hour}:${candidate.minute}';
      if (seen.add(key)) {
        uniqueCandidates.add(candidate);
      }
    }

    final fromPoint =
        _pickupLatLng ??
        (_currentPosition == null
            ? null
            : LatLng(_currentPosition!.latitude, _currentPosition!.longitude));

    double? bestPrice;
    TimeOfDay bestTime = slot.time;

    for (final candidate in uniqueCandidates) {
      try {
        final estimate = await _mobilityApiService.estimateQuotes(
          from: _pickupLatLng == null
              ? 'Current location'
              : 'Map selected pickup',
          to: destination,
          pickupAt: _slotPickupDateTime(candidate),
          fromLatitude: fromPoint?.latitude,
          fromLongitude: fromPoint?.longitude,
          toLatitude: _destinationLatLng?.latitude,
          toLongitude: _destinationLatLng?.longitude,
        );

        final option =
            estimate.best ??
            (estimate.options.isEmpty ? null : estimate.options.first);
        if (option == null) continue;

        if (bestPrice == null || option.minPrice < bestPrice) {
          bestPrice = option.minPrice;
          bestTime = candidate;
        }
      } catch (_) {
        // Keep current best candidate when estimate fails for one window edge.
      }
    }

    return bestTime;
  }

  Future<void> _openSchedulePlanner() async {
    final plan = await Navigator.of(context).push<TravelSchedulePlan>(
      MaterialPageRoute(
        builder: (_) => TravelSchedulePage(
          initialFromLocation: _plannedFromLocation,
          initialToLocation: _destinationController.text.trim(),
          initialSlots: _scheduleSlots,
          initialBestPriceWindowEnabled: _bestPriceWindowEnabled,
          initialBestPriceWindowMinutes: _bestPriceWindowMinutes,
          initialSavedRequests: _savedScheduleRequests,
          baseMinPrice: _estimate?.best?.minPrice,
          baseMaxPrice: _estimate?.best?.maxPrice,
          baseEtaMinutes: _estimate?.best?.etaMinutes,
        ),
      ),
    );

    if (plan == null || !mounted) return;

    setState(() {
      _scheduleSlots = plan.slots
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
      _dailyRuleEnabled = _scheduleSlots.any((slot) => slot.enabled);
      _bestPriceWindowEnabled = plan.bestPriceWindowEnabled;
      _bestPriceWindowMinutes = plan.bestPriceWindowMinutes;
      _savedScheduleRequests = plan.savedRequests;
      _syncPrimaryPickupFromSchedules();
      _plannedFromLocation = plan.fromLocation;
      _destinationController.text = plan.toLocation;
      _errorMessage = null;
    });

    final parsedDestination = _parseLatLngInput(plan.toLocation);
    if (parsedDestination != null) {
      setState(() {
        _destinationLatLng = parsedDestination;
      });
      await _buildRoute();
      await _fetchMobilityEstimate();
    }

    if (!mounted) return;
    if (_dailyRuleEnabled) {
      await _syncDailyRule(enabled: true);
    }
  }

  String _clientTimezone() {
    final tz = DateTime.now().timeZoneName.trim();
    return tz.isEmpty ? 'UTC' : tz;
  }

  String _coordsLabel(LatLng point) {
    return '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
  }

  LatLng? _parseLatLngInput(String raw) {
    final parts = raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
    if (parts.length != 2) return null;

    final lat = double.tryParse(parts[0]);
    final lng = double.tryParse(parts[1]);
    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;

    return LatLng(lat, lng);
  }

  Future<void> _applyManualDestination() async {
    final parsed = _parseLatLngInput(_destinationController.text.trim());
    if (parsed == null) {
      setState(() {
        _errorMessage =
            'Manual destination format: latitude, longitude (example: 36.80421, 10.17453).';
      });
      return;
    }

    setState(() {
      _destinationLatLng = parsed;
      _destinationController.text = _coordsLabel(parsed);
      _errorMessage = null;
      _bookingStatusMessage = null;
    });

    await _buildRoute();
    await _fetchMobilityEstimate();
  }

  Future<void> _onMapTapped(LatLng point) async {
    setState(() {
      _errorMessage = null;
      _bookingStatusMessage = null;
      if (_selectingFromOnMap) {
        _pickupLatLng = point;
        _selectingFromOnMap = false;
      } else {
        _destinationLatLng = point;
        _destinationController.text = _coordsLabel(point);
      }
    });

    if (_destinationLatLng != null) {
      await _buildRoute();
      await _fetchMobilityEstimate();
    }
  }

  Future<void> _openFullMapSelection() async {
    final fullMapController = MapController();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (routeContext) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Scaffold(
                backgroundColor: const Color(0xFF0f2940),
                appBar: AppBar(
                  title: const Text('Full Map Selection (A -> B)'),
                  backgroundColor: const Color(0xFF16384d),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Done'),
                    ),
                  ],
                ),
                body: Stack(
                  children: [
                    FlutterMap(
                      mapController: fullMapController,
                      options: MapOptions(
                        initialCenter:
                            _destinationLatLng ??
                            _pickupLatLng ??
                            _initialCenter,
                        initialZoom: 12.8,
                        minZoom: 3,
                        maxZoom: 19,
                        onTap: (_, point) async {
                          await _onMapTapped(point);
                          setModalState(() {});
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'pi_dev_agentia',
                        ),
                        if (_routePoints.isNotEmpty)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _routePoints,
                                strokeWidth: 5,
                                color: AppColors.cyan400,
                              ),
                            ],
                          ),
                        MarkerLayer(
                          markers: [
                            if (_driverLatLng() != null)
                              Marker(
                                point: _driverLatLng()!,
                                width: 44,
                                height: 44,
                                child: const Icon(
                                  Icons.local_taxi,
                                  color: Colors.lightGreenAccent,
                                  size: 30,
                                ),
                              ),
                            if (_currentPosition != null)
                              Marker(
                                point: LatLng(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                ),
                                width: 44,
                                height: 44,
                                child: const Icon(
                                  Icons.my_location,
                                  color: Colors.blue,
                                  size: 28,
                                ),
                              ),
                            if (_pickupLatLng != null)
                              Marker(
                                point: _pickupLatLng!,
                                width: 44,
                                height: 44,
                                child: const Icon(
                                  Icons.trip_origin,
                                  color: Colors.orangeAccent,
                                  size: 28,
                                ),
                              ),
                            if (_destinationLatLng != null)
                              Marker(
                                point: _destinationLatLng!,
                                width: 48,
                                height: 48,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.redAccent,
                                  size: 30,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.58),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _selectingFromOnMap
                              ? 'Tap map to set A (From).'
                              : 'Tap map to set B (Destination).',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                floatingActionButton: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton.extended(
                      heroTag: 'toggle-from-full-map',
                      onPressed: () {
                        setState(() {
                          _selectingFromOnMap = !_selectingFromOnMap;
                        });
                        setModalState(() {});
                      },
                      icon: Icon(
                        _selectingFromOnMap
                            ? Icons.touch_app
                            : Icons.trip_origin,
                      ),
                      label: Text(
                        _selectingFromOnMap ? 'Selecting A' : 'Select A',
                      ),
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton.extended(
                      heroTag: 'center-full-map',
                      onPressed: () {
                        final center =
                            _destinationLatLng ??
                            _pickupLatLng ??
                            _initialCenter;
                        fullMapController.move(center, 13.5);
                      },
                      icon: const Icon(Icons.center_focus_strong),
                      label: const Text('Center'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _loadDailyRule() async {
    try {
      final rules = await _mobilityApiService.fetchRules();
      if (!mounted) return;
      final existing = rules
          .where((r) {
            return r.name == 'Daily commute template' ||
                r.name.startsWith('Daily commute template #');
          })
          .toList(growable: false);
      if (existing.isEmpty) return;

      final loadedSlots = <TravelScheduleSlot>[];
      for (final rule in existing) {
        final slot = _slotFromRule(rule);
        if (slot != null) {
          loadedSlots.add(slot);
        }
      }

      if (loadedSlots.isEmpty) return;

      setState(() {
        _scheduleSlots = loadedSlots;
        _dailyRuleEnabled = loadedSlots.any((slot) => slot.enabled);
        _syncPrimaryPickupFromSchedules();
      });
    } catch (_) {
      // Non-blocking: travel still works without daily rule sync.
    }
  }

  Future<void> _syncDailyRule({required bool enabled}) async {
    final destination = _destinationController.text.trim();
    if (destination.isEmpty) {
      setState(() {
        _dailyRuleEnabled = false;
        _errorMessage = 'Set destination before enabling the daily rule.';
      });
      return;
    }

    setState(() {
      _syncingDailyRule = true;
      _errorMessage = null;
    });

    try {
      final existingRules = await _mobilityApiService.fetchRules();
      final existingByName = <String, MobilityRule>{
        for (final rule in existingRules)
          if (rule.name == 'Daily commute template' ||
              rule.name.startsWith('Daily commute template #'))
            rule.name: rule,
      };

      var slotsForSync = _scheduleSlots
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

      if (enabled && _bestPriceWindowEnabled) {
        for (var i = 0; i < slotsForSync.length; i += 1) {
          final slot = slotsForSync[i];
          if (!slot.enabled) continue;
          final bestTime = await _resolveBestWindowTime(
            slot: slot,
            destination: destination,
            windowMinutes: _bestPriceWindowMinutes,
          );
          slotsForSync[i] = slot.copyWith(adjustedTime: bestTime);
        }
      }

      final updatedSlots = <TravelScheduleSlot>[];
      final usedNames = <String>{};
      final syncedAt = DateTime.now();

      for (var i = 0; i < slotsForSync.length; i += 1) {
        final slot = slotsForSync[i];
        final name = 'Daily commute template #${i + 1}';
        usedNames.add(name);

        final effectiveTime = enabled && slot.enabled
            ? (slot.adjustedTime ?? slot.time)
            : slot.time;
        final cron = _toCron(effectiveTime, slot.weekdays);
        final existing = existingByName[name];
        final finalAdjustedTime = enabled && slot.enabled
            ? effectiveTime
            : null;
        final finalSyncedAt = enabled && slot.enabled ? syncedAt : null;

        if (existing == null) {
          final created = await _mobilityApiService.createRule(
            name: name,
            from: _plannedFromLocation,
            to: destination,
            timezone: _clientTimezone(),
            cron: cron,
            enabled: enabled && slot.enabled,
            requireUserApproval: true,
          );
          updatedSlots.add(
            slot.copyWith(
              ruleId: created?.id,
              adjustedTime: finalAdjustedTime,
              lastSyncedAt: finalSyncedAt,
            ),
          );
        } else {
          await _mobilityApiService.updateRule(
            ruleId: existing.id,
            patch: {
              'enabled': enabled && slot.enabled,
              'to': destination,
              'cron': cron,
              'requireUserApproval': true,
            },
          );
          updatedSlots.add(
            slot.copyWith(
              ruleId: existing.id,
              adjustedTime: finalAdjustedTime,
              lastSyncedAt: finalSyncedAt,
            ),
          );
        }
      }

      for (final entry in existingByName.entries) {
        if (usedNames.contains(entry.key)) continue;
        await _mobilityApiService.updateRule(
          ruleId: entry.value.id,
          patch: {'enabled': false, 'requireUserApproval': true},
        );
      }

      if (!mounted) return;
      setState(() {
        _scheduleSlots = updatedSlots;
        _dailyRuleEnabled = enabled;
        _syncingDailyRule = false;
      });
    } on MobilityApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _syncingDailyRule = false;
        _setAllScheduleEnabled(!enabled);
        _errorMessage = _mobilityErrorMessage(e);
        _lastMobilityErrorCode = e.code;
        _lastMobilityErrorBody = _truncateForDebug(e.body);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _syncingDailyRule = false;
        _setAllScheduleEnabled(!enabled);
        _errorMessage = 'Failed to sync daily rule with backend.';
      });
    }
  }

  String _normalizeStatus(String? status) {
    final value = (status ?? '').trim();
    if (value.isEmpty) return 'PENDING';
    return value.toUpperCase();
  }

  String _nowClock() {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  void _appendStatusHistory(String status) {
    final normalized = _normalizeStatus(status);
    final entry = '${_nowClock()} - $normalized';
    if (_proposalStatusHistory.isNotEmpty &&
        _proposalStatusHistory.last.endsWith(normalized)) {
      return;
    }
    _proposalStatusHistory.add(entry);
    if (_proposalStatusHistory.length > 8) {
      _proposalStatusHistory.removeAt(0);
    }
  }

  Color _statusAccentColor(String status) {
    switch (_normalizeStatus(status)) {
      case 'CONFIRMED':
      case 'ACCEPTED':
      case 'COMPLETED':
        return Colors.greenAccent;
      case 'REJECTED':
      case 'FAILED':
      case 'CANCELED':
      case 'CANCELLED':
      case 'EXPIRED':
        return Colors.redAccent;
      default:
        return Colors.orangeAccent;
    }
  }

  Future<void> _cancelCurrentProposal() async {
    final proposal = _latestProposal;
    if (proposal == null || proposal.id.isEmpty) return;

    final confirmCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel taxi request'),
          content: const Text(
            'Do you want to cancel this request from the application?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Yes, cancel'),
            ),
          ],
        );
      },
    );

    if (confirmCancel != true) return;

    try {
      await _mobilityApiService.rejectProposal(proposal.id);
      if (!mounted) return;
      setState(() {
        _proposalStatusTimer?.cancel();
        _pollingProposalStatus = false;
        _proposalPendingSince = null;
        _locallyDecidedBookingIds.clear();
        _lastBookingBackendStatus = 'REJECTED';
        _latestBooking = null;
        _latestProposal = MobilityProposal(
          id: proposal.id,
          from: proposal.from,
          to: proposal.to,
          status: 'REJECTED',
          provider: proposal.provider,
        );
        _bookingStatusMessage = 'Taxi request canceled from app.';
        _appendStatusHistory('REJECTED');
      });
    } on MobilityApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _lastMobilityErrorCode = e.code;
        _lastMobilityErrorBody = _truncateForDebug(e.body);
        _errorMessage = 'Unable to cancel request (${e.code}).';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _lastMobilityErrorCode = 'unknown_exception';
        _lastMobilityErrorBody = null;
        _errorMessage = 'Unable to cancel request right now.';
      });
    }
  }

  Future<void> _submitDriverDecision({required bool accept}) async {
    final booking = _latestBooking;
    if (booking == null || booking.id.isEmpty) {
      setState(() {
        _errorMessage = 'No booking available for driver decision.';
      });
      return;
    }

    setState(() {
      _submittingDriverDecision = true;
      _errorMessage = null;
    });

    try {
      if (accept) {
        await _mobilityApiService.acceptDriver(booking.id);
      } else {
        await _mobilityApiService.rejectDriver(booking.id);
      }

      if (!mounted) return;
      setState(() {
        _locallyDecidedBookingIds.add(booking.id);
        _bookingStatusMessage = accept
            ? 'Driver accepted by user. Refreshing status...'
            : 'Driver rejected by user. Refreshing status...';
      });
      await _refreshLatestProposalStatus();
    } on MobilityApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _lastMobilityErrorCode = e.code;
        _lastMobilityErrorBody = _truncateForDebug(e.body);
        _errorMessage =
            'Unable to submit driver decision (${e.code}). Backend endpoint may be missing.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to submit driver decision right now.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _submittingDriverDecision = false;
      });
    }
  }

  bool _isTerminalBookingStatus(String status) {
    const terminal = <String>{
      'CONFIRMED',
      'ACCEPTED',
      'COMPLETED',
      'FAILED',
      'REJECTED',
      'CANCELED',
      'CANCELLED',
      'EXPIRED',
    };
    return terminal.contains(_normalizeStatus(status));
  }

  String _statusToUserText(String status) {
    final s = _normalizeStatus(status);
    switch (s) {
      case 'CONFIRMED':
      case 'ACCEPTED':
        if (_requiresUserDriverDecision()) {
          return 'Driver found. Please choose Accept or Reject.';
        }
        return 'Taxi accepted. Driver confirmed in backend.';
      case 'REJECTED':
      case 'FAILED':
      case 'CANCELED':
      case 'CANCELLED':
      case 'EXPIRED':
        return 'Taxi request was not accepted ($s).';
      default:
        final pendingSince = _proposalPendingSince;
        if (s == 'PENDING_PROVIDER' && pendingSince != null) {
          final wait = DateTime.now().difference(pendingSince);
          if (wait >= _providerPendingTimeout) {
            return 'No taxi available for now. You can refresh, change destination, or retry request.';
          }
        }
        return 'Taxi request pending. Waiting for provider response...';
    }
  }

  bool _requiresUserDriverDecision() {
    final booking = _latestBooking;
    if (booking == null) return false;

    if (_locallyDecidedBookingIds.contains(booking.id)) {
      return false;
    }

    final decision = _normalizeStatus(booking.userDriverDecision);
    if (decision == 'ACCEPTED' || decision == 'REJECTED') {
      return false;
    }

    if (booking.userDecisionRequired == true) {
      return true;
    }

    final tripStatus = _normalizeStatus(booking.tripStatus);
    if (tripStatus == 'DRIVER_PROPOSED' ||
        tripStatus == 'AWAITING_USER_CONFIRMATION') {
      return true;
    }

    // Backward-compatible fallback: accepted booking without explicit decision
    // metadata should still allow user choice.
    final bookingStatus = _normalizeStatus(booking.status);
    return bookingStatus == 'ACCEPTED';
  }

  String _displayProposalStatus(String status) {
    if (_requiresUserDriverDecision()) return 'AWAITING_USER_DECISION';
    return _normalizeStatus(status);
  }

  Future<bool> _recoverLatestProposalFromBackend({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _refreshingProposalStatus = true;
      });
    }

    try {
      final pending = await _mobilityApiService.fetchPendingProposals();
      final bookings = await _mobilityApiService.fetchBookings();

      final destination = _destinationController.text.trim().toLowerCase();
      MobilityProposal? selectedProposal;

      if (destination.isNotEmpty) {
        for (final p in pending) {
          final to = p.to.toLowerCase();
          if (to == destination || to.contains(destination)) {
            selectedProposal = p;
            break;
          }
        }
      }
      selectedProposal ??= pending.isNotEmpty ? pending.first : null;

      if (selectedProposal != null && mounted) {
        final proposalData = selectedProposal;
        final status = _normalizeStatus(proposalData.status);
        setState(() {
          _latestBooking = null;
          _latestProposal = MobilityProposal(
            id: proposalData.id,
            from: proposalData.from,
            to: proposalData.to,
            status: status,
            provider: proposalData.provider,
          );
          _lastBookingBackendStatus = status;
          _proposalPendingSince = status == 'PENDING_PROVIDER'
              ? DateTime.now()
              : null;
          _bookingStatusMessage = _statusToUserText(status);
          _appendStatusHistory(status);
        });
        if (!_isTerminalBookingStatus(status)) {
          _startProposalStatusPolling();
        }
        return true;
      }

      MobilityBooking? selectedBooking;
      final latestId = _latestProposal?.id;
      if (latestId != null && latestId.isNotEmpty) {
        for (final b in bookings) {
          if (b.proposalId == latestId || b.id == latestId) {
            selectedBooking = b;
            break;
          }
        }
      }

      if (selectedBooking == null && bookings.isNotEmpty) {
        for (final b in bookings) {
          if (!_isTerminalBookingStatus(b.status)) {
            selectedBooking = b;
            break;
          }
        }
      }
      selectedBooking ??= bookings.isNotEmpty ? bookings.first : null;

      if (selectedBooking != null && mounted) {
        final bookingData = selectedBooking;
        final status = _normalizeStatus(bookingData.status);
        final fallbackFrom = _pickupLatLng == null
            ? 'Current location'
            : 'Map selected pickup';
        final fallbackTo = _destinationController.text.trim().isEmpty
            ? 'Backend destination'
            : _destinationController.text.trim();
        setState(() {
          _latestBooking = bookingData;
          _latestProposal = MobilityProposal(
            id: bookingData.proposalId.isEmpty
                ? bookingData.id
                : bookingData.proposalId,
            from: fallbackFrom,
            to: fallbackTo,
            status: status,
            provider: bookingData.provider,
          );
          _lastBookingBackendStatus = status;
          _proposalPendingSince = status == 'PENDING_PROVIDER'
              ? DateTime.now()
              : null;
          _bookingStatusMessage = _statusToUserText(status);
          _appendStatusHistory(status);
        });
        if (!_isTerminalBookingStatus(status)) {
          _startProposalStatusPolling();
        }
        return true;
      }

      return false;
    } on MobilityApiException catch (e) {
      if (!mounted || silent) return false;
      setState(() {
        _lastMobilityErrorCode = e.code;
        _lastMobilityErrorBody = _truncateForDebug(e.body);
      });
      return false;
    } catch (_) {
      if (!mounted || silent) return false;
      setState(() {
        _lastMobilityErrorCode = 'unknown_exception';
        _lastMobilityErrorBody = null;
      });
      return false;
    } finally {
      if (!silent && mounted) {
        setState(() {
          _refreshingProposalStatus = false;
        });
      }
    }
  }

  Future<void> _refreshLatestProposalStatus({bool silent = false}) async {
    final proposal = _latestProposal;
    if (proposal == null || proposal.id.isEmpty) {
      await _recoverLatestProposalFromBackend(silent: silent);
      return;
    }

    if (!silent && mounted) {
      setState(() {
        _refreshingProposalStatus = true;
      });
    }

    try {
      final pending = await _mobilityApiService.fetchPendingProposals();
      final matchPending = pending.where((p) => p.id == proposal.id).toList();
      if (matchPending.isNotEmpty && mounted) {
        final p = matchPending.first;
        final pendingStatus = _normalizeStatus(p.status);
        setState(() {
          _latestBooking = null;
          _latestProposal = MobilityProposal(
            id: p.id,
            from: p.from,
            to: p.to,
            status: pendingStatus,
            provider: p.provider ?? _latestProposal?.provider,
          );
          if (pendingStatus == 'PENDING_PROVIDER') {
            _proposalPendingSince ??= DateTime.now();
          } else {
            _proposalPendingSince = null;
          }
          _lastBookingBackendStatus = pendingStatus;
          _appendStatusHistory(pendingStatus);
        });
      }

      final bookings = await _mobilityApiService.fetchBookings();
      final bookingMatch = bookings
          .where((b) => b.proposalId == proposal.id)
          .toList();

      if (bookingMatch.isNotEmpty && mounted) {
        final booking = bookingMatch.first;
        final bookingStatus = _normalizeStatus(booking.status);
        setState(() {
          _latestBooking = booking;
          _lastBookingBackendStatus = bookingStatus;
          _latestProposal = MobilityProposal(
            id: proposal.id,
            from: proposal.from,
            to: proposal.to,
            status: bookingStatus,
            provider: booking.provider ?? _latestProposal?.provider,
          );
          if (bookingStatus == 'PENDING_PROVIDER') {
            _proposalPendingSince ??= DateTime.now();
          } else {
            _proposalPendingSince = null;
          }
          _bookingStatusMessage = _statusToUserText(bookingStatus);
          _appendStatusHistory(bookingStatus);
        });

        if (_isTerminalBookingStatus(bookingStatus)) {
          _proposalStatusTimer?.cancel();
          if (mounted) {
            setState(() {
              _pollingProposalStatus = false;
            });
          }
        }
      } else if (mounted) {
        final current = _latestProposal?.status ?? proposal.status;
        if (_normalizeStatus(current) == 'PENDING_PROVIDER') {
          _proposalPendingSince ??= DateTime.now();
        }
        final nextMessage = _statusToUserText(current);
        if (_bookingStatusMessage != nextMessage) {
          setState(() {
            _bookingStatusMessage = nextMessage;
          });
        }
      }
    } on MobilityApiException catch (e) {
      if (!mounted || silent) return;
      setState(() {
        _lastMobilityErrorCode = e.code;
        _lastMobilityErrorBody = _truncateForDebug(e.body);
      });
    } catch (_) {
      if (!mounted || silent) return;
      setState(() {
        _lastMobilityErrorCode = 'unknown_exception';
        _lastMobilityErrorBody = null;
      });
    } finally {
      if (!silent && mounted) {
        setState(() {
          _refreshingProposalStatus = false;
        });
      }
    }
  }

  Future<void> _fetchNearbyTaxiStations() async {
    LatLng? center;
    try {
      final mapCenter = _mapController.camera.center;
      if (mapCenter.latitude.isFinite && mapCenter.longitude.isFinite) {
        center = mapCenter;
      }
    } catch (_) {
      // Map camera may not be ready yet on first frames.
    }

    center ??=
        _pickupLatLng ??
        (_currentPosition == null
            ? null
            : LatLng(_currentPosition!.latitude, _currentPosition!.longitude));
    if (center == null) return;

    setState(() {
      _loadingNearbyTaxis = true;
    });

    try {
      final query =
          '''
[out:json][timeout:15];
(
  node["amenity"="taxi"](around:12000,${center.latitude},${center.longitude});
  way["amenity"="taxi"](around:12000,${center.latitude},${center.longitude});
  relation["amenity"="taxi"](around:12000,${center.latitude},${center.longitude});
  node["taxi"="yes"](around:12000,${center.latitude},${center.longitude});
  way["taxi"="yes"](around:12000,${center.latitude},${center.longitude});
  relation["taxi"="yes"](around:12000,${center.latitude},${center.longitude});
  node["station"="taxi"](around:12000,${center.latitude},${center.longitude});
  way["station"="taxi"](around:12000,${center.latitude},${center.longitude});
  relation["station"="taxi"](around:12000,${center.latitude},${center.longitude});
);
out center 30;
''';

      final endpoints = <String>[
        'https://overpass-api.de/api/interpreter',
        'https://overpass.kumi.systems/api/interpreter',
        'https://overpass.openstreetmap.fr/api/interpreter',
      ];

      http.Response? response;
      Object? lastError;
      for (final endpoint in endpoints) {
        try {
          var candidate = await http
              .post(
                Uri.parse(endpoint),
                headers: buildJsonHeaders(
                  extra: const {'Content-Type': 'text/plain; charset=utf-8'},
                ),
                body: query,
              )
              .timeout(const Duration(seconds: 18));
          if (candidate.statusCode != 200) {
            reportHttpResponseError(
              feature: 'travel.nearby_taxis.overpass',
              response: candidate,
            );
            candidate = await http
                .post(
                  Uri.parse(endpoint),
                  headers: buildJsonHeaders(
                    extra: const {
                      'Content-Type':
                          'application/x-www-form-urlencoded; charset=utf-8',
                    },
                  ),
                  body: 'data=${Uri.encodeQueryComponent(query)}',
                )
                .timeout(const Duration(seconds: 18));
          }
          if (candidate.statusCode == 200) {
            response = candidate;
            break;
          }
          reportHttpResponseError(
            feature: 'travel.nearby_taxis.overpass',
            response: candidate,
          );
          lastError = 'OSM query failed: ${candidate.statusCode}';
        } catch (e) {
          reportApiException(feature: 'travel.nearby_taxis.overpass', error: e);
          lastError = e;
        }
      }

      if (response == null) {
        throw Exception(lastError ?? 'OSM request failed');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final elements =
          decoded['elements'] as List<dynamic>? ?? const <dynamic>[];

      final points = <LatLng>[];
      final seen = <String>{};
      for (final e in elements) {
        if (e is! Map<String, dynamic>) continue;
        final latNum = e['lat'] as num?;
        final lonNum = e['lon'] as num?;
        if (latNum != null && lonNum != null) {
          final lat = latNum.toDouble();
          final lon = lonNum.toDouble();
          final key = '${lat.toStringAsFixed(5)},${lon.toStringAsFixed(5)}';
          if (seen.add(key)) {
            points.add(LatLng(lat, lon));
          }
          continue;
        }

        final centerMap = e['center'];
        if (centerMap is Map<String, dynamic>) {
          final cLat = centerMap['lat'] as num?;
          final cLon = centerMap['lon'] as num?;
          if (cLat != null && cLon != null) {
            final lat = cLat.toDouble();
            final lon = cLon.toDouble();
            final key = '${lat.toStringAsFixed(5)},${lon.toStringAsFixed(5)}';
            if (seen.add(key)) {
              points.add(LatLng(lat, lon));
            }
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _nearbyTaxiPoints = points;
        _loadingNearbyTaxis = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingNearbyTaxis = false;
        _nearbyTaxiPoints = const <LatLng>[];
      });
    }
  }

  double? _nearestTaxiDistanceMeters() {
    if (_nearbyTaxiPoints.isEmpty) return null;

    final origin =
        _pickupLatLng ??
        (_currentPosition == null
            ? null
            : LatLng(_currentPosition!.latitude, _currentPosition!.longitude));
    if (origin == null) return null;

    double? best;
    for (final p in _nearbyTaxiPoints) {
      final d = _distanceCalc(origin, p);
      if (best == null || d < best) {
        best = d;
      }
    }
    return best;
  }

  LatLng? _driverLatLng() {
    final booking = _latestBooking;
    if (booking == null) return null;
    final lat = booking.driverLatitude;
    final lng = booking.driverLongitude;
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  bool _canUserDecideDriver() {
    if (_latestBooking == null) return false;
    if (_submittingDriverDecision) return false;
    return _requiresUserDriverDecision();
  }

  void _startProposalStatusPolling() {
    _proposalStatusTimer?.cancel();
    if (mounted) {
      setState(() {
        _pollingProposalStatus = true;
      });
    } else {
      _pollingProposalStatus = true;
    }
    _proposalStatusTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      unawaited(_refreshLatestProposalStatus(silent: true));
    });
  }

  Future<void> _confirmInAppTaxiRequest() async {
    final selectedOption = _estimate?.best;
    if (_destinationLatLng == null ||
        _distanceKm == null ||
        _durationMin == null) {
      setState(
        () => _errorMessage = 'Search destination and build route first.',
      );
      return;
    }

    // Fallback mode: allow in-app request even if live quote is unavailable.
    final effectiveOption =
        selectedOption ??
        MobilityQuoteOption(
          provider: 'uberx',
          minPrice: 0,
          maxPrice: 0,
          etaMinutes: _durationMin!.round(),
          confidence: 0,
          reasons: const <String>['live estimate unavailable'],
        );

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.cardGradient,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderCyanFocus),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppColors.buttonGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_taxi_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Confirm Taxi Request',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryMedium.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderCyan),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Destination: ${_destinationController.text.trim()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pickup time: ${_plannedTime.format(context)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Provider: ${effectiveOption.provider}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryMedium.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderCyan),
                        ),
                        child: Text(
                          '${effectiveOption.minPrice.toStringAsFixed(1)}-${effectiveOption.maxPrice.toStringAsFixed(1)} AED',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.cyan200,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryMedium.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderCyan),
                        ),
                        child: Text(
                          '${_distanceKm!.toStringAsFixed(1)} km • ${_durationMin!.round()} min',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.cyan200,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (selectedOption == null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withOpacity(0.45)),
                    ),
                    child: Text(
                      'Live estimate is unavailable now. Request will still be sent to backend.',
                      style: TextStyle(
                        color: Colors.amberAccent.withOpacity(0.95),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'We will send the request and track acceptance/refusal in this app.',
                  style: TextStyle(
                    color: AppColors.textCyan200.withOpacity(0.88),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.borderCyanFocus),
                          foregroundColor: AppColors.cyan200,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: AppColors.buttonGradient,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        child: FilledButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Request Taxi'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _confirmingBooking = true;
      _errorMessage = null;
      _bookingStatusMessage = null;
      _proposalPendingSince = null;
      _locallyDecidedBookingIds.clear();
      _latestBooking = null;
      _latestProposal = null;
      _latestProposalOfferLabel = null;
      _lastBookingBackendStatus = null;
      _proposalStatusHistory.clear();
      _proposalStatusTimer?.cancel();
      _pollingProposalStatus = false;
    });

    try {
      final destination = _destinationController.text.trim();
      MobilityProposal? proposal = await _mobilityApiService.createProposal(
        from: _pickupLatLng == null
            ? 'Current location'
            : 'Map selected pickup',
        to: destination,
        pickupAt: _effectivePickupDateTime(),
        selectedOption: effectiveOption,
        fromLatitude: _pickupLatLng?.latitude ?? _currentPosition?.latitude,
        fromLongitude: _pickupLatLng?.longitude ?? _currentPosition?.longitude,
        toLatitude: _destinationLatLng?.latitude,
        toLongitude: _destinationLatLng?.longitude,
        distanceKm: _distanceKm,
        durationMin: _durationMin,
      );

      if (proposal == null) {
        final pending = await _mobilityApiService.fetchPendingProposals();
        final lowerDestination = destination.toLowerCase();
        final matches = pending.where((p) {
          return p.to.toLowerCase() == lowerDestination ||
              p.to.toLowerCase().contains(lowerDestination);
        }).toList();
        if (matches.isNotEmpty) {
          proposal = matches.first;
        }
      }

      if (proposal != null && proposal.id.isNotEmpty) {
        final confirmResult = await _mobilityApiService.confirmProposal(
          proposal.id,
        );
        final confirmedStatus = _normalizeStatus(confirmResult['status']);
        proposal = MobilityProposal(
          id: proposal.id,
          from: proposal.from,
          to: proposal.to,
          status: confirmedStatus,
          provider: proposal.provider ?? effectiveOption.provider,
        );
      }

      if (!mounted) return;
      setState(() {
        _latestProposal = proposal;
        _latestProposalOfferLabel =
            selectedOption?.label ?? 'fallback in-app request';
        _lastBookingBackendStatus = proposal == null
            ? null
            : _normalizeStatus(proposal.status);
        _proposalPendingSince =
            proposal != null &&
                _normalizeStatus(proposal.status) == 'PENDING_PROVIDER'
            ? DateTime.now()
            : null;
        _bookingStatusMessage = proposal == null
            ? 'Taxi request submitted, waiting for backend proposal...'
            : _statusToUserText(proposal.status);
        if (proposal != null) {
          _appendStatusHistory(proposal.status);
        }
      });

      if (proposal != null && proposal.id.isNotEmpty) {
        _startProposalStatusPolling();
      }
    } on MobilityApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _latestProposalOfferLabel =
            selectedOption?.label ?? 'fallback in-app request';
        _estimateInfoMessage = 'Backend request failed (${e.code}).';
        _bookingStatusMessage = 'Taxi request failed in backend. Please retry.';
        _lastMobilityErrorCode = e.code;
        _lastMobilityErrorBody = _truncateForDebug(e.body);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _estimateInfoMessage = 'Backend request failed.';
        _bookingStatusMessage = 'Taxi request failed in backend. Please retry.';
        _lastMobilityErrorCode = 'unknown_exception';
        _lastMobilityErrorBody = null;
      });
    }

    if (!mounted) return;
    setState(() {
      _confirmingBooking = false;
    });
  }

  Widget _buildStatusCard(
    BuildContext context, {
    required String title,
    required String message,
    bool loading = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          if (loading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(Icons.info_outline, size: 16, color: AppColors.cyan400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$title: $message',
              style: TextStyle(
                color: AppColors.textCyan200.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  LatLng get _initialCenter => _defaultTestHub;

  Widget _buildProposalCard(BuildContext context) {
    final proposal = _latestProposal;
    if (proposal == null) return const SizedBox.shrink();

    final rawStatus = proposal.status.isEmpty ? 'PENDING' : proposal.status;
    final status = _displayProposalStatus(rawStatus);
    final statusColor = _statusAccentColor(status);
    final isTerminal = _isTerminalBookingStatus(rawStatus);
    final awaitingDecision = _canUserDecideDriver();
    final estimate = _estimate;

    return Container(
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.28)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                proposal.provider ?? 'uberx',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              // Refresh (icon only)
              GestureDetector(
                onTap: _refreshingProposalStatus
                    ? null
                    : () => unawaited(_refreshLatestProposalStatus()),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    shape: BoxShape.circle,
                  ),
                  child: _refreshingProposalStatus
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.refresh,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                ),
              ),
            ],
          ),

          // Estimate summary (price + ETA)
          if (estimate?.best != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.payments_outlined,
                  size: 14,
                  color: Colors.greenAccent.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 5),
                Text(
                  '${estimate!.best!.minPrice.toStringAsFixed(0)}–${estimate.best!.maxPrice.toStringAsFixed(0)} AED',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  '${estimate.best!.etaMinutes} min',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],

          // AWAITING_USER_DECISION — prominent accept/reject
          if (awaitingDecision) ...[
            const SizedBox(height: 12),
            Text(
              'Driver found — confirm to proceed:',
              style: TextStyle(
                color: Colors.amberAccent.withValues(alpha: 0.95),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _submittingDriverDecision
                        ? null
                        : () => unawaited(_submitDriverDecision(accept: true)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.check,
                            color: Colors.greenAccent,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Accept',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: _submittingDriverDecision
                        ? null
                        : () => unawaited(_submitDriverDecision(accept: false)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.close, color: Colors.redAccent, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Reject',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Polling indicator
          if (!isTerminal && !awaitingDecision && _pollingProposalStatus) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Waiting for driver...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],

          // Cancel (not terminal)
          if (!isTerminal && !awaitingDecision) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _cancelCurrentProposal,
              child: Text(
                'Cancel request',
                style: TextStyle(
                  color: Colors.redAccent.withValues(alpha: 0.75),
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.redAccent.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],

          // Last status entry only
          if (_proposalStatusHistory.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _proposalStatusHistory.last,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Stack(
        children: [
          // Full-screen map — fills everything, sheet overlaps it
          Positioned.fill(child: _buildFullScreenMap(context)),

          // Top fade gradient for readability under the top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 140,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF0A1628).withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Draggable booking sheet — drag up for full form, down to minimise
          DraggableScrollableSheet(
            initialChildSize: 0.40,
            minChildSize: 0.10,
            maxChildSize: 0.88,
            snap: true,
            snapSizes: const [0.10, 0.40, 0.88],
            builder: (ctx, scrollController) =>
                _buildBookingSheet(ctx, scrollController),
          ),

          // Top bar — always on top of sheet
          Positioned(top: 0, left: 0, right: 0, child: _buildTopBar(context)),

          // Map FABs — right side, above minimum sheet position
          // Material wrapper ensures hit-testing wins over DraggableScrollableSheet
          Positioned(
            right: 16,
            bottom: MediaQuery.sizeOf(context).height * 0.12 + 16,
            child: Material(
              color: Colors.transparent,
              child: _buildMapFabs(context),
            ),
          ),

          // Navigation bar — always on top
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: NavigationBarWidget(currentPath: '/travel'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingSheet(
    BuildContext context,
    ScrollController scrollController,
  ) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const navBarHeight = 72.0;
    final hasRoute = _distanceKm != null && _durationMin != null;
    final estimate = _estimate;
    final hasProposal = _latestProposal != null;

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0A1628).withValues(alpha: 0.97),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(26),
              ),
              border: Border(
                top: BorderSide(
                  color: AppColors.cyan500.withValues(alpha: 0.22),
                ),
              ),
            ),
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                bottomInset + navBarHeight + 8,
              ),
              children: [
                // ── Drag handle ──
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── A → B location rows ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        const SizedBox(height: 11),
                        Container(
                          width: 11,
                          height: 11,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 26,
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                        Container(
                          width: 11,
                          height: 11,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        children: [
                          // Pickup
                          GestureDetector(
                            onTap: () => setState(
                              () => _selectingFromOnMap = !_selectingFromOnMap,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: _selectingFromOnMap
                                    ? AppColors.cyan400.withValues(alpha: 0.12)
                                    : Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(10),
                                border: _selectingFromOnMap
                                    ? Border.all(
                                        color: AppColors.cyan400.withValues(
                                          alpha: 0.45,
                                        ),
                                      )
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _pickupLatLng != null
                                          ? 'Custom pickup · ${_pickupLatLng!.latitude.toStringAsFixed(4)}, ${_pickupLatLng!.longitude.toStringAsFixed(4)}'
                                          : _loadingLocation
                                          ? 'Getting your location...'
                                          : _currentPosition == null
                                          ? 'Tap to set pickup on map'
                                          : 'Your current location',
                                      style: TextStyle(
                                        color: _selectingFromOnMap
                                            ? AppColors.cyan400
                                            : Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  TextButton.icon(
                                    onPressed: _useCurrentLocationAsPickup,
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.cyan400,
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.my_location,
                                      size: 15,
                                    ),
                                    label: const Text(
                                      'My location',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  if (_selectingFromOnMap)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.cyan400.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Tap map',
                                        style: TextStyle(
                                          color: AppColors.cyan400,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                  else if (_pickupLatLng != null)
                                    GestureDetector(
                                      onTap: () =>
                                          setState(() => _pickupLatLng = null),
                                      child: Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Destination + suggestions
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _destinationController,
                                onChanged: (v) {
                                  _suggestionDebounce?.cancel();
                                  _suggestionDebounce = Timer(
                                    const Duration(milliseconds: 400),
                                    () => _fetchPlaceSuggestions(v),
                                  );
                                },
                                onSubmitted: (_) =>
                                    unawaited(_applyManualDestination()),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Where to?',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 14,
                                  ),
                                  prefixIcon: _loadingSuggestions
                                      ? Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white.withValues(
                                                alpha: 0.5,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          Icons.search,
                                          color: Colors.white.withValues(
                                            alpha: 0.45,
                                          ),
                                          size: 20,
                                        ),
                                  suffixIcon: _destinationLatLng != null
                                      ? IconButton(
                                          icon: Icon(
                                            Icons.clear,
                                            size: 16,
                                            color: Colors.white.withValues(
                                              alpha: 0.5,
                                            ),
                                          ),
                                          onPressed: () => setState(() {
                                            _destinationController.clear();
                                            _destinationLatLng = null;
                                            _routePoints = const <LatLng>[];
                                            _distanceKm = null;
                                            _durationMin = null;
                                            _estimate = null;
                                            _estimateInfoMessage = null;
                                            _errorMessage = null;
                                            _placeSuggestions = const [];
                                          }),
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: Colors.white.withValues(
                                    alpha: 0.06,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: AppColors.cyan400.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (_placeSuggestions.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0d1f35),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.cyan500.withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    children: _placeSuggestions
                                        .map((place) {
                                          final raw =
                                              place['display_name']
                                                  as String? ??
                                              '';
                                          final parts = raw.split(',');
                                          final short = parts.first.trim();
                                          final sub = parts.length > 1
                                              ? parts
                                                    .skip(1)
                                                    .take(2)
                                                    .join(',')
                                                    .trim()
                                              : '';
                                          return InkWell(
                                            onTap: () =>
                                                _selectSuggestion(place),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 10,
                                                  ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.place_outlined,
                                                    size: 16,
                                                    color: AppColors.cyan400,
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          short,
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                        if (sub.isNotEmpty)
                                                          Text(
                                                            sub,
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .white
                                                                  .withValues(
                                                                    alpha: 0.4,
                                                                  ),
                                                              fontSize: 11,
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        })
                                        .toList(growable: false),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Now / Schedule toggle + Find Ride ──
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _rideNow = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _rideNow
                              ? AppColors.cyan400
                              : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _rideNow
                                ? AppColors.cyan400
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bolt,
                              size: 15,
                              color: _rideNow
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.55),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Now',
                              style: TextStyle(
                                color: _rideNow
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.55),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        setState(() => _rideNow = false);
                        await _pickTime();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: !_rideNow
                              ? AppColors.cyan400.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: !_rideNow
                                ? AppColors.cyan400.withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 15,
                              color: !_rideNow
                                  ? AppColors.cyan400
                                  : Colors.white.withValues(alpha: 0.55),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              !_rideNow
                                  ? _plannedTime.format(context)
                                  : 'Schedule',
                              style: TextStyle(
                                color: !_rideNow
                                    ? AppColors.cyan400
                                    : Colors.white.withValues(alpha: 0.55),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        if (_destinationLatLng == null) {
                          final manual = _parseLatLngInput(
                            _destinationController.text.trim(),
                          );
                          if (manual != null) {
                            setState(() {
                              _destinationLatLng = manual;
                              _destinationController.text = _coordsLabel(
                                manual,
                              );
                            });
                          }
                        }
                        if (_destinationLatLng == null) {
                          setState(
                            () => _errorMessage =
                                'Type or tap the map to set your destination.',
                          );
                          return;
                        }
                        unawaited(_buildRoute());
                        unawaited(_fetchMobilityEstimate());
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.buttonGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _loadingRoute || _loadingEstimate
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Find Ride',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),

                // ── Route info chips ──
                if (hasRoute) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _infoChip(
                        icon: Icons.route,
                        label: '${_distanceKm!.toStringAsFixed(1)} km',
                        color: AppColors.cyan400,
                        bg: AppColors.cyan500.withValues(alpha: 0.15),
                        border: AppColors.cyan500.withValues(alpha: 0.3),
                      ),
                      _infoChip(
                        icon: Icons.access_time,
                        label: '${_durationMin!.round()} min',
                        color: Colors.white.withValues(alpha: 0.8),
                        bg: Colors.white.withValues(alpha: 0.06),
                        border: Colors.white.withValues(alpha: 0.12),
                      ),
                      if (estimate?.best != null)
                        _infoChip(
                          icon: Icons.payments_outlined,
                          label:
                              '${estimate!.best!.minPrice.toStringAsFixed(0)}–${estimate.best!.maxPrice.toStringAsFixed(0)} AED',
                          color: Colors.greenAccent,
                          bg: Colors.green.withValues(alpha: 0.12),
                          border: Colors.green.withValues(alpha: 0.3),
                        ),
                    ],
                  ),
                ],

                // ── Request Ride CTA ──
                if (hasRoute) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _confirmingBooking ? null : _confirmInAppTaxiRequest,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        gradient: AppColors.buttonGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cyan400.withValues(alpha: 0.22),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _confirmingBooking
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.local_taxi_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _rideNow
                                        ? 'Request Ride Now'
                                        : 'Schedule · ${_plannedTime.format(context)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (estimate?.best != null) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '· ${estimate!.best!.minPrice.toStringAsFixed(0)} AED',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.6,
                                        ),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                      ),
                    ),
                  ),
                ],

                // ── Proposal status ──
                if (hasProposal) ...[
                  const SizedBox(height: 10),
                  _buildProposalCard(context),
                ],

                // ── Driver info ──
                if (_latestBooking != null) ...[
                  const SizedBox(height: 8),
                  _buildDriverInfoCard(context),
                ],

                // ── Error banner ──
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  _buildErrorBanner(context),
                ],

                // ── Success banner ──
                if (_bookingStatusMessage != null && !hasProposal) ...[
                  const SizedBox(height: 8),
                  _buildSuccessBanner(context),
                ],

                // ── Schedule planner link ──
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: _openSchedulePlanner,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 13,
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Schedule & Pricing Planner',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.28),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenMap(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _initialCenter,
        initialZoom: 14.0,
        minZoom: 4,
        maxZoom: 18,
        onTap: (_, point) => unawaited(_onMapTapped(point)),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'pi_dev_agentia',
        ),
        if (_routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routePoints,
                strokeWidth: 5,
                color: AppColors.cyan400,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            ..._nearbyTaxiPoints.map(
              (p) => Marker(
                point: p,
                width: 28,
                height: 28,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.92),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.local_taxi,
                    color: Colors.black,
                    size: 14,
                  ),
                ),
              ),
            ),
            if (_driverLatLng() != null)
              Marker(
                point: _driverLatLng()!,
                width: 44,
                height: 44,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.lightGreenAccent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.local_taxi,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ),
            if (_currentPosition != null)
              Marker(
                point: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                width: 48,
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                    ),
                  ],
                ),
              ),
            if (_pickupLatLng != null)
              Marker(
                point: _pickupLatLng!,
                width: 44,
                height: 44,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.cyan400,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.circle,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            if (_destinationLatLng != null)
              Marker(
                point: _destinationLatLng!,
                width: 40,
                height: 48,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.location_on, color: Colors.redAccent, size: 38),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Book a Ride',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const Spacer(),
            if (_loadingLocation)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapFabs(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Center on my location
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => unawaited(_loadLocation()),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _loadingLocation
                  ? Colors.white.withValues(alpha: 0.85)
                  : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _loadingLocation
                ? const Padding(
                    padding: EdgeInsets.all(13),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF0A1628),
                    ),
                  )
                : Icon(
                    _currentPosition != null
                        ? Icons.my_location
                        : Icons.location_searching,
                    color: _currentPosition != null
                        ? const Color(0xFF0A66C2)
                        : const Color(0xFF0A1628),
                    size: 22,
                  ),
          ),
        ),
        const SizedBox(height: 10),
        // Toggle pickup-on-map mode
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () =>
              setState(() => _selectingFromOnMap = !_selectingFromOnMap),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _selectingFromOnMap ? AppColors.cyan400 : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.pin_drop,
              color: _selectingFromOnMap
                  ? Colors.white
                  : const Color(0xFF0A1628),
              size: 22,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Open full-screen destination picker
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openFullMapSelection,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _loadingNearbyTaxis
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF0A1628),
                    ),
                  )
                : const Icon(
                    Icons.open_in_full,
                    color: Color(0xFF0A1628),
                    size: 20,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildDriverInfoCard(BuildContext context) {
    final booking = _latestBooking;
    if (booking == null ||
        (_normalizeStatus(booking.status) != 'ACCEPTED' &&
            !_canUserDecideDriver())) {
      return const SizedBox.shrink();
    }

    final driverName = booking.driverName?.isNotEmpty == true
        ? booking.driverName!
        : 'Driver Information Pending';
    final rawDriverPhone = booking.driverPhone?.isNotEmpty == true
        ? booking.driverPhone!
        : 'N/A';
    final driverPhone = rawDriverPhone.startsWith('+216')
        ? rawDriverPhone.replaceFirst('+216', '+971')
        : rawDriverPhone;
    final rawVehiclePlate = booking.vehiclePlate?.isNotEmpty == true
        ? booking.vehiclePlate!
        : 'N/A';
    final vehiclePlate = rawVehiclePlate == 'N/A'
        ? rawVehiclePlate
        : rawVehiclePlate.replaceAll(
            RegExp(r'\bTUN\b', caseSensitive: false),
            'DXB',
          );
    final hasLocation =
        booking.driverLatitude != null && booking.driverLongitude != null;
    final etaMinutes = booking.etaMinutes ?? 0;

    return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderCyan),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Driver Details',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.cyan400,
                ),
              ),
              const SizedBox(height: 12),
              // Driver Header with Icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppColors.buttonGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.directions_car_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driverName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Plate: $vehiclePlate',
                          style: TextStyle(
                            color: AppColors.cyan400,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (etaMinutes > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        'ETA $etaMinutes min',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Contact & Details
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryMedium.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderCyan),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.phone_rounded,
                          color: AppColors.cyan400,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            driverPhone,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (hasLocation)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: AppColors.cyan400,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${booking.driverLatitude?.toStringAsFixed(4)}, ${booking.driverLongitude?.toStringAsFixed(4)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (_canUserDecideDriver()) ...[
                const SizedBox(height: 12),
                Text(
                  'Please confirm this driver:',
                  style: TextStyle(
                    color: Colors.amberAccent.withOpacity(0.95),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _submittingDriverDecision
                          ? null
                          : () =>
                                unawaited(_submitDriverDecision(accept: true)),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Accept driver'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _submittingDriverDecision
                          ? null
                          : () =>
                                unawaited(_submitDriverDecision(accept: false)),
                      icon: const Icon(Icons.person_off, size: 16),
                      label: const Text('Reject driver'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 400))
        .slideY(
          begin: 0.2,
          end: 0,
          duration: const Duration(milliseconds: 400),
        );
  }

  Widget _buildErrorBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.redAccent.withOpacity(0.35)),
      ),
      child: Text(_errorMessage!, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _buildSuccessBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.withOpacity(0.35)),
      ),
      child: Text(
        _bookingStatusMessage!,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
