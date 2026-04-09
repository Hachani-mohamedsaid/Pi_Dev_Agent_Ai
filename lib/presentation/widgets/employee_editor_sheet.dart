import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';

/// Données saisies (création ou mise à jour collaborateur).
class EmployeeDraft {
  EmployeeDraft({
    this.id,
    required this.fullName,
    required this.email,
    required this.profile,
    required this.skills,
    required this.tags,
  });

  /// `null` = création ; sinon identifiant Mongo.
  final String? id;
  final String fullName;
  final String email;
  final String profile;
  final List<String> skills;
  final List<String> tags;
}

List<String> _splitSkills(String raw) {
  return raw
      .split(RegExp(r'[,;\n]+'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

/// Bottom sheet formulaire collaborateur (thème aligné sur l’app).
Future<EmployeeDraft?> showEmployeeEditorSheet(
  BuildContext context, {
  Map<String, dynamic>? initial,
}) {
  return showModalBottomSheet<EmployeeDraft>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _EmployeeEditorBody(initial: initial),
  );
}

class _EmployeeEditorBody extends StatefulWidget {
  const _EmployeeEditorBody({this.initial});

  final Map<String, dynamic>? initial;

  @override
  State<_EmployeeEditorBody> createState() => _EmployeeEditorBodyState();
}

class _EmployeeEditorBodyState extends State<_EmployeeEditorBody> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _profileCtrl;
  late final TextEditingController _skillsCtrl;
  late final TextEditingController _tagsCtrl;

  String? get _id {
    final m = widget.initial;
    if (m == null) return null;
    final v = m['id']?.toString() ?? m['_id']?.toString();
    return v?.isEmpty ?? true ? null : v;
  }

  @override
  void initState() {
    super.initState();
    final m = widget.initial;
    _nameCtrl = TextEditingController(
      text: m?['fullName']?.toString() ?? m?['full_name']?.toString() ?? '',
    );
    _emailCtrl = TextEditingController(text: m?['email']?.toString() ?? '');
    _profileCtrl = TextEditingController(text: m?['profile']?.toString() ?? '');
    _skillsCtrl = TextEditingController(
      text: _joinList(m?['skills']),
    );
    _tagsCtrl = TextEditingController(
      text: _joinList(m?['tags']),
    );
  }

  static String _joinList(dynamic v) {
    if (v is! List) return '';
    return v.map((e) => e.toString()).where((s) => s.isNotEmpty).join(', ');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _profileCtrl.dispose();
    _skillsCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
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

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      EmployeeDraft(
        id: _id,
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        profile: _profileCtrl.text.trim(),
        skills: _splitSkills(_skillsCtrl.text),
        tags: _splitSkills(_tagsCtrl.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final isEdit = _id != null;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF0f2940),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: Color(0x3322D3EE)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textCyan200.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
              child: Row(
                children: [
                  Icon(
                    isEdit ? LucideIcons.userCog : LucideIcons.userPlus,
                    color: AppColors.cyan400,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isEdit ? 'Modifier le collaborateur' : 'Nouveau collaborateur',
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      LucideIcons.x,
                      color: AppColors.textCyan200.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        style: const TextStyle(color: AppColors.textWhite),
                        decoration: _dec('Nom complet'),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Champ requis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emailCtrl,
                        style: const TextStyle(color: AppColors.textWhite),
                        decoration: _dec('E-mail'),
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Champ requis';
                          }
                          if (!v.contains('@')) {
                            return 'E-mail invalide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _profileCtrl,
                        style: const TextStyle(color: AppColors.textWhite),
                        decoration: _dec(
                          'Rôle / profil',
                          hint: 'ex. Développeur full stack',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Champ requis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _skillsCtrl,
                        style: const TextStyle(color: AppColors.textWhite),
                        maxLines: 2,
                        decoration: _dec(
                          'Compétences',
                          hint: 'Séparées par des virgules (ex. Flutter, NestJS)',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _tagsCtrl,
                        style: const TextStyle(color: AppColors.textWhite),
                        maxLines: 2,
                        decoration: _dec(
                          'Étiquettes (optionnel)',
                          hint: 'Mots-clés séparés par des virgules',
                        ),
                      ),
                      const SizedBox(height: 28),
                      FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.cyan400.withValues(alpha: 0.92),
                          foregroundColor: const Color(0xFF0a1628),
                        ),
                        child: Text(
                          isEdit ? 'Enregistrer les modifications' : 'Ajouter le collaborateur',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
