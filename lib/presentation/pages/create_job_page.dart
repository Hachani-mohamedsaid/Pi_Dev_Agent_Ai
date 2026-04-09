import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/create_job_service.dart';
import '../widgets/navigation_bar.dart';

/// Assistant de publication LinkedIn : mêmes champs et même payload JSON
/// que l’ancien formulaire (`CreateJobService.createJob`).
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

  int _step = 0;
  static const int _stepCount = 3;

  bool _publish = false;
  bool _isLoading = false;
  bool _showFormUrl = false;
  final _service = CreateJobService();

  static const List<_DescriptionTemplate> _templates = [
    _DescriptionTemplate(
      label: 'Missions',
      body:
          'Missions principales :\n• \n• \n• ',
    ),
    _DescriptionTemplate(
      label: 'Profil',
      body:
          'Profil recherché :\n• Formation / expérience :\n• Compétences :\n• Qualités :',
    ),
    _DescriptionTemplate(
      label: 'Modalités',
      body:
          'Type de contrat : \nLocalisation : \nTélétravail : \nRémunération : ',
    ),
  ];

  @override
  void initState() {
    super.initState();
    for (final c in [_titleCtl, _companyCtl, _departmentCtl, _descriptionCtl]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _companyCtl.dispose();
    _departmentCtl.dispose();
    _descriptionCtl.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, {String? hint, int? maxLines}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: maxLines != null && maxLines > 1,
      labelStyle: TextStyle(
        color: AppColors.textCyan200.withValues(alpha: 0.85),
        fontSize: 13,
      ),
      hintStyle: TextStyle(
        color: AppColors.textCyan200.withValues(alpha: 0.4),
        fontSize: 13,
      ),
      filled: true,
      fillColor: AppColors.primaryDark.withValues(alpha: 0.95),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.cyan400.withValues(alpha: 0.25),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.textCyan200.withValues(alpha: 0.15),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cyan400, width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  void _appendTemplate(String block) {
    final c = _descriptionCtl;
    final sep = c.text.trim().isEmpty ? '' : '\n\n';
    c.text = '${c.text}$sep$block';
    c.selection = TextSelection.collapsed(offset: c.text.length);
    setState(() {});
  }

  bool _validateStep(int step) {
    if (step == 0) {
      return _formKey.currentState?.validate() ?? false;
    }
    return true;
  }

  void _goNext() {
    if (!_validateStep(_step)) return;
    if (_step < _stepCount - 1) {
      setState(() => _step++);
    }
  }

  void _goBack() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _submit() async {
    if (_titleCtl.text.trim().isEmpty) {
      setState(() => _step = 0);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('L’intitulé du poste est obligatoire.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
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
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Une erreur inattendue s’est produite. Réessayez dans un instant.',
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
                'Publication prête',
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
              if (jobId.isNotEmpty) ...[
                _infoRow('Référence', jobId),
                const SizedBox(height: 14),
              ],
              if (postUrl.isNotEmpty) ...[
                const Text(
                  'Lien vers le post LinkedIn',
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
              if (applyFormUrl.isNotEmpty) ...[
                const Text(
                  'Candidature (formulaire)',
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (postUrl.isNotEmpty)
                    FilledButton.icon(
                      onPressed: () => _openUrl(postUrl),
                      icon: const Icon(LucideIcons.externalLink, size: 16),
                      label: const Text('Ouvrir LinkedIn'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.cyan500,
                      ),
                    ),
                  if (postUrl.isNotEmpty)
                    FilledButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: postUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Lien copié dans le presse-papiers'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(LucideIcons.copy, size: 16),
                      label: const Text('Copier le lien'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                      ),
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

  Widget _stepHeader() {
    const titles = [
      'Définir l’offre',
      'Rédiger et prévisualiser',
      'Paramètres de diffusion',
    ];
    const hints = [
      'Intitulé et structure — le minimum pour lancer une publication soignée.',
      'Ajoutez du contexte ; l’aperçu reflète ce qui sera envoyé au workflow.',
      'Choisissez si le post est publié tout de suite et comment les candidats postulent.',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(_stepCount, (i) {
            final active = i == _step;
            final done = i < _step;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < _stepCount - 1 ? 6 : 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: done || active ? 1 : 0,
                              minHeight: 4,
                              backgroundColor: AppColors.textCyan200.withValues(alpha: 0.12),
                              color: done || active
                                  ? AppColors.cyan400
                                  : AppColors.textCyan200.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: active
                            ? AppColors.cyan400
                            : AppColors.textCyan200.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        Text(
          titles[_step],
          style: const TextStyle(
            color: AppColors.textWhite,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          hints[_step],
          style: TextStyle(
            color: AppColors.textCyan200.withValues(alpha: 0.78),
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _titleCtl,
          style: const TextStyle(color: AppColors.textWhite),
          decoration: _dec('Intitulé du poste *', hint: 'Ex. Ingénieur logiciel senior'),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Ce champ est obligatoire' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _companyCtl,
          style: const TextStyle(color: AppColors.textWhite),
          decoration: _dec('Entreprise', hint: 'Ex. Acme SAS'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _departmentCtl,
          style: const TextStyle(color: AppColors.textWhite),
          decoration: _dec('Service / direction', hint: 'Ex. Ingénierie produit'),
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Blocs suggérés',
          style: TextStyle(
            color: AppColors.textCyan200.withValues(alpha: 0.65),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _templates
              .map(
                (t) => ActionChip(
                  label: Text(t.label),
                  onPressed: () => _appendTemplate(t.body),
                  backgroundColor: AppColors.primaryDark.withValues(alpha: 0.9),
                  side: BorderSide(color: AppColors.cyan400.withValues(alpha: 0.35)),
                  labelStyle: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 18),
        TextFormField(
          controller: _descriptionCtl,
          style: const TextStyle(color: AppColors.textWhite),
          maxLines: 8,
          decoration: _dec(
            'Description de l’offre',
            hint: 'Contexte, missions, profil, avantages…',
            maxLines: 8,
          ),
        ),
        const SizedBox(height: 20),
        _LinkedInStylePreview(
          title: _titleCtl.text.trim(),
          company: _companyCtl.text.trim(),
          department: _departmentCtl.text.trim(),
          description: _descriptionCtl.text.trim(),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    final host = Uri.tryParse(baseGoogleFormUrl)?.host ?? 'formulaire configuré';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Publier sur LinkedIn',
            style: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            _publish
                ? 'Le workflow tentera une publication immédiate selon votre automatisation.'
                : 'Brouillon ou étape manuelle côté automatisation — selon votre scénario n8n.',
            style: TextStyle(
              color: AppColors.textCyan200.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
          value: _publish,
          activeThumbColor: AppColors.cyan400,
          onChanged: (v) => setState(() => _publish = v),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cyan400.withValues(alpha: 0.2)),
            color: AppColors.primaryDarker.withValues(alpha: 0.9),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.clipboardCheck,
                    color: AppColors.cyan400.withValues(alpha: 0.9),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Candidatures',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Les candidats sont orientés vers le formulaire défini dans la configuration '
                'de l’application. Vous n’avez pas à coller d’URL à chaque publication.',
                style: TextStyle(
                  color: AppColors.textCyan200.withValues(alpha: 0.85),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hébergeur : $host',
                style: TextStyle(
                  color: AppColors.textCyan200.withValues(alpha: 0.55),
                  fontSize: 12,
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _showFormUrl = !_showFormUrl),
                icon: Icon(
                  _showFormUrl ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 18,
                  color: AppColors.cyan400,
                ),
                label: Text(
                  _showFormUrl ? 'Masquer l’URL technique' : 'Voir l’URL du formulaire',
                  style: const TextStyle(color: AppColors.cyan400, fontSize: 13),
                ),
              ),
              if (_showFormUrl) ...[
                SelectableText(
                  baseGoogleFormUrl,
                  style: TextStyle(
                    color: AppColors.textCyan200.withValues(alpha: 0.75),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.go('/home'),
                      icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textWhite),
                    ),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Publication LinkedIn',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textWhite,
                            ),
                          ),
                          Text(
                            'Assistant en 3 étapes',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textCyan200,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Candidatures',
                      onPressed: () => context.push('/candidatures'),
                      icon: const Icon(LucideIcons.clipboardList, color: AppColors.cyan400),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: _stepHeader(),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: KeyedSubtree(
                              key: ValueKey<int>(_step),
                              child: _step == 0
                                  ? _buildStep0()
                                  : _step == 1
                                      ? _buildStep1()
                                      : _buildStep2(),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark.withValues(alpha: 0.92),
                          border: Border(
                            top: BorderSide(
                              color: AppColors.textCyan200.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        child: SafeArea(
                          top: false,
                          child: Row(
                            children: [
                              if (_step > 0)
                                OutlinedButton.icon(
                                  onPressed: _isLoading ? null : _goBack,
                                  icon: const Icon(LucideIcons.arrowLeft, size: 18),
                                  label: const Text('Retour'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.cyan400,
                                    side: const BorderSide(color: AppColors.cyan400),
                                  ),
                                ),
                              if (_step > 0) const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _step < _stepCount - 1
                                          ? _goNext
                                          : _submit,
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
                                      : Text(
                                          _step < _stepCount - 1
                                              ? 'Continuer'
                                              : 'Créer le poste',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
}

class _DescriptionTemplate {
  const _DescriptionTemplate({required this.label, required this.body});
  final String label;
  final String body;
}

/// Aperçu visuel type fil LinkedIn (données locales uniquement).
class _LinkedInStylePreview extends StatelessWidget {
  const _LinkedInStylePreview({
    required this.title,
    required this.company,
    required this.department,
    required this.description,
  });

  final String title;
  final String company;
  final String department;
  final String description;

  @override
  Widget build(BuildContext context) {
    final headline = title.isEmpty ? 'Intitulé de l’offre' : title;
    final sub = [
      if (company.isNotEmpty) company,
      if (department.isNotEmpty) department,
    ].join(' · ');
    final body = description.trim().isEmpty
        ? 'Votre description apparaîtra ici. Utilisez les blocs suggérés pour structurer l’annonce.'
        : description.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aperçu (lecture seule)',
          style: TextStyle(
            color: AppColors.textCyan200.withValues(alpha: 0.55),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a1a).withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF0a66c2).withValues(alpha: 0.35),
                    child: const Icon(LucideIcons.building2, color: Color(0xFF93c5fd), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company.isEmpty ? 'Votre entreprise' : company,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Offre d’emploi · Aperçu',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(LucideIcons.linkedin, color: const Color(0xFF0a66c2), size: 22),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                headline,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  height: 1.25,
                ),
              ),
              if (sub.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  sub,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                body,
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
