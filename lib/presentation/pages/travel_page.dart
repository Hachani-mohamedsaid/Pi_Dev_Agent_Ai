import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../injection_container.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../data/services/mobility_api_service.dart';
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
  static const String _defaultTestHubLabel =
      'Downtown Dubai (Uber + high taxi density)';

  final TextEditingController _destinationController = TextEditingController();
  final MapController _mapController = MapController();
  final MobilityApiService _mobilityApiService = InjectionContainer.instance
      .buildMobilityApiService();

  Position? _currentPosition;
  LatLng? _pickupLatLng;
  LatLng? _destinationLatLng;

  bool _loadingLocation = true;
  bool _loadingRoute = false;
  bool _loadingEstimate = false;
  bool _confirmingBooking = false;
  bool _syncingDailyRule = false;
  bool _dailyRuleEnabled = false;
  bool _selectingFromOnMap = false;
  bool _showDebugPanel = false;
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
  String? _nearbyTaxiError;
  LatLng? _nearbyTaxiSearchCenter;
  final Distance _distanceCalc = const Distance();

  List<LatLng> _routePoints = const <LatLng>[];
  double? _distanceKm;
  double? _durationMin;
  MobilityEstimateResponse? _estimate;
  MobilityProposal? _latestProposal;
  MobilityBooking? _latestBooking;
  String? _latestProposalOfferLabel;
  String? _dailyRuleId;
  TimeOfDay _plannedTime = const TimeOfDay(hour: 8, minute: 0);
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
    _destinationController.dispose();
    super.dispose();
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
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _loadingLocation = false;
          _errorMessage = 'Location services are disabled.';
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
          _errorMessage = 'Location permission is required.';
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
      });

      _startLiveLocationStream();
      _mapController.move(_defaultTestHub, 13.5);
      unawaited(_fetchNearbyTaxiStations());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingLocation = false;
        _errorMessage = 'Unable to fetch your current location.';
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
      setState(() => _plannedTime = picked);
      if (_dailyRuleEnabled && _dailyRuleId != null) {
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
      final response = await http.get(uri);

      if (response.statusCode != 200) {
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
    } catch (_) {
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
        pickupAt: _nextPickupDateTime(),
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
    if (normalized == 'login_required') return false;

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
      default:
        return 'Mobility backend error (${e.code}).';
    }
  }

  String _toCron(TimeOfDay t) => '${t.minute} ${t.hour} * * *';

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
          .where((r) => r.name == 'Daily commute template')
          .toList();
      if (existing.isEmpty) return;
      setState(() {
        _dailyRuleId = existing.first.id;
        _dailyRuleEnabled = existing.first.enabled;
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
      if (_dailyRuleId == null) {
        final created = await _mobilityApiService.createRule(
          name: 'Daily commute template',
          from: 'Current location',
          to: destination,
          timezone: _clientTimezone(),
          cron: _toCron(_plannedTime),
          enabled: enabled,
          requireUserApproval: true,
        );
        if (!mounted) return;
        setState(() {
          _dailyRuleId = created?.id;
          _dailyRuleEnabled = enabled;
          _syncingDailyRule = false;
        });
        return;
      }

      await _mobilityApiService.updateRule(
        ruleId: _dailyRuleId!,
        patch: {
          'enabled': enabled,
          'to': destination,
          'cron': _toCron(_plannedTime),
          'requireUserApproval': true,
        },
      );
      if (!mounted) return;
      setState(() {
        _dailyRuleEnabled = enabled;
        _syncingDailyRule = false;
      });
    } on MobilityApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _syncingDailyRule = false;
        _dailyRuleEnabled = !enabled;
        _errorMessage = _mobilityErrorMessage(e);
        _lastMobilityErrorCode = e.code;
        _lastMobilityErrorBody = _truncateForDebug(e.body);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _syncingDailyRule = false;
        _dailyRuleEnabled = !enabled;
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

  Future<void> _refreshInAppData() async {
    setState(() {
      _errorMessage = null;
      _bookingStatusMessage = null;
    });

    if (_destinationLatLng != null && !_loadingRoute) {
      await _buildRoute();
    }

    await _fetchMobilityEstimate();
    await _refreshLatestProposalStatus(silent: true);
    await _fetchNearbyTaxiStations();
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
      _nearbyTaxiError = null;
      _nearbyTaxiSearchCenter = center;
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
                headers: const {'Content-Type': 'text/plain; charset=utf-8'},
                body: query,
              )
              .timeout(const Duration(seconds: 18));
          if (candidate.statusCode != 200) {
            candidate = await http
                .post(
                  Uri.parse(endpoint),
                  headers: const {
                    'Content-Type':
                        'application/x-www-form-urlencoded; charset=utf-8',
                  },
                  body: 'data=${Uri.encodeQueryComponent(query)}',
                )
                .timeout(const Duration(seconds: 18));
          }
          if (candidate.statusCode == 200) {
            response = candidate;
            break;
          }
          lastError = 'OSM query failed: ${candidate.statusCode}';
        } catch (e) {
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
        _nearbyTaxiError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingNearbyTaxis = false;
        _nearbyTaxiPoints = const <LatLng>[];
        _nearbyTaxiError = e.toString();
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

  String _nearestTaxiDistanceLabel() {
    final meters = _nearestTaxiDistanceMeters();
    if (meters == null) return 'n/a';
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
    return '${meters.round()} m';
  }

  LatLng? _driverLatLng() {
    final booking = _latestBooking;
    if (booking == null) return null;
    final lat = booking.driverLatitude;
    final lng = booking.driverLongitude;
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  String _driverInfoLabel() {
    final booking = _latestBooking;
    if (booking == null) return 'Driver details unavailable.';
    final name = booking.driverName;
    final phone = booking.driverPhone;
    final plate = booking.vehiclePlate;
    final model = booking.vehicleModel;
    final eta = booking.etaMinutes;
    final hasLocation =
        booking.driverLatitude != null && booking.driverLongitude != null;

    final chunks = <String>[];
    if (name != null && name.isNotEmpty) chunks.add(name);
    if (phone != null && phone.isNotEmpty) chunks.add(phone);
    if (model != null && model.isNotEmpty) chunks.add(model);
    if (plate != null && plate.isNotEmpty) chunks.add('plate $plate');
    if (eta != null) chunks.add('ETA ${eta} min');
    if (hasLocation) chunks.add('live location available');
    return chunks.isEmpty
        ? 'Driver accepted, but backend did not provide driver data yet (name/phone/plate/location).'
        : chunks.join(' • ');
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
        return AlertDialog(
          title: const Text('Confirm taxi request in app'),
          content: Text(
            'Destination: ${_destinationController.text.trim()}\n'
            'Pickup time: ${_plannedTime.format(context)}\n'
            'Provider: ${effectiveOption.provider}\n'
            'Price: ${effectiveOption.minPrice.toStringAsFixed(1)} - ${effectiveOption.maxPrice.toStringAsFixed(1)} TND\n'
            'Distance: ${_distanceKm!.toStringAsFixed(1)} km\n'
            'ETA: ${_durationMin!.round()} min\n\n'
            '${selectedOption == null ? 'Live estimate is unavailable right now. Request will still be sent to backend.\n\n' : ''}We will send the request and track acceptance/refusal in this app.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Request Taxi'),
            ),
          ],
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
        pickupAt: _nextPickupDateTime(),
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

  Widget _buildEstimateCard(BuildContext context) {
    if (_loadingEstimate) {
      return _buildStatusCard(
        context,
        title: 'Live Backend Estimate',
        message: 'Fetching mobility quotes from Railway backend...',
        loading: true,
      );
    }

    final estimate = _estimate;
    if (estimate == null || estimate.options.isEmpty) {
      return _buildStatusCard(
        context,
        title: 'Live Backend Estimate',
        message: 'Trace a route to request cheapest provider options.',
      );
    }

    final best = estimate.best ?? estimate.options.first;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.sparkles, color: AppColors.cyan400, size: 18),
              const SizedBox(width: 8),
              Text(
                'Best live offer',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${(best.confidence * 100).round()}% confidence',
                style: TextStyle(
                  color: AppColors.textCyan200.withOpacity(0.86),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            best.label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (best.reasons.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              best.reasons.join(' • '),
              style: TextStyle(
                color: AppColors.textCyan200.withOpacity(0.84),
                fontSize: 12,
              ),
            ),
          ],
          if (estimate.options.length > 1) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: estimate.options
                  .skip(1)
                  .map(
                    (option) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Text(
                        option.label,
                        style: TextStyle(
                          color: AppColors.textCyan200.withOpacity(0.86),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          if (_estimateInfoMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _estimateInfoMessage!,
              style: TextStyle(
                color: AppColors.textCyan200.withOpacity(0.8),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
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

  Widget _buildProposalCard(BuildContext context) {
    final proposal = _latestProposal;
    if (proposal == null) {
      return const SizedBox.shrink();
    }

    final status = proposal.status.isEmpty ? 'PENDING' : proposal.status;
    final shownStatus = _displayProposalStatus(status);
    final provider = proposal.provider ?? 'uber';
    final statusColor = _statusAccentColor(shownStatus);
    final isTerminal = _isTerminalBookingStatus(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your proposal in app',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusColor.withOpacity(0.65)),
                ),
                child: Text(
                  shownStatus,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'Provider: $provider',
                style: TextStyle(
                  color: AppColors.textCyan200.withOpacity(0.92),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Status: $shownStatus',
            style: TextStyle(
              color: AppColors.textCyan200.withOpacity(0.92),
              fontSize: 12,
            ),
          ),
          Text(
            'Proposal ID: ${proposal.id}',
            style: TextStyle(
              color: AppColors.textCyan200.withOpacity(0.92),
              fontSize: 12,
            ),
          ),
          Text(
            'Trip: ${proposal.from} -> ${proposal.to}',
            style: TextStyle(
              color: AppColors.textCyan200.withOpacity(0.92),
              fontSize: 12,
            ),
          ),
          if (_latestProposalOfferLabel != null)
            Text(
              'Offer: $_latestProposalOfferLabel',
              style: TextStyle(
                color: AppColors.textCyan200.withOpacity(0.92),
                fontSize: 12,
              ),
            ),
          if (_latestBooking?.providerBookingRef != null &&
              _latestBooking!.providerBookingRef!.isNotEmpty)
            Text(
              'Provider booking ref: ${_latestBooking!.providerBookingRef}',
              style: TextStyle(
                color: AppColors.textCyan200.withOpacity(0.92),
                fontSize: 12,
              ),
            ),
          if (_normalizeStatus(status) == 'ACCEPTED')
            Text(
              'Driver: ${_driverInfoLabel()}',
              style: TextStyle(
                color: AppColors.textCyan200.withOpacity(0.92),
                fontSize: 12,
              ),
            ),
          if (_normalizeStatus(status) == 'ACCEPTED')
            Text(
              'driverName: ${_latestBooking?.driverName?.isNotEmpty == true ? _latestBooking!.driverName : 'not provided'}',
              style: TextStyle(
                color: AppColors.textCyan200.withOpacity(0.92),
                fontSize: 12,
              ),
            ),
          if (_normalizeStatus(status) == 'ACCEPTED')
            Text(
              'driverPhone: ${_latestBooking?.driverPhone?.isNotEmpty == true ? _latestBooking!.driverPhone : 'not provided'}',
              style: TextStyle(
                color: AppColors.textCyan200.withOpacity(0.92),
                fontSize: 12,
              ),
            ),
          if (_normalizeStatus(status) == 'ACCEPTED')
            Text(
              'vehiclePlate: ${_latestBooking?.vehiclePlate?.isNotEmpty == true ? _latestBooking!.vehiclePlate : 'not provided'}',
              style: TextStyle(
                color: AppColors.textCyan200.withOpacity(0.92),
                fontSize: 12,
              ),
            ),
          if (_normalizeStatus(status) == 'ACCEPTED')
            Text(
              'driverLatitude: ${_latestBooking?.driverLatitude?.toStringAsFixed(6) ?? 'not provided'}',
              style: TextStyle(
                color: AppColors.textCyan200.withOpacity(0.92),
                fontSize: 12,
              ),
            ),
          if (_normalizeStatus(status) == 'ACCEPTED')
            Text(
              'driverLongitude: ${_latestBooking?.driverLongitude?.toStringAsFixed(6) ?? 'not provided'}',
              style: TextStyle(
                color: AppColors.textCyan200.withOpacity(0.92),
                fontSize: 12,
              ),
            ),
          if (_canUserDecideDriver())
            Text(
              'User decision required: please Accept or Reject this driver.',
              style: TextStyle(
                color: Colors.amberAccent.withOpacity(0.95),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (_normalizeStatus(status) == 'FAILED' &&
              _latestBooking?.failureMessage != null &&
              _latestBooking!.failureMessage!.isNotEmpty)
            Text(
              'Failure: ${_latestBooking!.failureMessage}',
              style: TextStyle(
                color: AppColors.textCyan200.withOpacity(0.92),
                fontSize: 12,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            _pollingProposalStatus
                ? 'Waiting for provider decision... auto-refresh every 5s.'
                : 'Status handled fully in app (no Uber web redirect).',
            style: TextStyle(
              color: AppColors.textCyan200.withOpacity(0.80),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _refreshingProposalStatus
                      ? null
                      : () => unawaited(_refreshLatestProposalStatus()),
                  icon: _refreshingProposalStatus
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 16),
                  label: Text(
                    _refreshingProposalStatus
                        ? 'Refreshing...'
                        : 'Refresh status',
                  ),
                ),
                if (!isTerminal)
                  OutlinedButton.icon(
                    onPressed: _cancelCurrentProposal,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Cancel request'),
                  ),
                if (_canUserDecideDriver())
                  FilledButton.icon(
                    onPressed: _submittingDriverDecision
                        ? null
                        : () => unawaited(_submitDriverDecision(accept: true)),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Accept driver'),
                  ),
                if (_canUserDecideDriver())
                  OutlinedButton.icon(
                    onPressed: _submittingDriverDecision
                        ? null
                        : () => unawaited(_submitDriverDecision(accept: false)),
                    icon: const Icon(Icons.person_off, size: 16),
                    label: const Text('Reject driver'),
                  ),
              ],
            ),
          ),
          if (_proposalStatusHistory.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Timeline',
              style: TextStyle(
                color: AppColors.textCyan200.withOpacity(0.92),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _proposalStatusHistory.reversed.take(4).join('\n'),
              style: TextStyle(
                color: AppColors.textCyan200.withOpacity(0.85),
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }

  LatLng get _initialCenter {
    return _defaultTestHub;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.getResponsiveValue(
      context,
      mobile: 20.0,
      tablet: 28.0,
      desktop: 36.0,
    );

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
          bottom: false,
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: padding,
                  right: padding,
                  top: padding,
                  bottom: isMobile ? 110 : 130,
                ),
                child:
                    Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(context),
                            const SizedBox(height: 16),
                            _buildControlPanel(context),
                            const SizedBox(height: 16),
                            _buildMapCard(context),
                            const SizedBox(height: 12),
                            _buildEstimateCard(context),
                            if (_latestProposal != null) ...[
                              const SizedBox(height: 12),
                              _buildProposalCard(context),
                            ],
                            if (_showDebugPanel) ...[
                              const SizedBox(height: 12),
                              _buildDebugPanel(context),
                            ],
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 12),
                              _buildErrorBanner(context),
                            ],
                            if (_bookingStatusMessage != null) ...[
                              const SizedBox(height: 12),
                              _buildSuccessBanner(context),
                            ],
                            const SizedBox(height: 16),
                            _buildActionCards(context),
                          ],
                        )
                        .animate()
                        .fadeIn(duration: 350.ms)
                        .slideY(begin: 0.05, end: 0, duration: 350.ms),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: NavigationBarWidget(currentPath: '/travel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Travel Live',
          style: TextStyle(
            fontSize: Responsive.getResponsiveValue(
              context,
              mobile: 30.0,
              tablet: 34.0,
              desktop: 40.0,
            ),
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Dynamic map, live GPS, real-time route, taxi flow fully in app.',
          style: TextStyle(
            fontSize: Responsive.getResponsiveValue(
              context,
              mobile: 13.0,
              tablet: 14.0,
              desktop: 15.0,
            ),
            color: AppColors.textCyan200.withOpacity(0.85),
          ),
        ),
      ],
    );
  }

  Widget _buildControlPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _destinationController,
            onSubmitted: (_) => unawaited(_applyManualDestination()),
            decoration: InputDecoration(
              labelText: 'To (map or manual lat,lng)',
              hintText: 'Tap map or type: 36.80421, 10.17453',
              suffixIcon: IconButton(
                tooltip: 'Use manual coordinates',
                onPressed: () => unawaited(_applyManualDestination()),
                icon: const Icon(Icons.check_circle_outline),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.schedule),
                  label: Text('Pickup ${_plannedTime.format(context)}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    setState(() => _selectingFromOnMap = !_selectingFromOnMap);
                  },
                  icon: Icon(
                    _selectingFromOnMap ? Icons.touch_app : Icons.pin_drop,
                  ),
                  label: Text(
                    _selectingFromOnMap
                        ? 'Tap map: set A (From)'
                        : 'Select A on map',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openFullMapSelection,
              icon: const Icon(Icons.map),
              label: const Text('Open full map for selection'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => unawaited(_applyManualDestination()),
              icon: const Icon(Icons.edit_location_alt_outlined),
              label: const Text('Use manual To (lat, lng)'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => unawaited(_refreshInAppData()),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh live estimate and status'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _mapController.move(_defaultTestHub, 13.5);
              },
              icon: const Icon(Icons.public),
              label: const Text('Go to default test hub'),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Default hub: $_defaultTestHubLabel',
            style: TextStyle(
              color: AppColors.textCyan200.withOpacity(0.78),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _loadingRoute
                      ? null
                      : () {
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
                            setState(() {
                              _errorMessage =
                                  'Set destination from map or type: latitude, longitude.';
                            });
                            return;
                          }
                          unawaited(_buildRoute());
                          unawaited(_fetchMobilityEstimate());
                        },
                  icon: _loadingRoute
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.alt_route),
                  label: const Text('Trace route from map'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _pickupLatLng = null;
                      _destinationLatLng = null;
                      _destinationController.clear();
                      _routePoints = const <LatLng>[];
                      _distanceKm = null;
                      _durationMin = null;
                      _estimate = null;
                      _estimateInfoMessage = null;
                    });
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear A/B'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.my_location, size: 15, color: AppColors.cyan400),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _loadingLocation
                      ? 'Loading GPS...'
                      : _currentPosition == null
                      ? 'GPS unavailable'
                      : 'GPS: ${_currentPosition!.latitude.toStringAsFixed(5)}, ${_currentPosition!.longitude.toStringAsFixed(5)}',
                  style: TextStyle(
                    color: AppColors.textCyan200.withOpacity(0.8),
                  ),
                ),
              ),
              TextButton(
                onPressed: _loadLocation,
                child: const Text('Refresh GPS'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.place, size: 15, color: AppColors.cyan400),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'From A: ${_pickupLatLng == null ? 'GPS current location' : _coordsLabel(_pickupLatLng!)}',
                  style: TextStyle(
                    color: AppColors.textCyan200.withOpacity(0.82),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.flag, size: 15, color: AppColors.cyan400),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'To B: ${_destinationLatLng == null ? 'tap map to set destination' : _coordsLabel(_destinationLatLng!)}',
                  style: TextStyle(
                    color: AppColors.textCyan200.withOpacity(0.82),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.local_taxi, size: 15, color: Colors.amberAccent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _loadingNearbyTaxis
                      ? 'Searching nearby taxi stations...'
                      : _nearbyTaxiError != null
                      ? 'Taxi stations unavailable now (${_nearbyTaxiError!}).'
                      : _nearbyTaxiPoints.isEmpty
                      ? 'No nearby taxi station found near map center (${(_nearbyTaxiSearchCenter?.latitude ?? 0).toStringAsFixed(4)}, ${(_nearbyTaxiSearchCenter?.longitude ?? 0).toStringAsFixed(4)}).'
                      : 'Nearest taxi station: ${_nearestTaxiDistanceLabel()} • points: ${_nearbyTaxiPoints.length}',
                  style: TextStyle(
                    color: AppColors.textCyan200.withOpacity(0.82),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.alarm, size: 15, color: AppColors.cyan400),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Daily rule at ${_plannedTime.format(context)} (editable example)',
                  style: TextStyle(
                    color: AppColors.textCyan200.withOpacity(0.82),
                  ),
                ),
              ),
              if (_syncingDailyRule)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Switch.adaptive(
                  value: _dailyRuleEnabled,
                  onChanged: (value) {
                    setState(() => _dailyRuleEnabled = value);
                    unawaited(_syncDailyRule(enabled: value));
                  },
                ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() => _showDebugPanel = !_showDebugPanel);
              },
              icon: Icon(
                _showDebugPanel ? Icons.bug_report : Icons.bug_report_outlined,
                size: 16,
                color: AppColors.cyan400,
              ),
              label: Text(
                _showDebugPanel
                    ? 'Hide debug diagnostics'
                    : 'Show debug diagnostics',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugPanel(BuildContext context) {
    final best = _estimate?.best;
    final destination = _destinationLatLng == null
        ? _destinationController.text.trim()
        : _coordsLabel(_destinationLatLng!);

    String _fmtDouble(double? value, {int digits = 5}) {
      if (value == null) return 'n/a';
      return value.toStringAsFixed(digits);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.terminal, size: 16, color: AppColors.cyan400),
              const SizedBox(width: 8),
              const Text(
                'Travel Debug Diagnostics',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Destination: ${destination.isEmpty ? 'n/a' : destination}',
            style: TextStyle(
              color: AppColors.textCyan200.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
          Text(
            'From: ${_pickupLatLng == null ? '${_fmtDouble(_currentPosition?.latitude)}, ${_fmtDouble(_currentPosition?.longitude)}' : _coordsLabel(_pickupLatLng!)}',
            style: TextStyle(
              color: AppColors.textCyan200.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
          Text(
            'To: ${_fmtDouble(_destinationLatLng?.latitude)}, ${_fmtDouble(_destinationLatLng?.longitude)}',
            style: TextStyle(
              color: AppColors.textCyan200.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
          Text(
            'Route: ${_distanceKm?.toStringAsFixed(1) ?? 'n/a'} km • ${_durationMin?.round() ?? 'n/a'} min',
            style: TextStyle(
              color: AppColors.textCyan200.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
          Text(
            'Estimate mode: backend-live-only',
            style: TextStyle(
              color: AppColors.textCyan200.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
          Text(
            'Retry: attempts=$_estimateRetryAttempts pending=$_estimateRetryPending',
            style: TextStyle(
              color: AppColors.textCyan200.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
          Text(
            'Best provider: ${best?.provider ?? 'n/a'}',
            style: TextStyle(
              color: AppColors.textCyan200.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
          if (best != null)
            Text(
              'Best price: ${best.minPrice.toStringAsFixed(1)} - ${best.maxPrice.toStringAsFixed(1)} TND • ETA ${best.etaMinutes} min',
              style: TextStyle(
                color: AppColors.textCyan200.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
          Text(
            'Daily rule: id=${_dailyRuleId ?? 'n/a'} enabled=$_dailyRuleEnabled syncing=$_syncingDailyRule',
            style: TextStyle(
              color: AppColors.textCyan200.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
          Text(
            'Last backend error code: ${_lastMobilityErrorCode ?? 'n/a'}',
            style: TextStyle(
              color: AppColors.textCyan200.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
          Text(
            'Last backend error body: ${_lastMobilityErrorBody ?? 'n/a'}',
            style: TextStyle(
              color: AppColors.textCyan200.withOpacity(0.9),
              fontSize: 12,
            ),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Booking backend status: ${_lastBookingBackendStatus ?? 'n/a'}',
            style: TextStyle(
              color: AppColors.textCyan200.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard(BuildContext context) {
    return Container(
      height: 340,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.22)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _initialCenter,
                initialZoom: 12.8,
                minZoom: 4,
                maxZoom: 18,
                onTap: (_, point) {
                  unawaited(_onMapTapped(point));
                },
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
                        width: 32,
                        height: 32,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.92),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.black.withOpacity(0.6),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.local_taxi,
                            color: Colors.black,
                            size: 18,
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
                            color: Colors.lightGreenAccent.withOpacity(0.95),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.black.withOpacity(0.65),
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
                        width: 44,
                        height: 44,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    if (_pickupLatLng != null)
                      Marker(
                        point: _pickupLatLng!,
                        width: 44,
                        height: 44,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.trip_origin,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    if (_destinationLatLng != null)
                      Marker(
                        point: _destinationLatLng!,
                        width: 48,
                        height: 48,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.navigation,
                      size: 16,
                      color: AppColors.cyan400,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _loadingRoute
                            ? 'Building live route...'
                            : _distanceKm == null
                            ? 'Tap map to set A/B and build route.'
                            : '${_distanceKm!.toStringAsFixed(1)} km • ${_durationMin!.round()} min',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      onPressed: _openFullMapSelection,
                      icon: const Icon(Icons.open_in_full, color: Colors.white),
                      tooltip: 'Open full map',
                    ),
                    IconButton(
                      onPressed: _loadingNearbyTaxis
                          ? null
                          : () => unawaited(_fetchNearbyTaxiStations()),
                      icon: Icon(
                        Icons.local_taxi,
                        color: _nearbyTaxiPoints.isEmpty
                            ? Colors.white
                            : Colors.amberAccent,
                      ),
                      tooltip: 'Refresh nearby taxi stations',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _actionCard(
            context,
            icon: LucideIcons.car,
            title: 'Request Taxi (In-App)',
            subtitle: _confirmingBooking
                ? 'Sending proposal to backend...'
                : 'Track accepted/refused status directly in this app',
            onTap: _confirmInAppTaxiRequest,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionCard(
            context,
            icon: LucideIcons.navigation,
            title: 'Open Dynamic Map',
            subtitle: 'External turn-by-turn route',
            onTap: () async {
              final fromPoint =
                  _pickupLatLng ??
                  (_currentPosition == null
                      ? null
                      : LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ));
              if (_destinationLatLng == null || fromPoint == null) {
                setState(
                  () => _errorMessage =
                      'Tap map to define A (from) and B (to) first.',
                );
                return;
              }
              final origin = '${fromPoint.latitude},${fromPoint.longitude}';
              final uri = Uri.https('www.google.com', '/maps/dir/', {
                'api': '1',
                'origin': origin,
                'destination':
                    '${_destinationLatLng!.latitude},${_destinationLatLng!.longitude}',
                'travelmode': 'driving',
              });
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
          ),
        ),
      ],
    );
  }

  Widget _actionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1e4a66).withOpacity(0.45),
              const Color(0xFF16384d).withOpacity(0.45),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cyan500.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.cyan400, size: 20),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.textCyan200.withOpacity(0.85),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
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
