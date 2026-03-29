import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../models/campaign_result_model.dart';
import '../services/social_media_campaign_service.dart';

class SocialMediaSendScreen extends StatefulWidget {
  final CampaignResultModel result;

  const SocialMediaSendScreen({super.key, required this.result});

  @override
  State<SocialMediaSendScreen> createState() => _SocialMediaSendScreenState();
}

class _SocialMediaSendScreenState extends State<SocialMediaSendScreen>
    with SingleTickerProviderStateMixin {
  final _recipientsCtrl = TextEditingController();
  final _departmentCtrl =
      TextEditingController(text: 'Social Media Department');
  final _notesCtrl = TextEditingController();
  bool _attachPdf = true;
  bool _isSending = false;
  String? _errorMessage;

  late AnimationController _checkAnimController;

  static final _service = SocialMediaCampaignService.instance;

  @override
  void initState() {
    super.initState();
    _checkAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _recipientsCtrl.dispose();
    _departmentCtrl.dispose();
    _notesCtrl.dispose();
    _checkAnimController.dispose();
    super.dispose();
  }

  List<String> get _parsedRecipients => _recipientsCtrl.text
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  Future<void> _send() async {
    setState(() => _errorMessage = null);

    final recipients = _parsedRecipients;
    if (recipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter at least one recipient.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await _service.sendCampaignReport(
        widget.result.id,
        recipients,
        _notesCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() => _isSending = false);
      _showSuccessSheet();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _errorMessage = _friendlyError(e);
      });
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('Connection')) {
      return 'No connection. Check your internet and try again.';
    }
    if (msg.contains('400')) {
      return 'Invalid request. Check recipients and try again.';
    }
    return 'Failed to send. Please try again.';
  }

  void _showSuccessSheet() {
    _checkAnimController.forward(from: 0);
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SuccessSheet(
        animController: _checkAnimController,
        onDone: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).popUntil((r) => r.isFirst);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCampaignSummary(),
                      const SizedBox(height: 24),
                      if (_errorMessage != null) _buildErrorBanner(),
                      _sectionLabel('Recipients'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _recipientsCtrl,
                        hint: 'email1@company.com, email2@company.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          'Separate multiple emails with commas',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textCyan200.withOpacity(0.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _sectionLabel('Department'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _departmentCtrl,
                        hint: 'Social Media Department',
                      ),
                      const SizedBox(height: 20),
                      _sectionLabel('Additional Notes (optional)'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _notesCtrl,
                        hint: 'Any special instructions or context…',
                        maxLines: 4,
                      ),
                      const SizedBox(height: 24),
                      _buildPdfToggle(),
                      const SizedBox(height: 32),
                      _buildSendButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cyan500.withOpacity(0.2)),
              ),
              child: const Icon(LucideIcons.arrowLeft,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Send to Department',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEC4899).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: const Color(0xFFEC4899).withOpacity(0.3)),
            ),
            child: const Icon(LucideIcons.send,
                color: Color(0xFFEC4899), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEC4899).withOpacity(0.1),
            const Color(0xFFA855F7).withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEC4899).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEC4899), Color(0xFFA855F7)],
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child:
                const Icon(LucideIcons.megaphone, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.result.productName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${widget.result.platforms.join(', ')} • ${widget.result.toneOfVoice}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textCyan200.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.15),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Text(
              'Ready',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF10B981),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertCircle,
              color: Colors.redAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textCyan200.withOpacity(0.85),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.cyan500.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppColors.cyan400.withOpacity(0.6), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPdfToggle() {
    return GestureDetector(
      onTap: () => setState(() => _attachPdf = !_attachPdf),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cyan500.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.cyan500.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(LucideIcons.fileText, color: AppColors.cyan400, size: 20),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attach full report as PDF',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Includes all platform strategies & analytics',
                    style:
                        TextStyle(fontSize: 11, color: Color(0xFFA5F3FC)),
                  ),
                ],
              ),
            ),
            Switch(
              value: _attachPdf,
              onChanged: (v) => setState(() => _attachPdf = v),
              activeColor: AppColors.cyan400,
              activeTrackColor: AppColors.cyan500.withOpacity(0.3),
              inactiveThumbColor: Colors.white.withOpacity(0.4),
              inactiveTrackColor: Colors.white.withOpacity(0.1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: _isSending ? null : _send,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isSending
                ? [
                    const Color(0xFFEC4899).withOpacity(0.5),
                    const Color(0xFFA855F7).withOpacity(0.5),
                  ]
                : const [Color(0xFFEC4899), Color(0xFFA855F7)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isSending
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFFEC4899).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: _isSending
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.send, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Send Report',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── Success Bottom Sheet ─────────────────────────────────────────────────────

class _SuccessSheet extends StatelessWidget {
  final AnimationController animController;
  final VoidCallback onDone;

  const _SuccessSheet({
    required this.animController,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 48),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1a3a52), Color(0xFF0f2940)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 32),
          ScaleTransition(
            scale: CurvedAnimation(
              parent: animController,
              curve: Curves.elasticOut,
            ),
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF34D399)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.4),
                    blurRadius: 28,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child:
                  const Icon(LucideIcons.check, color: Colors.white, size: 40),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Campaign Report Sent!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
          const SizedBox(height: 10),
          Text(
            'Your campaign report has been sent to the Social Media Department successfully.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textCyan200.withOpacity(0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          const SizedBox(height: 36),
          GestureDetector(
            onTap: onDone,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF34D399)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Text(
                'Done',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
        ],
      ),
    );
  }
}
