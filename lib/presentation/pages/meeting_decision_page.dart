import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../state/meeting_decision_controller.dart';
import '../../injection_container.dart';

class MeetingDecisionPage extends StatefulWidget {
  final MeetingDecisionController? controller;
  final String token;

  const MeetingDecisionPage({super.key, this.controller, required this.token});

  @override
  State<MeetingDecisionPage> createState() => _MeetingDecisionPageState();
}

class _MeetingDecisionPageState extends State<MeetingDecisionPage> {
  late MeetingDecisionController _controller;
  final _durationController = TextEditingController(text: '30');
  String? _token;
  bool _isLoadingToken = true;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ??
        InjectionContainer.instance.buildMeetingDecisionController();
    _controller.addListener(_onControllerChanged);
    if (kDebugMode) {
      debugPrint('🔁 MeetingDecisionPage.initState called');
      debugPrint('🔎 controller.hashCode (initState): ${_controller.hashCode}');
    }
    _loadToken();
  }

  Future<void> _loadToken() async {
    if (widget.token.isNotEmpty) {
      _token = widget.token;
    } else {
      try {
        final prefs = await SharedPreferences.getInstance();
        _token = prefs.getString('auth_access_token') ?? '';
      } catch (e) {
        _token = '';
      }
    }

    setState(() {
      _isLoadingToken = false;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _durationController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (_controller.successMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.successMessage ?? ''),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 3),
        ),
      );
      _controller.clearMessages();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _controller.selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      _controller.setDate(picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _controller.selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      if (kDebugMode) debugPrint('Time picked: $picked');
      _controller.setTime(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meeting Decision'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            if (kDebugMode) {
              debugPrint(
                '🔁 ListenableBuilder rebuild — controller.hashCode: ${_controller.hashCode}',
              );
              debugPrint('VALIDATION RESULT: ${_controller.validateForm()}');
              debugPrint('isLoading: ${_controller.isLoading}');
              debugPrint('validation: ${_controller.validateForm()}');
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Meeting Date'),
                const SizedBox(height: 8),
                _buildDatePickerButton(context),
                const SizedBox(height: 24),
                _buildSectionTitle('Meeting Time'),
                const SizedBox(height: 8),
                _buildTimePickerButton(context),
                const SizedBox(height: 24),
                _buildSectionTitle('Decision'),
                const SizedBox(height: 8),
                _buildDecisionDropdown(),
                const SizedBox(height: 24),
                _buildSectionTitle('Duration (minutes)'),
                const SizedBox(height: 8),
                _buildDurationField(),
                const SizedBox(height: 32),
                if (_controller.selectedDate != null ||
                    _controller.selectedTime != null ||
                    _controller.durationMinutes != 30)
                  _buildSummary(),
                if (_controller.errorMessage != null) _buildErrorMessage(),
                const SizedBox(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        if (kDebugMode)
                          debugPrint(
                            '🔧 Force notify button pressed — calling notifyListeners()',
                          );
                        _controller.notifyListeners();
                      },
                      child: const Text('Force notify'),
                    ),
                    const SizedBox(height: 12),
                    _buildSubmitButton(context),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _buildDatePickerButton(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _selectDate(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _controller.selectedDate != null
                    ? '${_controller.selectedDate!.toLocal()}'.split(' ')[0]
                    : 'Select a date',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Icon(
                Icons.calendar_today,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimePickerButton(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _selectTime(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _controller.selectedTime != null
                    ? _controller.selectedTime!.format(context)
                    : 'Select a time',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Icon(
                Icons.access_time,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDecisionDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: _controller.selectedDecision,
        isExpanded: true,
        underline: const SizedBox(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            _controller.setDecision(newValue);
          }
        },
        items: [
          DropdownMenuItem(
            value: 'accept',
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade400,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text('Accept'),
              ],
            ),
          ),
          DropdownMenuItem(
            value: 'reject',
            child: Row(
              children: [
                Icon(Icons.cancel, color: Colors.red.shade400, size: 20),
                const SizedBox(width: 8),
                const Text('Reject'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationField() {
    return TextField(
      controller: _durationController,
      keyboardType: TextInputType.number,
      onChanged: (value) {
        final duration = int.tryParse(value);
        if (duration != null) {
          _controller.setDuration(duration);
        }
      },
      decoration: InputDecoration(
        hintText: 'Enter duration in minutes',
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(
          Icons.hourglass_bottom,
          color: Theme.of(context).colorScheme.primary,
        ),
        suffixText: 'min',
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Date',
            '${_controller.selectedDate?.toLocal()}'.split(' ')[0],
          ),
          _buildSummaryRow(
            'Time',
            _controller.selectedTime?.format(context) ?? 'N/A',
          ),
          _buildSummaryRow(
            'Decision',
            _controller.selectedDecision.toUpperCase(),
          ),
          _buildSummaryRow(
            'Duration',
            '${_controller.durationMinutes} minutes',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _controller.errorMessage ?? '',
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _controller.isLoading
            ? null
            : () async {
                if (kDebugMode) debugPrint('🚀 BUTTON CLICKED');
                // TODO: Replace dev-token with real JWT token after authentication integration
                await _controller.submitDecision("dev-token");
              },
        child: _controller.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text("Submit Decision"),
      ),
    );
  }
}
