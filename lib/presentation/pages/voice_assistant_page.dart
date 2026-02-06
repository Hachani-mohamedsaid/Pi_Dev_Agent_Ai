import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:openai_tts/openai_tts.dart';

import '../../core/config/api_config.dart'
    show openaiApiKey, chatSystemInstructionMultilingual, realtimeVoiceWsUrl;
import '../../core/utils/responsive.dart';
import '../../data/datasources/chat_remote_data_source.dart';
import '../../data/datasources/realtime_voice_client.dart';

class VoiceAssistantPage extends StatefulWidget {
  VoiceAssistantPage({super.key, ChatRemoteDataSource? chatDataSource})
    : chatDataSource = chatDataSource ?? ApiChatRemoteDataSource();

  final ChatRemoteDataSource chatDataSource;

  @override
  State<VoiceAssistantPage> createState() => _VoiceAssistantPageState();
}

class _VoiceAssistantPageState extends State<VoiceAssistantPage>
    with TickerProviderStateMixin {
  // --- State Variables ---
  bool isListening = false;
  bool isSpeaking = false;
  bool showChat = false;
  bool isLoadingAI = false;
  String inputText = "";
  String currentTranscript = "";
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _speechAvailable = false;
  OpenaiTTS? _openaiTts;
  StreamSubscription<OpenaiTTSStatus>? _openaiTtsStatusSub;
  RealtimeVoiceClient? _realtimeClient;
  StreamSubscription<List<int>>? _realtimeAudioSub;

  List<ChatMessage> messages = [
    ChatMessage(
      id: 1,
      text: "Bonjour ! Comment puis-je vous aider aujourd'hui ?",
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
    ),
  ];

  // --- Animation Controllers ---
  late AnimationController _waveformController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    try {
      // Continuous rotation for waveform
      _waveformController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 15),
      )..repeat();

      // Pulse for active state
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
      );

      // Initialize speech and TTS with error handling
      _initSpeech().catchError((error) {
        debugPrint('Error initializing speech: $error');
      });
      _initTts().catchError((error) {
        debugPrint('Error initializing TTS: $error');
      });
      
      if (openaiApiKey.isNotEmpty) {
        try {
          _openaiTts = OpenaiTTS(apiKey: openaiApiKey);
          _openaiTtsStatusSub = _openaiTts!.ttsStatusStream.listen((status) {
            if (!mounted) return;
            setState(() {
              isSpeaking = status == OpenaiTTSStatus.fetching ||
                  status == OpenaiTTSStatus.playing;
            });
            if (status == OpenaiTTSStatus.completed || status == OpenaiTTSStatus.stopped) {
              _waveformController.duration = const Duration(seconds: 15);
              _waveformController.repeat();
              _pulseController.stop();
              _pulseController.reset();
            }
          }, onError: (error) {
            debugPrint('OpenAI TTS stream error: $error');
          });
        } catch (e) {
          debugPrint('Error initializing OpenAI TTS: $e');
        }
      }
      
      if (realtimeVoiceWsUrl.isNotEmpty) {
        try {
          _realtimeClient = RealtimeVoiceClientImpl(wsUrl: realtimeVoiceWsUrl);
          _realtimeClient!.connect().then((_) {
            _realtimeAudioSub = _realtimeClient!.audioDeltaStream.listen((bytes) {
              if (!mounted) return;
              setState(() => isSpeaking = true);
              // TODO: jouer bytes PCM avec flutter_sound (startPlayerFromStream)
              // Pour l'instant le client Realtime est prêt ; brancher record PCM → sendAudioChunk + play ici.
            }, onError: (error) {
              debugPrint('Realtime audio stream error: $error');
            });
          }).catchError((error) {
            debugPrint('Error connecting to realtime voice client: $error');
          });
        } catch (e) {
          debugPrint('Error initializing realtime voice client: $e');
        }
      }
    } catch (e) {
      debugPrint('Error in VoiceAssistantPage initState: $e');
    }
  }

  /// Initialise le TTS : débit lent et volume max pour un son clair (FR, EN, AR).
  Future<void> _initTts() async {
    try {
      await _flutterTts.setSpeechRate(0.48); // Vitesse équilibrée (voix type ChatGPT)
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS error: $msg');
      });
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
    }
  }

  /// Appels TTS sécurisés (évite DeadObjectException / "not bound to TTS engine" sur Android).
  Future<void> _ttsSafeStop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
  }

  Future<bool> _ttsSafeSetLanguage(String locale) async {
    try {
      if (kDebugMode) print('TTS: Attempting to set language: $locale');

      final ok = await _flutterTts.isLanguageAvailable(locale);
      if (ok == true) {
        await _flutterTts.setLanguage(locale);
        if (kDebugMode) print('TTS: Language set successfully: $locale');
        return true;
      }

      if (kDebugMode)
        print('TTS: Language $locale not available, trying alternatives...');

      // Pour l'arabe, essaye d'autres variantes si ar-SA n'est pas dispo
      if (locale == 'ar-SA') {
        final variants = ['ar', 'ar_SA', 'ar-AE', 'ar_AE', 'ar-EG', 'ar_EG'];
        for (final variant in variants) {
          final available = await _flutterTts.isLanguageAvailable(variant);
          if (available == true) {
            if (kDebugMode)
              print('TTS: Using alternative Arabic locale: $variant');
            await _flutterTts.setLanguage(variant);
            return true;
          }
        }
      }

      // Pour le francais, essaye d'autres variantes
      if (locale == 'fr-FR') {
        final variants = ['fr', 'fr-CA', 'fr_CA', 'fr-BE', 'fr_BE'];
        for (final variant in variants) {
          final available = await _flutterTts.isLanguageAvailable(variant);
          if (available == true) {
            if (kDebugMode)
              print('TTS: Using alternative French locale: $variant');
            await _flutterTts.setLanguage(variant);
            return true;
          }
        }
      }

      if (kDebugMode)
        print(
          'TTS: No suitable language found, using default: $_defaultTtsLocale',
        );
      // Fallback a la langue par defaut
      await _flutterTts.setLanguage(_defaultTtsLocale);
      return false;
    } catch (e) {
      if (kDebugMode) print('TTS: Error setting language: $e');
      return false;
    }
  }

  Future<void> _ttsSafeSpeak(String text) async {
    try {
      // Detecte la langue pour ajuster le debit
      final detectectedLang = _detectLanguage(text);

      // Arabe: debit moyen (0.42) pour une bonne comprehension et fluidite
      // Francais/Anglais: debit normal (0.48)
      final speechRate = detectectedLang == 'ar-SA' ? 0.42 : 0.48;

      if (kDebugMode)
        print(
          'TTS: Setting speech rate: $speechRate for language: $detectectedLang',
        );

      // Configuration TTS optimisee
      await _flutterTts.setSpeechRate(speechRate);
      await _flutterTts.setVolume(1.0); // Volume max
      await _flutterTts.setPitch(1.0); // Pitch normal

      // Ajoute un delai minimal pour s'assurer que la langue est bien configuree
      await Future.delayed(const Duration(milliseconds: 100));

      await _flutterTts.speak(text);
    } catch (_) {
      if (mounted) {
        setState(() => isSpeaking = false);
        _waveformController.duration = const Duration(seconds: 15);
        _waveformController.repeat();
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  /// Langue TTS par défaut quand on ne détecte pas (anglais = langue neutre courante).
  static const String _defaultTtsLocale = 'en-US';
  static const String _defaultSttLocale = 'en_US';

  /// Detecte la langue du texte pour choisir la voix TTS (ar, fr, en, etc.).
  /// Arabe → ar-SA, Francais (accents) → fr-FR, sinon → en-US (multilingue).
  String _detectLanguage(String text) {
    if (text.isEmpty) return _defaultTtsLocale;
    final trimmed = text.trim();
    // Detection arabe amelioree : caracteres arabes (Basic + Extended + Supplement)
    final arabicRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');
    if (arabicRegex.hasMatch(trimmed)) {
      if (kDebugMode) print('Language detection: ARABIC detected');
      return 'ar-SA';
    }
    // Detection francais : accents francais courants
    if (RegExp(r'[àâäéèêëïîôùûüçœæ]', caseSensitive: false).hasMatch(trimmed)) {
      if (kDebugMode) print('Language detection: FRENCH detected');
      return 'fr-FR';
    }
    if (kDebugMode) print('Language detection: DEFAULT (en-US)');
    return _defaultTtsLocale;
  }

  /// Detecte la langue STT pour configurer le localeId (ar_SA, fr_FR, en_US, etc.).
  String _detectSttLocale(String text) {
    if (text.isEmpty) return _defaultSttLocale;
    final trimmed = text.trim();
    // Detection arabe pour STT (includes extended Arabic)
    final arabicRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');
    if (arabicRegex.hasMatch(trimmed)) {
      if (kDebugMode) print('STT Language detection: ARABIC detected');
      return 'ar_SA';
    }
    // Detection francais pour STT
    if (RegExp(r'[àâäéèêëïîôùûüçœæ]', caseSensitive: false).hasMatch(trimmed)) {
      if (kDebugMode) print('STT Language detection: FRENCH detected');
      return 'fr_FR';
    }
    if (kDebugMode) print('STT Language detection: DEFAULT (en_US)');
    return _defaultSttLocale;
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (error) {
          debugPrint('Speech recognition error: $error');
        },
        onStatus: (status) {
          debugPrint('Speech recognition status: $status');
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error initializing speech recognition: $e');
      _speechAvailable = false;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _realtimeAudioSub?.cancel();
    _realtimeClient?.close();
    _openaiTtsStatusSub?.cancel();
    _openaiTts?.stopPlayer();
    _openaiTts?.dispose();
    _waveformController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- Logic Functions ---

  /// Parole IA : TTS claire en FR, EN, AR. L’utilisateur entend la réponse.
  Future<void> simulateAISpeaking(String text) async {
    if (text.isEmpty) return;
    setState(() => isSpeaking = true);
    _waveformController.duration = const Duration(seconds: 3);
    _waveformController.repeat();
    _pulseController.repeat(reverse: true);

    // Detecte si le texte est en arabe
    final isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);

    // Force FlutterTts pour l'arabe car OpenAI TTS ne le supporte pas bien
    if (isArabic) {
      _fallbackFlutterTts(text);
      return;
    }

    if (_openaiTts != null) {
      await _openaiTts!.stopPlayer();
      try {
        await _openaiTts!.streamSpeak(
          text,
          voice: OpenaiTTSVoice.alloy,
          model: OpenaiTTSModel.tts1hd, // HD = son plus clair
        );
      } catch (_) {
        if (mounted) _fallbackFlutterTts(text);
      }
      return;
    }

    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() => isSpeaking = false);
        _waveformController.duration = const Duration(seconds: 15);
        _waveformController.repeat();
        _pulseController.stop();
        _pulseController.reset();
      }
    });
    await _ttsSafeStop();
    final locale = _detectLanguage(text);
    if (kDebugMode) print('TTS simulateAISpeaking: Detected locale= $locale');
    await _ttsSafeSetLanguage(locale);
    // Delai pour laisser la langue s'appliquer
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) await _ttsSafeSpeak(text);
  }

  void _fallbackFlutterTts(String text) async {
    if (text.isEmpty) return;
    setState(() => isSpeaking = true);

    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() => isSpeaking = false);
        _waveformController.duration = const Duration(seconds: 15);
        _waveformController.repeat();
        _pulseController.stop();
        _pulseController.reset();
      }
    });

    await _ttsSafeStop();

    // Detecte et configure la langue
    final locale = _detectLanguage(text);
    if (kDebugMode) print('TTS Fallback: Detected locale= $locale');

    // Configure la langue
    final langSet = await _ttsSafeSetLanguage(locale);
    if (kDebugMode) print('TTS Language set: $langSet (locale: $locale)');

    // Attend un peu plus longtemps pour s'assurer que la langue est appliquee
    await Future.delayed(const Duration(milliseconds: 200));

    if (mounted) await _ttsSafeSpeak(text);
  }

  void handleMicToggle() async {
    if (isListening) {
      await _speech.stop();
      setState(() => isListening = false);
      _pulseController.stop();
      _pulseController.reset();
      _waveformController.duration = const Duration(seconds: 15);
      _waveformController.repeat();

      final transcript = currentTranscript.trim();
      final isPlaceholder =
          transcript.isEmpty ||
          transcript == "Go ahead, I'm listening..." ||
          transcript == "Parle, j'écoute...";
      if (!isPlaceholder && transcript.isNotEmpty) {
        _addMessage(transcript, MessageSender.user);
        setState(() => currentTranscript = "");
        _requestAIResponse(transcript);
      }
      setState(() => currentTranscript = "");
    } else {
      if (!_speechAvailable) {
        _speechAvailable = await _speech.initialize();
        if (!_speechAvailable && mounted) {
          setState(() => currentTranscript = "Micro non disponible");
          return;
        }
      }
      setState(() {
        isListening = true;
        currentTranscript = "Parle, j'écoute...";
      });
      _pulseController.repeat(reverse: true);
      _waveformController.duration = const Duration(seconds: 3);
      _waveformController.repeat();

      // Détermine la langue STT en fonction du dernier message (si disponible)
      // ou utilise l'arabe comme langue par défaut si le contexte suggère l'arabe
      String sttLocale = _defaultSttLocale;
      if (messages.isNotEmpty) {
        final lastUserMessage = messages.lastWhere(
          (m) => m.sender == MessageSender.user,
          orElse: () => messages.last,
        );
        sttLocale = _detectSttLocale(lastUserMessage.text);
      }

      await _speech.listen(
        onResult: (result) {
          if (mounted && result.recognizedWords.isNotEmpty) {
            setState(() => currentTranscript = result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId:
            sttLocale, // Configure la langue pour STT (ar_SA, fr_FR, en_US)
      );
    }
  }

  void handleSendMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      _addMessage(text, MessageSender.user);
      _textController.clear();
      _requestAIResponse(text);
    }
  }

  /// Appelle l'API chat (backend) pour une réponse dynamique ; en cas d'erreur, affiche un message de repli.
  Future<void> _requestAIResponse(String _) async {
    if (!mounted) return;
    setState(() => isLoadingAI = true);

    try {
      final apiMessages = messages
          .map(
            (m) => {
              'role': m.sender == MessageSender.user ? 'user' : 'assistant',
              'content': m.text,
            },
          )
          .toList();

      final response = await widget.chatDataSource.sendMessages(
        apiMessages,
        systemInstruction: chatSystemInstructionMultilingual,
      );
      if (!mounted) return;
      setState(() => isLoadingAI = false);
      _addMessage(response, MessageSender.ai);
      simulateAISpeaking(response);
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoadingAI = false);
      const fallback =
          "J'ai bien reçu votre message. Comment puis-je vous aider ?";
      _addMessage(fallback, MessageSender.ai);
      simulateAISpeaking(fallback);
    }
  }

  void _addMessage(String text, MessageSender sender) {
    setState(() {
      messages.add(
        ChatMessage(
          id: messages.length + 1,
          text: text,
          sender: sender,
          timestamp: DateTime.now(),
        ),
      );
    });
    // Scroll to bottom
    if (showChat) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Background Gradient Colors
    const bgStart = Color(0xFF0f2940);
    const bgMid = Color(0xFF1a3a52);
    const bgEnd = Color(0xFF0f2940);

    return Scaffold(
      resizeToAvoidBottomInset: false, // Handle keyboard manually if needed
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgStart, bgMid, bgEnd],
          ),
        ),
        child: Stack(
          children: [
            // Background Glow Effects (Static Blobs) - Behind everything
            Positioned(
              top: MediaQuery.of(context).size.height * 0.33,
              left: MediaQuery.of(context).size.width / 2 - 192,
              child: IgnorePointer(
                child: Container(
                  width: 384,
                  height: 384,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.cyan.withOpacity(0.1),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.25,
              left: MediaQuery.of(context).size.width * 0.25,
              child: IgnorePointer(
                child: Container(
                  width: 256,
                  height: 256,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withOpacity(0.1),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),
            ),

            // --- Main Content ---
            SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenHeight = MediaQuery.of(context).size.height;
                  final screenWidth = MediaQuery.of(context).size.width;

                  // Responsive calculations - Reduced to move waveform up
                  final topSectionHeight = Responsive.getResponsiveValue(
                    context,
                    mobile: screenHeight * 0.22,
                    tablet: screenHeight * 0.20,
                    desktop: screenHeight * 0.18,
                  );

                  // Responsive bottom section height
                  final micButtonHeight = Responsive.getResponsiveValue(
                    context,
                    mobile: 100.0,
                    tablet: 110.0,
                    desktop: 120.0,
                  );
                  final spacingHeight = Responsive.getResponsiveValue(
                    context,
                    mobile: 32.0,
                    tablet: 36.0,
                    desktop: 40.0,
                  );
                  final inputFieldHeight = Responsive.getResponsiveValue(
                    context,
                    mobile: 70.0,
                    tablet: 75.0,
                    desktop: 80.0,
                  );
                  final bottomPadding = Responsive.getResponsiveValue(
                    context,
                    mobile: 24.0,
                    tablet: 28.0,
                    desktop: 32.0,
                  );

                  final bottomSectionHeight =
                      micButtonHeight +
                      spacingHeight +
                      inputFieldHeight +
                      bottomPadding;

                  // Available height for waveform area (with safety margin)
                  final availableHeight =
                      (constraints.maxHeight -
                              topSectionHeight -
                              bottomSectionHeight)
                          .clamp(200.0, double.infinity);

                  return Column(
                    children: [
                      // Spacer to account for top section
                      SizedBox(height: topSectionHeight),

                      // Waveform Area - Centered in available space
                      Expanded(
                        child: Center(
                          child: _WaveformVisualizer(
                            rotateController: _waveformController,
                            pulseController: _pulseController,
                            isActive: isListening || isSpeaking,
                          ),
                        ),
                      ),

                      // Mic Button - Fixed height to prevent layout shift
                      SizedBox(
                        height: micButtonHeight,
                        child: ClipRect(
                          child: Center(
                            child: _MicButton(
                              isListening: isListening,
                              onTap: handleMicToggle,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: spacingHeight),

                      // Bottom Input Field - Fixed height to prevent layout shift
                      Padding(
                        padding: EdgeInsets.only(
                          bottom:
                              bottomPadding +
                              MediaQuery.of(context).padding.bottom,
                          left: Responsive.getResponsiveValue(
                            context,
                            mobile: 20.0,
                            tablet: 24.0,
                            desktop: 28.0,
                          ),
                          right: Responsive.getResponsiveValue(
                            context,
                            mobile: 20.0,
                            tablet: 24.0,
                            desktop: 28.0,
                          ),
                        ),
                        child: _buildInputArea(),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Top Navigation & Controls - On front layer
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: Responsive.getResponsivePadding(
                      context,
                      mobile: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      tablet: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 24,
                      ),
                      desktop: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 28,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back Button
                        GestureDetector(
                          onTap: () => context.go('/home'),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.chevronLeft,
                                color: const Color(0xFF22d3ee),
                                size: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 22.0,
                                  tablet: 24.0,
                                  desktop: 26.0,
                                ),
                              ),
                              SizedBox(
                                width: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 4.0,
                                  tablet: 6.0,
                                  desktop: 8.0,
                                ),
                              ),
                              Text(
                                "Home",
                                style: TextStyle(
                                  color: const Color(0xFF22d3ee),
                                  fontSize: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 14.0,
                                    tablet: 16.0,
                                    desktop: 18.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Top Right Buttons
                        Row(
                          children: [
                            _buildGlassIconButton(
                              icon: LucideIcons.messageSquare,
                              onTap: () => setState(() => showChat = !showChat),
                              badgeCount: messages.length > 1
                                  ? messages.length
                                  : 0,
                            ),
                            SizedBox(
                              width: Responsive.getResponsiveValue(
                                context,
                                mobile: 10.0,
                                tablet: 12.0,
                                desktop: 14.0,
                              ),
                            ),
                            _buildGlassIconButton(
                              icon: LucideIcons.menu,
                              onTap: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Header Text
                  Column(
                    children: [
                      Text(
                        "Talk to buddy",
                        style: TextStyle(
                          color: Colors.cyan[200]!.withOpacity(0.6),
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 12.0,
                            tablet: 14.0,
                            desktop: 16.0,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: Responsive.getResponsiveValue(
                          context,
                          mobile: 12.0,
                          tablet: 16.0,
                          desktop: 20.0,
                        ),
                      ),
                      SizedBox(
                        height: Responsive.getResponsiveValue(
                          context,
                          mobile: 70.0,
                          tablet: 80.0,
                          desktop: 90.0,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Column(
                            key: ValueKey(
                              isListening
                                  ? "list"
                                  : isSpeaking
                                  ? "speak"
                                  : "idle",
                            ),
                            children: [
                              Text(
                                isListening
                                    ? "Parle, j'écoute..."
                                    : isSpeaking
                                    ? "Je réfléchis..."
                                    : "Prêt à vous aider pour",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 18.0,
                                    tablet: 20.0,
                                    desktop: 22.0,
                                  ),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (!isListening && !isSpeaking)
                                Text(
                                  "tout ce dont vous avez besoin aujourd'hui !",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 18.0,
                                      tablet: 20.0,
                                      desktop: 22.0,
                                    ),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- Chat Overlay ---
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              left: 0,
              right: 0,
              bottom: showChat ? 0 : -MediaQuery.of(context).size.height,
              height: MediaQuery.of(context).size.height,
              child: _ChatOverlay(
                messages: messages,
                isLoadingAI: isLoadingAI,
                onClose: () => setState(() => showChat = false),
                scrollController: _scrollController,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1e4a66).withOpacity(0.6),
              const Color(0xFF16384d).withOpacity(0.6),
            ],
          ),
          border: Border.all(color: Colors.cyan.withOpacity(0.2)),
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: const Color(0xFF22d3ee), size: 20),
            if (badgeCount > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.pink, Colors.purple],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "$badgeCount",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(
        Responsive.getResponsiveValue(
          context,
          mobile: 45.0,
          tablet: 50.0,
          desktop: 55.0,
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.getResponsiveValue(
              context,
              mobile: 20.0,
              tablet: 24.0,
              desktop: 28.0,
            ),
            vertical: Responsive.getResponsiveValue(
              context,
              mobile: 10.0,
              tablet: 12.0,
              desktop: 14.0,
            ),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              Responsive.getResponsiveValue(
                context,
                mobile: 45.0,
                tablet: 50.0,
                desktop: 55.0,
              ),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1e4a66).withOpacity(0.6),
                const Color(0xFF16384d).withOpacity(0.6),
              ],
            ),
            border: Border.all(color: Colors.cyan.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.getResponsiveValue(
                      context,
                      mobile: 15.0,
                      tablet: 17.0,
                      desktop: 19.0,
                    ),
                  ),
                  decoration: InputDecoration(
                    hintText: "Enter your prompt here...",
                    hintStyle: TextStyle(
                      color: Colors.cyan[200]!.withOpacity(0.3),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (_) => handleSendMessage(),
                ),
              ),
              GestureDetector(
                onTap: handleSendMessage,
                child: Container(
                  padding: EdgeInsets.all(
                    Responsive.getResponsiveValue(
                      context,
                      mobile: 6.0,
                      tablet: 8.0,
                      desktop: 10.0,
                    ),
                  ),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF06b6d4), Color(0xFF3b82f6)],
                    ),
                  ),
                  child: Icon(
                    LucideIcons.send,
                    color: Colors.white,
                    size: Responsive.getResponsiveValue(
                      context,
                      mobile: 14.0,
                      tablet: 16.0,
                      desktop: 18.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Waveform Visualizer ---
class _WaveformVisualizer extends StatelessWidget {
  final AnimationController rotateController;
  final AnimationController pulseController;
  final bool isActive;

  const _WaveformVisualizer({
    required this.rotateController,
    required this.pulseController,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final waveformSize = Responsive.getResponsiveValue(
      context,
      mobile: 300.0,
      tablet: 340.0,
      desktop: 380.0,
    );

    final layer1Size = waveformSize * 0.85;
    final layer2Size = waveformSize * 0.75;
    final layer3Size = waveformSize * 0.75;

    return SizedBox(
      width: waveformSize,
      height: waveformSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Static Background Glow
          Container(
            width: waveformSize,
            height: waveformSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withOpacity(0.2),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(color: Colors.transparent),
            ),
          ),

          // Layer 1: Cyan/Blue Swirl
          AnimatedBuilder(
            animation: Listenable.merge([rotateController, pulseController]),
            builder: (context, child) {
              return Transform.rotate(
                angle: rotateController.value * 2 * math.pi,
                child: Transform.scale(
                  scale: isActive ? 1.0 + (pulseController.value * 0.1) : 1.0,
                  child: Container(
                    width: layer1Size,
                    height: layer1Size,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          Color(0xFF0891b2),
                          Color(0xFF3b82f6),
                          Colors.transparent,
                          Color(0xFF0891b2),
                        ],
                      ),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ),
              );
            },
          ),

          // Layer 2: Pink/Purple Swirl (Counter Rotation)
          AnimatedBuilder(
            animation: Listenable.merge([rotateController, pulseController]),
            builder: (context, child) {
              return Transform.rotate(
                angle: -rotateController.value * 2 * math.pi,
                child: Transform.scale(
                  scale: isActive ? 0.95 + (pulseController.value * 0.2) : 0.95,
                  child: Container(
                    width: layer2Size,
                    height: layer2Size,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        startAngle: math.pi,
                        colors: [
                          Color(0xFFdb2777),
                          Color(0xFF9333ea),
                          Colors.transparent,
                          Color(0xFFdb2777),
                        ],
                      ),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ),
              );
            },
          ),

          // Layer 3: Inner Liquid Glow
          AnimatedBuilder(
            animation: Listenable.merge([rotateController, pulseController]),
            builder: (context, child) {
              // A slightly distorted rotation to simulate liquid
              return Transform.rotate(
                angle: rotateController.value * math.pi,
                child: Container(
                  width: layer3Size,
                  height: layer3Size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.blue.withOpacity(0.3),
                        Colors.purple.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFA7F3D0).withOpacity(0.1),
                        blurRadius: 60,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// --- Microphone Button ---
class _MicButton extends StatelessWidget {
  final bool isListening;
  final VoidCallback onTap;

  const _MicButton({required this.isListening, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 84,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Outer Glow Ripple (when listening) - Positioned absolutely to not affect layout
            if (isListening)
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.0, end: 1.3),
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Center(
                      child: Container(
                        width: 120 * value,
                        height: 120 * value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.purple.withOpacity(0.4 * (1.3 - value)),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  onEnd: () {},
                ),
              ),

            // Gradient Border Ring
            Container(
              width: 84,
              height: 84,
              padding: const EdgeInsets.all(2), // Border width
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: const [
                    Color(0xFFA855F7),
                    Color(0xFFEC4899),
                    Color(0xFF06B6D4),
                    Color(0xFF10B981),
                    Color(0xFFA855F7),
                  ],
                  stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                  transform: GradientRotation(
                    isListening ? 0 : 0.5,
                  ), // Animate this if you want rotation
                ),
                boxShadow: isListening
                    ? [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ]
                    : [],
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF0f2940),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Inner Button
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isListening
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF9333ea),
                          Color(0xFFdb2777),
                          Color(0xFF0891b2),
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF1a3a52),
                          const Color(0xFF0f2940),
                        ],
                      ),
                border: isListening
                    ? null
                    : Border.all(color: Colors.cyan.withOpacity(0.3)),
              ),
              child: Icon(
                isListening ? LucideIcons.micOff : LucideIcons.mic,
                color: isListening ? Colors.white : const Color(0xFF67e8f9),
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Chat Overlay ---
class _ChatOverlay extends StatelessWidget {
  final List<ChatMessage> messages;
  final bool isLoadingAI;
  final VoidCallback onClose;
  final ScrollController scrollController;

  const _ChatOverlay({
    required this.messages,
    required this.isLoadingAI,
    required this.onClose,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Conversation",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: onClose,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1e4a66).withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.cyan.withOpacity(0.2)),
                      ),
                      child: const Icon(
                        LucideIcons.x,
                        color: Color(0xFF22d3ee),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Messages List
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                itemCount: messages.length + (isLoadingAI ? 1 : 0),
                itemBuilder: (context, index) {
                  if (isLoadingAI && index == messages.length) {
                    return const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Text(
                                "Buddy is typing...",
                                style: TextStyle(
                                  color: Color(0xFF94a3b8),
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final msg = messages[index];
                  final isUser = msg.sender == MessageSender.user;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: isUser
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: isUser
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF06b6d4),
                                        Color(0xFF3b82f6),
                                      ],
                                    )
                                  : LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        const Color(
                                          0xFF1e4a66,
                                        ).withOpacity(0.6),
                                        const Color(
                                          0xFF16384d,
                                        ).withOpacity(0.6),
                                      ],
                                    ),
                              border: isUser
                                  ? null
                                  : Border.all(
                                      color: Colors.cyan.withOpacity(0.2),
                                    ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg.text,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}",
                                  style: TextStyle(
                                    color: isUser
                                        ? Colors.white.withOpacity(0.7)
                                        : Colors.cyan[200]!.withOpacity(0.5),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Data Models ---
enum MessageSender { user, ai }

class ChatMessage {
  final int id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
  });
}
