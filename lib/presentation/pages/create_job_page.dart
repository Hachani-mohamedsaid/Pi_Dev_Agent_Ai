import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/create_job_service.dart';
import '../widgets/navigation_bar.dart';

class CreateJobPage extends StatefulWidget {
  const CreateJobPage({super.key});

  @override
  State<CreateJobPage> createState() => _CreateJobPageState();
}

class _CreateJobPageState extends State<CreateJobPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtl = TextEditingController();
  final _companyCtl = TextEditingController();
  final _departmentCtl = TextEditingController();
  final _descriptionCtl = TextEditingController();

  bool _publish = false;
  bool _isLoading = false;
  final _service = CreateJobService();

  @override
  void dispose() {
    _titleCtl.dispose();
    _companyCtl.dispose();
    _departmentCtl.dispose();
    _descriptionCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final body = <String, dynamic>{
        'title': _titleCtl.text.trim(),
        'company': _companyCtl.text.trim(),
        'department': _departmentCtl.text.trim(),
        'description': _descriptionCtl.text.trim(),
        'publish': _publish,
        'base_form_url': baseGoogleFormUrl,
      };

      final result = await _service.createJob(body);

      if (!mounted) return;
      _showSuccessDialog(result);
    } on CreateJobException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur inattendue : $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Dialog de succès ────────────────────────────────────────────────

  void _showSuccessDialog(Map<String, dynamic> data) {
    final postUrl = data['post_url'] as String? ?? '';
    final jobId = data['job_id'] as String? ?? '';
    final applyFormUrl = data['apply_form_url'] as String? ?? '';

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF142E42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Post créé ✅',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Job ID (masqué si absent)
              if (jobId.isNotEmpty) ...[
                _infoRow('Job ID', jobId),
                const SizedBox(height: 14),
              ],

              // Post URL LinkedIn (cliquable)
              if (postUrl.isNotEmpty) ...[
                const Text(
                  'Lien LinkedIn :',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _openUrl(postUrl),
                  child: Text(
                    postUrl,
                    style: const TextStyle(
                      color: AppColors.cyan400,
                      decoration: TextDecoration.underline,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Apply Form URL (masqué si absent)
              if (applyFormUrl.isNotEmpty) ...[
                const Text(
                  'Formulaire de candidature :',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _openUrl(applyFormUrl),
                  child: Text(
                    applyFormUrl,
                    style: const TextStyle(
                      color: AppColors.cyan400,
                      decoration: TextDecoration.underline,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 14),
              ],

              const Divider(color: Colors.white24),
              const SizedBox(height: 8),

              // Boutons d'action
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (postUrl.isNotEmpty)
                    FilledButton.icon(
                      onPressed: () => _openUrl(postUrl),
                      icon: const Icon(LucideIcons.externalLink, size: 16),
                      label: const Text('Ouvrir LinkedIn'),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.cyan500),
                    ),
                  if (postUrl.isNotEmpty)
                    FilledButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: postUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lien copié !')),
                        );
                      },
                      icon: const Icon(LucideIcons.copy, size: 16),
                      label: const Text('Copier le lien'),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.primaryLight),
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label : ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
        ),
      ],
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────

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
              // AppBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.go('/home'),
                      icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textWhite),
                    ),
                    const Expanded(
                      child: Text(
                        'ATS Admin',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textWhite,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Formulaire
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _fieldCard(
                          child: TextFormField(
                            controller: _titleCtl,
                            decoration: const InputDecoration(
                              labelText: 'Job Title *',
                              hintText: 'Ex. Software Engineer',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
                          ),
                        ),
                        _fieldCard(
                          child: TextFormField(
                            controller: _companyCtl,
                            decoration: const InputDecoration(
                              labelText: 'Company (optionnel)',
                              hintText: 'Ex. Ma Société',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        _fieldCard(
                          child: TextFormField(
                            controller: _departmentCtl,
                            decoration: const InputDecoration(
                              labelText: 'Department (optionnel)',
                              hintText: 'Ex. Engineering',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        _fieldCard(
                          child: TextFormField(
                            controller: _descriptionCtl,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Description (optionnel)',
                              hintText: 'Décrivez le poste...',
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        Card(
                          color: const Color(0xFF1E4A66).withValues(alpha: 0.5),
                          child: SwitchListTile(
                            title: const Text('Publish'),
                            subtitle: const Text('Publier le post (par défaut : non)'),
                            value: _publish,
                            onChanged: (v) => setState(() => _publish = v),
                          ),
                        ),
                        _fieldCard(
                          child: TextFormField(
                            initialValue: baseGoogleFormUrl,
                            readOnly: true,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Base Google Form URL',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        FilledButton(
                          onPressed: _isLoading ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.cyan500,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Créer le poste', style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const NavigationBarWidget(currentPath: '/create-job'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldCard({required Widget child}) {
    return Card(
      color: const Color(0xFF1E4A66).withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
