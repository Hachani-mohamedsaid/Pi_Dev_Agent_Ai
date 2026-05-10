import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class TripPlannerPage extends StatefulWidget {
  const TripPlannerPage({super.key});

  @override
  State<TripPlannerPage> createState() => _TripPlannerPageState();
}

class _TripPlannerPageState extends State<TripPlannerPage> {
  final _destinationController = TextEditingController();
  final _budgetController = TextEditingController();
  DateTime? _checkIn;
  DateTime? _checkOut;
  int _travelers = 1;
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  static const _n8nUrl =
      'https://n8n-production-1e13.up.railway.app/webhook/ava-travel';

  Future<void> _planTrip() async {
    if (_destinationController.text.isEmpty ||
        _budgetController.text.isEmpty ||
        _checkIn == null ||
        _checkOut == null) {
      setState(() => _error = 'Please fill all fields');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final response = await http.post(
        Uri.parse(_n8nUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'destination': _destinationController.text.trim(),
          'budget': _budgetController.text.trim(),
          'currency': 'TND',
          'checkIn': _checkIn!.toIso8601String().split('T')[0],
          'checkOut': _checkOut!.toIso8601String().split('T')[0],
          'travelers': _travelers,
        }),
      );
      if (response.statusCode == 200) {
        setState(() => _result = jsonDecode(response.body));
      } else {
        setState(() => _error = 'Failed to get travel plan');
      }
    } catch (e) {
      setState(() => _error = 'Connection error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickDate(bool isCheckIn) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn
          ? (_checkIn ?? now.add(const Duration(days: 7)))
          : (_checkOut ?? now.add(const Duration(days: 14))),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF20b2aa),
            surface: Color(0xFF0d1b2e),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isCheckIn) _checkIn = picked;
        else _checkOut = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0f1a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF081220),
        foregroundColor: Colors.white,
        title: const Row(children: [
          Text('✈️ ', style: TextStyle(fontSize: 20)),
          Text('Trip Planner',
              style: TextStyle(
                  color: Color(0xFF20b2aa),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
        ]),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: const Color(0xFF20b2aa)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildForm(),
            if (_error != null) _buildError(),
            if (_loading) _buildLoading(),
            if (_result != null) _buildResult(),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0d1b2e),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF20b2aa).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Plan Your Trip',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Get instant booking links for flights, hotels & more',
              style:
                  TextStyle(color: Color(0xFF64748b), fontSize: 13)),
          const SizedBox(height: 20),
          _field(_destinationController, '🌍 Destination',
              'e.g. Paris, Dubai, London'),
          const SizedBox(height: 12),
          _field(_budgetController, '💰 Budget (TND)', 'e.g. 3000',
              type: TextInputType.number),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: _dateField('📅 Check-in', _checkIn,
                    () => _pickDate(true))),
            const SizedBox(width: 12),
            Expanded(
                child: _dateField('📅 Check-out', _checkOut,
                    () => _pickDate(false))),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF081220),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color:
                      const Color(0xFF20b2aa).withOpacity(0.3)),
            ),
            child: Row(children: [
              const Text('👥 Travelers',
                  style: TextStyle(
                      color: Color(0xFF94a3b8), fontSize: 14)),
              const Spacer(),
              IconButton(
                onPressed: () {
                  if (_travelers > 1)
                    setState(() => _travelers--);
                },
                icon: const Icon(Icons.remove_circle_outline,
                    color: Color(0xFF20b2aa)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Text('$_travelers',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => setState(() => _travelers++),
                icon: const Icon(Icons.add_circle_outline,
                    color: Color(0xFF20b2aa)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _planTrip,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF20b2aa),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Plan My Trip →',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, String hint,
      {TextInputType? type}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              color: Color(0xFF94a3b8), fontSize: 13)),
      const SizedBox(height: 6),
      TextField(
        controller: c,
        keyboardType: type,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: Color(0xFF475569)),
          filled: true,
          fillColor: const Color(0xFF081220),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: const Color(0xFF20b2aa)
                      .withOpacity(0.3))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: const Color(0xFF20b2aa)
                      .withOpacity(0.3))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: Color(0xFF20b2aa))),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
      ),
    ]);
  }

  Widget _dateField(
      String label, DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF94a3b8), fontSize: 13)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF081220),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF20b2aa)
                        .withOpacity(0.3)),
              ),
              child: Text(
                date != null
                    ? '${date.day}/${date.month}/${date.year}'
                    : 'Select date',
                style: TextStyle(
                    color: date != null
                        ? Colors.white
                        : const Color(0xFF475569),
                    fontSize: 14),
              ),
            ),
          ]),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(children: [
          CircularProgressIndicator(color: Color(0xFF20b2aa)),
          SizedBox(height: 16),
          Text('Building your travel plan...',
              style: TextStyle(color: Color(0xFF64748b))),
        ]),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF7f1d1d).withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Text(_error!,
          style:
              const TextStyle(color: Colors.red, fontSize: 14)),
    );
  }

  Widget _buildResult() {
    final r = _result!;
    final budget = r['budget'] as Map<String, dynamic>;
    final breakdown =
        budget['breakdown'] as Map<String, dynamic>;
    final links = r['links'] as List<dynamic>;
    final tips = r['tips'] as List<dynamic>;

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0d1b2e),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFF20b2aa)
                      .withOpacity(0.3)),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Text('🌍 ',
                        style: TextStyle(fontSize: 20)),
                    Text(r['destination'],
                        style: const TextStyle(
                            color: Color(0xFF20b2aa),
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: [
                    _chip('📅 ${r['duration']}'),
                    _chip(
                        '👥 ${r['travelers']} traveler(s)'),
                  ]),
                  const SizedBox(height: 16),
                  const Text('Budget Breakdown',
                      style: TextStyle(
                          color: Color(0xFF94a3b8),
                          fontSize: 12,
                          letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text(
                      'Total: ${budget['original']} ≈ ${budget['eur']}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...breakdown.entries.map((e) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: 4),
                        child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  e.key[0].toUpperCase() +
                                      e.key.substring(1),
                                  style: const TextStyle(
                                      color:
                                          Color(0xFF64748b),
                                      fontSize: 13)),
                              Text(e.value.toString(),
                                  style: const TextStyle(
                                      color:
                                          Color(0xFF94a3b8),
                                      fontSize: 13)),
                            ]),
                      )),
                ]),
          ),
          const SizedBox(height: 20),
          const Text('🔗 Book Now',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...links.map((link) {
            final color = Color(int.parse(
                (link['color'] as String)
                    .replaceAll('#', '0xFF')));
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () async {
                  final url = Uri.parse(link['url']);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url,
                        mode: LaunchMode.externalApplication);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0d1b2e),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: color.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                          color: color,
                          borderRadius:
                              BorderRadius.circular(2)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                        child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                          Text(link['label'],
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight:
                                      FontWeight.w600)),
                          Text(link['description'],
                              style: const TextStyle(
                                  color: Color(0xFF64748b),
                                  fontSize: 12)),
                        ])),
                    Icon(Icons.arrow_forward_ios,
                        color: color, size: 16),
                  ]),
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0d1b2e),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFFf59e0b)
                      .withOpacity(0.2)),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡 Travel Tips',
                      style: TextStyle(
                          color: Color(0xFFf59e0b),
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...tips.asMap().entries.map((e) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: 8),
                        child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text('${e.key + 1}. ',
                                  style: const TextStyle(
                                      color:
                                          Color(0xFFf59e0b),
                                      fontWeight:
                                          FontWeight.bold,
                                      fontSize: 13)),
                              Expanded(
                                  child: Text(
                                      e.value.toString(),
                                      style: const TextStyle(
                                          color: Color(
                                              0xFF94a3b8),
                                          fontSize: 13,
                                          height: 1.4))),
                            ]),
                      )),
                ]),
          ),
          const SizedBox(height: 32),
        ]);
  }

  Widget _chip(String text) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF20b2aa).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF20b2aa).withOpacity(0.3)),
      ),
      child: Text(text,
          style: const TextStyle(
              color: Color(0xFF20b2aa), fontSize: 12)),
    );
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }
}
