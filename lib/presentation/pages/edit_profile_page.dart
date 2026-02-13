import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/config/imgbb_config.dart';
import '../../core/config/open_weather_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/utils/responsive.dart';
import '../../data/services/imgbb_upload_service.dart';
import '../../data/services/open_weather_service.dart';
import '../state/auth_controller.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class EditProfilePage extends StatefulWidget {
  final AuthController controller;

  const EditProfilePage({
    super.key,
    required this.controller,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  late TextEditingController _birthDateController;
  late TextEditingController _bioController;
  bool _initialized = false;
  bool _uploadingPhoto = false;
  /// Image choisie localement (affichée même sans clé ImgBB).
  Uint8List? _pickedImageBytes;
  /// Météo pour la localisation (OpenWeather).
  String? _locationWeather;
  bool _weatherLoading = false;
  Timer? _weatherDebounceTimer;
  /// Suggestions de villes (Geocoding OpenWeather) quand l'utilisateur tape.
  List<CitySuggestion> _citySuggestions = [];
  bool _suggestionsLoading = false;
  Timer? _suggestionsDebounceTimer;
  /// Dernière recherche sans résultat (pour afficher "Aucune ville trouvée").
  String? _lastLocationQueryEmpty;
  /// Après sélection d'une ville, on ignore la prochaine recherche pour ne pas réafficher la liste.
  bool _skipNextSuggestionsFetch = false;

  Future<void> _fetchLocationSuggestions(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _suggestionsLoading = true;
      _lastLocationQueryEmpty = null;
    });
    final list = await OpenWeatherService.getCitySuggestions(text);
    if (!mounted) return;
    final singleMatch = list.length == 1 && list.first.displayName == text.trim();
    setState(() {
      _suggestionsLoading = false;
      _citySuggestions = singleMatch ? [] : list;
      _lastLocationQueryEmpty = list.isEmpty ? text : null;
    });
  }

  void _onLocationTextChanged() {
    _suggestionsDebounceTimer?.cancel();
    _suggestionsDebounceTimer = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      if (_skipNextSuggestionsFetch) {
        setState(() => _skipNextSuggestionsFetch = false);
        return;
      }
      final text = _locationController.text.trim();
      if (text.isEmpty) {
        setState(() {
          _citySuggestions = [];
          _locationWeather = null;
          _lastLocationQueryEmpty = null;
        });
        return;
      }
      _fetchLocationSuggestions(text);
    });
  }

  void _selectCitySuggestion(CitySuggestion suggestion) {
    _suggestionsDebounceTimer?.cancel();
    _skipNextSuggestionsFetch = true;
    final displayName = suggestion.displayName;
    _locationController.text = displayName;
    _locationController.selection = TextSelection.collapsed(offset: displayName.length);
    setState(() => _citySuggestions = []);
    _fetchWeatherForLocation(suggestion.name);
  }

  Future<void> _fetchWeatherForLocation(String city) async {
    if (city.trim().isEmpty || openWeatherApiKey.isEmpty) return;
    if (!mounted) return;
    setState(() => _weatherLoading = true);
    final summary = await OpenWeatherService.getWeatherSummaryForCity(city);
    if (!mounted) return;
    setState(() {
      _weatherLoading = false;
      _locationWeather = summary;
    });
  }

  Future<void> _handleChangePhoto() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 85);
    if (xFile == null || !mounted) return;

    if (imgbbApiKey.isEmpty) {
      final bytes = await xFile.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pickedImageBytes = bytes;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ajoute la clé ImgBB dans lib/core/config/imgbb_config.dart pour enregistrer la photo.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _uploadingPhoto = true);
    try {
      final bytes = await xFile.readAsBytes();
      final url = await ImgBBUploadService.uploadImage(bytes);
      if (url == null || !mounted) {
        setState(() => _uploadingPhoto = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.tr(context, 'uploadFailed')), backgroundColor: Colors.red),
          );
        }
        return;
      }
      final success = await widget.controller.updateProfile(avatarUrl: url);
      if (!mounted) return;
      setState(() {
        _uploadingPhoto = false;
        _pickedImageBytes = null;
      });
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.tr(context, 'photoUpdated')), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.controller.error ?? 'Failed to save photo'), backgroundColor: Colors.red),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _uploadingPhoto = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.tr(context, 'uploadFailed')), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _locationController = TextEditingController();
    _birthDateController = TextEditingController();
    _bioController = TextEditingController();
    _locationController.addListener(_onLocationTextChanged);
    _fillFromProfile();
  }

  Future<void> _fillFromProfile() async {
    // Chaque route crée une nouvelle instance d'AuthController : charger user (cache)
    // et profil (GET /auth/me ou fallback) pour pré-remplir les champs.
    await widget.controller.loadCurrentUser();
    if (!mounted) return;
    await widget.controller.loadProfile();
    if (!mounted) return;
    final p = widget.controller.currentProfile;
    final u = widget.controller.currentUser;
    _nameController.text = p?.name ?? u?.name ?? '';
    _emailController.text = p?.email ?? u?.email ?? '';
    _phoneController.text = p?.phone ?? '';
    _locationController.text = p?.location ?? '';
    _birthDateController.text = p?.birthDate ?? '';
    _bioController.text = p?.bio ?? p?.role ?? '';
    setState(() => _initialized = true);
    _fetchWeatherForLocation(_locationController.text);
  }

  @override
  void dispose() {
    _weatherDebounceTimer?.cancel();
    _suggestionsDebounceTimer?.cancel();
    _locationController.removeListener(_onLocationTextChanged);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _birthDateController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await widget.controller.updateProfile(
      name: _nameController.text.trim(),
      role: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      birthDate: _birthDateController.text.trim().isEmpty ? null : _birthDateController.text.trim(),
      bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
    );
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.tr(context, 'profileUpdated')),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.controller.error ?? 'Erreur lors de la mise à jour'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? 24.0 : 32.0;
    final profile = widget.controller.currentProfile;
    final user = widget.controller.currentUser;
    final name = profile?.name ?? user?.name ?? '';
    final initials = name
        .split(' ')
        .map((n) => n.isNotEmpty ? n[0].toUpperCase() : '')
        .take(2)
        .join();
    final displayInitials = initials.isEmpty ? '?' : initials;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: padding,
              right: padding,
              top: padding,
              bottom: padding + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        padding: EdgeInsets.all(isMobile ? 8 : 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primaryLight.withOpacity(0.6),
                              AppColors.primaryDarker.withOpacity(0.6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                          border: Border.all(
                            color: AppColors.cyan500.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Icon(
                              Icons.arrow_back,
                              color: AppColors.cyan400,
                              size: isMobile ? 20 : 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      AppStrings.tr(context, 'editProfile'),
                      style: TextStyle(
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textWhite,
                      ),
                    ),
                    SizedBox(width: isMobile ? 40 : 48),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: -0.2, end: 0, duration: 300.ms),
                SizedBox(height: isMobile ? 24 : 32),

                // Avatar Section (Tap to change photo → image_picker → ImgBB → PATCH /auth/me avatarUrl)
                // Un seul GestureDetector sur toute la zone pour que le clic sur l’avatar OU l’icône caméra ouvre la galerie.
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _uploadingPhoto ? null : _handleChangePhoto,
                        behavior: HitTestBehavior.opaque,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: isMobile ? 96 : 112,
                              height: isMobile ? 96 : 112,
                              decoration: BoxDecoration(
                                gradient: AppColors.logoGradient,
                                borderRadius: BorderRadius.circular(isMobile ? 24 : 28),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _uploadingPhoto
                                  ? const Center(
                                      child: SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      ),
                                    )
                                  : _pickedImageBytes != null
                                      ? Image.memory(
                                          _pickedImageBytes!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        )
                                      : (widget.controller.currentProfile?.avatarUrl ?? '').isEmpty
                                          ? Center(
                                              child: Text(
                                                displayInitials,
                                                style: TextStyle(
                                                  color: AppColors.textWhite,
                                                  fontSize: isMobile ? 36 : 42,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            )
                                          : Image.network(
                                              widget.controller.currentProfile!.avatarUrl!,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                              loadingBuilder: (_, child, progress) =>
                                                  progress == null ? child : Center(child: CircularProgressIndicator(value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null)),
                                              errorBuilder: (_, __, ___) => Center(child: Text(displayInitials, style: TextStyle(color: AppColors.textWhite, fontSize: isMobile ? 36 : 42, fontWeight: FontWeight.bold))),
                                            ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: EdgeInsets.all(isMobile ? 8 : 10),
                                decoration: BoxDecoration(
                                  gradient: AppColors.buttonGradient,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primaryDark,
                                    width: 4,
                                  ),
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: AppColors.textWhite,
                                  size: isMobile ? 16 : 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isMobile ? 12 : 16),
                      Text(
                        'Tap to change photo',
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          color: AppColors.textCyan200.withOpacity(0.7),
                        ),
                      ),
                      if (imgbbApiKey.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Clé ImgBB non configurée : ajoute-la dans lib/core/config/imgbb_config.dart',
                            style: TextStyle(
                              fontSize: isMobile ? 11 : 12,
                              color: AppColors.textCyan200.withOpacity(0.5),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 300.ms)
                    .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), duration: 300.ms),
                SizedBox(height: isMobile ? 24 : 32),

                // Form Fields (pré-remplis depuis GET /auth/me, sauvegarde PATCH /auth/me)
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomTextField(
                        label: AppStrings.tr(context, 'fullName'),
                        hint: 'Enter your name',
                        icon: Icons.person_outline,
                        controller: _nameController,
                      )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 300.ms)
                          .slideY(begin: 0.2, end: 0, duration: 300.ms),
                      SizedBox(height: isMobile ? 20 : 24),
                      CustomTextField(
                        label: AppStrings.tr(context, 'emailAddress'),
                        hint: 'Enter your email',
                        icon: Icons.mail_outline,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        readOnly: true,
                      )
                          .animate()
                          .fadeIn(delay: 250.ms, duration: 300.ms)
                          .slideY(begin: 0.2, end: 0, duration: 300.ms),
                      SizedBox(height: isMobile ? 20 : 24),
                      CustomTextField(
                        label: AppStrings.tr(context, 'phoneNumber'),
                        hint: 'Enter your phone',
                        icon: Icons.phone_outlined,
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                      )
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 300.ms)
                          .slideY(begin: 0.2, end: 0, duration: 300.ms),
                      SizedBox(height: isMobile ? 20 : 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomTextField(
                            label: AppStrings.tr(context, 'location'),
                            hint: 'Type to search cities…',
                            icon: Icons.location_on_outlined,
                            controller: _locationController,
                          ),
                          if (openWeatherApiKey.isNotEmpty) ...[
                            if (_suggestionsLoading || _citySuggestions.isNotEmpty || (_lastLocationQueryEmpty != null && _lastLocationQueryEmpty!.length >= 2)) ...[
                              SizedBox(height: isMobile ? 6 : 8),
                              Container(
                                constraints: BoxConstraints(maxHeight: isMobile ? 180 : 220),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryDark.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                                  border: Border.all(
                                    color: AppColors.cyan500.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: _suggestionsLoading
                                    ? Padding(
                                        padding: EdgeInsets.all(isMobile ? 16 : 20),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                color: AppColors.cyan400,
                                                strokeWidth: 2,
                                              ),
                                            ),
                                            SizedBox(width: isMobile ? 10 : 12),
                                            Text(
                                              'Searching cities…',
                                              style: TextStyle(
                                                fontSize: isMobile ? 13 : 14,
                                                color: AppColors.textCyan200.withOpacity(0.9),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : _citySuggestions.isEmpty
                                        ? Padding(
                                            padding: EdgeInsets.all(isMobile ? 16 : 20),
                                            child: Text(
                                              _lastLocationQueryEmpty != null
                                                  ? 'No cities found for "$_lastLocationQueryEmpty"'
                                                  : 'Searching cities…',
                                              style: TextStyle(
                                                fontSize: isMobile ? 13 : 14,
                                                color: AppColors.textCyan200.withOpacity(0.8),
                                              ),
                                            ),
                                          )
                                        : ListView.builder(
                                            shrinkWrap: true,
                                            padding: EdgeInsets.symmetric(vertical: isMobile ? 6 : 8),
                                            itemCount: _citySuggestions.length,
                                            itemBuilder: (context, index) {
                                          final s = _citySuggestions[index];
                                          return Material(
                                            color: Colors.transparent,
                                            child: GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTap: () => _selectCitySuggestion(s),
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: isMobile ? 14 : 18,
                                                  vertical: isMobile ? 10 : 12,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.location_on_outlined,
                                                      size: isMobile ? 18 : 20,
                                                      color: AppColors.cyan400.withOpacity(0.9),
                                                    ),
                                                    SizedBox(width: isMobile ? 10 : 12),
                                                    Expanded(
                                                      child: Text(
                                                        s.displayName,
                                                        style: TextStyle(
                                                          fontSize: isMobile ? 14 : 15,
                                                          color: AppColors.textWhite,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                            ),
                              ),
                              SizedBox(height: isMobile ? 8 : 10),
                            ],
                            if (_weatherLoading)
                              Row(
                                children: [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      color: AppColors.cyan400,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: isMobile ? 8 : 10),
                                  Text(
                                    'Météo…',
                                    style: TextStyle(
                                      fontSize: isMobile ? 12 : 13,
                                      color: AppColors.textCyan200.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              )
                            else if (_locationWeather != null)
                              Row(
                                children: [
                                  Icon(
                                    Icons.cloud_outlined,
                                    size: isMobile ? 16 : 18,
                                    color: AppColors.cyan400,
                                  ),
                                  SizedBox(width: isMobile ? 8 : 10),
                                  Text(
                                    'Météo: $_locationWeather',
                                    style: TextStyle(
                                      fontSize: isMobile ? 12 : 13,
                                      color: AppColors.textCyan200.withOpacity(0.9),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _fetchWeatherForLocation(_locationController.text),
                                    child: Icon(
                                      Icons.refresh,
                                      size: isMobile ? 14 : 16,
                                      color: AppColors.cyan400.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ],
                      )
                          .animate()
                          .fadeIn(delay: 350.ms, duration: 300.ms)
                          .slideY(begin: 0.2, end: 0, duration: 300.ms),
                      SizedBox(height: isMobile ? 20 : 24),
                      GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (date != null && mounted) {
                            _birthDateController.text =
                                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                          }
                        },
                        child: CustomTextField(
                          label: AppStrings.tr(context, 'birthDate'),
                          hint: AppStrings.tr(context, 'selectDate'),
                          icon: Icons.calendar_today_outlined,
                          controller: _birthDateController,
                          readOnly: true,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 300.ms)
                          .slideY(begin: 0.2, end: 0, duration: 300.ms),
                      SizedBox(height: isMobile ? 20 : 24),
                      // Bio / Rôle
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              left: isMobile ? 4 : 8,
                              bottom: isMobile ? 6 : 8,
                            ),
                            child: Text(
                              'Bio / Rôle',
                              style: TextStyle(
                                color: AppColors.textCyan200,
                                fontSize: isMobile ? 14 : 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primaryLight.withOpacity(0.6),
                                  AppColors.primaryDarker.withOpacity(0.6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                              border: Border.all(
                                color: AppColors.cyan500.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: TextField(
                                  controller: _bioController,
                                  maxLines: 3,
                                  style: TextStyle(
                                    color: AppColors.textWhite,
                                    fontSize: isMobile ? 15 : 16,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Ex. AI Enthusiast',
                                    hintStyle: TextStyle(
                                      color: AppColors.textCyan200.withOpacity(0.3),
                                      fontSize: isMobile ? 15 : 16,
                                    ),
                                    contentPadding: EdgeInsets.all(isMobile ? 16 : 20),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                          .animate()
                          .fadeIn(delay: 450.ms, duration: 300.ms)
                          .slideY(begin: 0.2, end: 0, duration: 300.ms),
                    ],
                  ),
                ),
                SizedBox(height: isMobile ? 32 : 40),

                // Save Button
                CustomButton(
                  text: 'Save Changes',
                  onPressed: _initialized ? _handleSave : () {},
                  isLoading: widget.controller.isLoading,
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 300.ms)
                    .slideY(begin: 0.2, end: 0, duration: 300.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
