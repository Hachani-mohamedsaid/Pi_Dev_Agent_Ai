import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../state/auth_controller.dart';

class VoiceAssistantPage extends StatefulWidget {
  final AuthController controller;

  const VoiceAssistantPage({
    super.key,
    required this.controller,
  });

  @override
  State<VoiceAssistantPage> createState() => _VoiceAssistantPageState();
}

class _VoiceAssistantPageState extends State<VoiceAssistantPage>
    with TickerProviderStateMixin {
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _showChat = false;
  final TextEditingController _inputController = TextEditingController();
  final List<Message> _messages = [
    Message(
      id: 1,
      text: "Hello! How can I assist you today?",
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
    ),
  ];
  String _currentTranscript = "";
  late AnimationController _waveformController;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveformController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _simulateAISpeaking(String text) {
    setState(() {
      _isSpeaking = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
    });
  }

  void _handleMicToggle() {
    if (_isListening) {
      setState(() {
        _isListening = false;
      });
      if (_currentTranscript.isNotEmpty && _currentTranscript != "Go ahead, I'm listening...") {
        final userMessage = Message(
          id: _messages.length + 1,
          text: _currentTranscript,
          sender: MessageSender.user,
          timestamp: DateTime.now(),
        );
        setState(() {
          _messages.add(userMessage);
        });

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            final aiResponse = Message(
              id: _messages.length + 1,
              text: "I understand. Let me help you with that.",
              sender: MessageSender.ai,
              timestamp: DateTime.now(),
            );
            setState(() {
              _messages.add(aiResponse);
            });
            _simulateAISpeaking(aiResponse.text);
          }
        });

        setState(() {
          _currentTranscript = "";
        });
      }
    } else {
      setState(() {
        _isListening = true;
        _currentTranscript = "Go ahead, I'm listening...";
      });
    }
  }

  void _handleSendMessage() {
    if (_inputController.text.trim().isNotEmpty) {
      final userMessage = Message(
        id: _messages.length + 1,
        text: _inputController.text.trim(),
        sender: MessageSender.user,
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.add(userMessage);
        _inputController.clear();
      });

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          final aiResponse = Message(
            id: _messages.length + 1,
            text: "I've received your message. How else can I assist you?",
            sender: MessageSender.ai,
            timestamp: DateTime.now(),
          );
          setState(() {
            _messages.add(aiResponse);
          });
          _simulateAISpeaking(aiResponse.text);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final screenHeight = Responsive.screenHeight(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Stack(
          children: [
            // Background Glow Effects
            Positioned(
              top: screenHeight * 0.33,
              left: MediaQuery.of(context).size.width * 0.5,
              child: Transform.translate(
                offset: const Offset(-192, -192),
                child: Container(
                  width: 384,
                  height: 384,
                  decoration: BoxDecoration(
                    color: AppColors.cyan500.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(192),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                      child: Container(),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: screenHeight * 0.25,
              left: MediaQuery.of(context).size.width * 0.25,
              child: Container(
                width: 256,
                height: 256,
                decoration: BoxDecoration(
                  color: AppColors.blue500.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(128),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                    child: Container(),
                  ),
                ),
              ),
            ),

            // Main Content
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Top Bar
                  Padding(
                    padding: EdgeInsets.only(
                      left: isMobile ? 24 : 32,
                      right: isMobile ? 24 : 32,
                      top: isMobile ? 16 : 20,
                      bottom: isMobile ? 12 : 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back Button
                        GestureDetector(
                          onTap: () => context.go('/home'),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chevron_left,
                                color: AppColors.cyan400,
                                size: isMobile ? 24 : 28,
                              ),
                              SizedBox(width: isMobile ? 4 : 6),
                              Text(
                                'Home',
                                style: TextStyle(
                                  color: AppColors.cyan400,
                                  fontSize: isMobile ? 16 : 18,
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 300.ms)
                            .slideX(begin: -0.2, end: 0, duration: 300.ms),

                        // Right Controls
                        Row(
                          children: [
                            // Chat Button
                            GestureDetector(
                              onTap: () => setState(() => _showChat = !_showChat),
                              child: Container(
                                padding: EdgeInsets.all(isMobile ? 12 : 14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.primaryLight.withOpacity(0.6),
                                      AppColors.primaryDarker.withOpacity(0.6),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                                  border: Border.all(
                                    color: AppColors.cyan500.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                    child: Stack(
                                      children: [
                                        Icon(
                                          Icons.message,
                                          color: AppColors.cyan400,
                                          size: isMobile ? 20 : 24,
                                        ),
                                        if (_messages.length > 1)
                                          Positioned(
                                            top: -4,
                                            right: -4,
                                            child: Container(
                                              width: isMobile ? 18 : 20,
                                              height: isMobile ? 18 : 20,
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFFEC4899),
                                                    Color(0xFFA855F7),
                                                  ],
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '${_messages.length}',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: isMobile ? 10 : 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: isMobile ? 12 : 16),
                            // Menu Button
                            Container(
                              padding: EdgeInsets.all(isMobile ? 12 : 14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primaryLight.withOpacity(0.6),
                                    AppColors.primaryDarker.withOpacity(0.6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                                border: Border.all(
                                  color: AppColors.cyan500.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Icon(
                                    Icons.menu,
                                    color: AppColors.cyan400,
                                    size: isMobile ? 20 : 24,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .slideY(begin: -0.2, end: 0, duration: 500.ms),
                      ],
                    ),
                  ),

                  // Header
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 32),
                    child: Column(
                      children: [
                        Text(
                          'Talk to buddy',
                          style: TextStyle(
                            color: AppColors.textCyan200.withOpacity(0.6),
                            fontSize: isMobile ? 14 : 16,
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .slideY(begin: -0.2, end: 0, duration: 500.ms),
                        SizedBox(height: isMobile ? 8 : 12),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _isListening
                                ? "Go ahead, I'm listening..."
                                : _isSpeaking
                                    ? "Let me think about that..."
                                    : "Ready to assist you with",
                            key: ValueKey(_isListening ? "listening" : _isSpeaking ? "speaking" : "idle"),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textWhite,
                              fontSize: isMobile ? 18 : 20,
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 300.ms)
                              .slideY(begin: 0.1, end: 0, duration: 300.ms),
                        ),
                        if (!_isListening && !_isSpeaking)
                          Text(
                            'whatever you need today!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textWhite,
                              fontSize: isMobile ? 18 : 20,
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 200.ms, duration: 300.ms),
                      ],
                    ),
                  ),

                  SizedBox(height: isMobile ? 32 : 40),

                  // Waveform Visualization
                  _WaveformWidget(
                    isListening: _isListening,
                    isSpeaking: _isSpeaking,
                    isMobile: isMobile,
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 500.ms)
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1, 1),
                        delay: 300.ms,
                        duration: 500.ms,
                      ),

                  const Spacer(),

                  // Central Microphone Button
                  _MicrophoneButton(
                    isListening: _isListening,
                    onTap: _handleMicToggle,
                    isMobile: isMobile,
                  )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 500.ms)
                      .scale(
                        begin: const Offset(0, 0),
                        end: const Offset(1, 1),
                        delay: 500.ms,
                        duration: 500.ms,
                        curve: Curves.elasticOut,
                      ),

                  SizedBox(height: isMobile ? 32 : 40),

                  // Bottom Text Input
                  Padding(
                    padding: EdgeInsets.only(
                      left: isMobile ? 24 : 32,
                      right: isMobile ? 24 : 32,
                      bottom: isMobile ? 24 : 32 + MediaQuery.of(context).padding.bottom,
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 24 : 28,
                        vertical: isMobile ? 12 : 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryLight.withOpacity(0.6),
                            AppColors.primaryDarker.withOpacity(0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(isMobile ? 30 : 35),
                        border: Border.all(
                          color: AppColors.cyan500.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(isMobile ? 30 : 35),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _inputController,
                                  style: TextStyle(
                                    color: AppColors.textWhite,
                                    fontSize: isMobile ? 14 : 16,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Enter your prompt here...',
                                    hintStyle: TextStyle(
                                      color: AppColors.textCyan200.withOpacity(0.3),
                                      fontSize: isMobile ? 14 : 16,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onSubmitted: (_) => _handleSendMessage(),
                                ),
                              ),
                              SizedBox(width: isMobile ? 8 : 12),
                              GestureDetector(
                                onTap: _handleSendMessage,
                                child: Container(
                                  padding: EdgeInsets.all(isMobile ? 8 : 10),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.buttonGradient,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.send,
                                    color: Colors.white,
                                    size: isMobile ? 16 : 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 600.ms, duration: 500.ms)
                      .slideY(begin: 0.2, end: 0, delay: 600.ms, duration: 500.ms),
                ],
              ),
            ),

            // Chat Overlay
            if (_showChat)
              _ChatOverlay(
                messages: _messages,
                onClose: () => setState(() => _showChat = false),
                isMobile: isMobile,
              ),
          ],
        ),
      ),
    );
  }
}

class _WaveformWidget extends StatefulWidget {
  final bool isListening;
  final bool isSpeaking;
  final bool isMobile;

  const _WaveformWidget({
    required this.isListening,
    required this.isSpeaking,
    required this.isMobile,
  });

  @override
  State<_WaveformWidget> createState() => _WaveformWidgetState();
}

class _WaveformWidgetState extends State<_WaveformWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  final List<double> _baseHeights = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 40; i++) {
      _baseHeights.add(20 + _random.nextDouble() * 30);
    }
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: widget.isSpeaking ? 300 : widget.isListening ? 500 : 1500,
      ),
    )..repeat();
  }

  @override
  void didUpdateWidget(_WaveformWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSpeaking != widget.isSpeaking ||
        oldWidget.isListening != widget.isListening) {
      _controller.duration = Duration(
        milliseconds: widget.isSpeaking ? 300 : widget.isListening ? 500 : 1500,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.isMobile ? 160 : 180,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(40, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delay = index * 0.05;
              final animationValue = (_controller.value + delay) % 1.0;
              final heightMultiplier = widget.isListening || widget.isSpeaking
                  ? 1.0 + (sin(animationValue * 2 * pi) * 0.5 + 0.5)
                  : 0.3 + (sin(animationValue * 2 * pi) * 0.2);
              final height = _baseHeights[index] * heightMultiplier;

              return Container(
                width: widget.isMobile ? 2 : 3,
                margin: EdgeInsets.symmetric(horizontal: widget.isMobile ? 1 : 1.5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color.fromRGBO(
                        100 + (index * 3).clamp(0, 155).toInt(),
                        50 + (index * 4).clamp(0, 205).toInt(),
                        200 + (index * 1).clamp(0, 55).toInt(),
                        1.0,
                      ),
                      Color.fromRGBO(
                        150 + (index * 2).clamp(0, 105).toInt(),
                        100 + (index * 3).clamp(0, 155).toInt(),
                        255,
                        1.0,
                      ),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(widget.isMobile ? 1 : 1.5),
                ),
                height: height.clamp(10, double.infinity),
              );
            },
          );
        }),
      ),
    );
  }
}

class _MicrophoneButton extends StatefulWidget {
  final bool isListening;
  final VoidCallback onTap;
  final bool isMobile;

  const _MicrophoneButton({
    required this.isListening,
    required this.onTap,
    required this.isMobile,
  });

  @override
  State<_MicrophoneButton> createState() => _MicrophoneButtonState();
}

class _MicrophoneButtonState extends State<_MicrophoneButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isListening) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(_MicrophoneButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !oldWidget.isListening) {
      _pulseController.repeat();
    } else if (!widget.isListening && oldWidget.isListening) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          if (widget.isListening)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_pulseController.value * 0.3),
                  child: Opacity(
                    opacity: 0.5 - (_pulseController.value * 0.5),
                    child: Container(
                      width: widget.isMobile ? 120 : 140,
                      height: widget.isMobile ? 120 : 140,
                      decoration: BoxDecoration(
                        color: AppColors.cyan500.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            ),
          // Main button
          Container(
            width: widget.isMobile ? 96 : 112,
            height: widget.isMobile ? 96 : 112,
            decoration: BoxDecoration(
              gradient: widget.isListening
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.cyan400,
                        AppColors.blue500,
                      ],
                    )
                  : null,
              color: widget.isListening
                  ? null
                  : AppColors.primaryLight.withOpacity(0.8),
              shape: BoxShape.circle,
              border: widget.isListening
                  ? null
                  : Border.all(
                      color: AppColors.cyan500.withOpacity(0.3),
                      width: 2,
                    ),
              boxShadow: widget.isListening
                  ? [
                      BoxShadow(
                        color: AppColors.cyan500.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              widget.isListening ? Icons.mic_off : Icons.mic,
              color: widget.isListening ? Colors.white : AppColors.cyan400,
              size: widget.isMobile ? 40 : 48,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatOverlay extends StatelessWidget {
  final List<Message> messages;
  final VoidCallback onClose;
  final bool isMobile;

  const _ChatOverlay({
    required this.messages,
    required this.onClose,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.only(
                left: isMobile ? 24 : 32,
                right: isMobile ? 24 : 32,
                top: isMobile ? 16 : 20,
                bottom: isMobile ? 12 : 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Conversation',
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontSize: isMobile ? 20 : 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: onClose,
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
                            Icons.close,
                            color: AppColors.cyan400,
                            size: isMobile ? 20 : 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Messages
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(
                  left: isMobile ? 24 : 32,
                  right: isMobile ? 24 : 32,
                  bottom: isMobile ? 24 : 32 + MediaQuery.of(context).padding.bottom,
                ),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return _MessageBubble(
                    message: message,
                    isMobile: isMobile,
                  )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideX(
                        begin: message.sender == MessageSender.user ? 0.2 : -0.2,
                        end: 0,
                        duration: 300.ms,
                      );
                },
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 1.0, end: 0.0, duration: 400.ms, curve: Curves.easeOut);
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMobile;

  const _MessageBubble({
    required this.message,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    final timeString = '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 16 : 20),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 20,
                vertical: isMobile ? 12 : 14,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryLight.withOpacity(0.6),
                    AppColors.primaryDarker.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isMobile ? 20 : 24),
                  topRight: Radius.circular(isMobile ? 20 : 24),
                  bottomRight: Radius.circular(isMobile ? 20 : 24),
                  bottomLeft: const Radius.circular(4),
                ),
                border: Border.all(
                  color: AppColors.cyan500.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isMobile ? 20 : 24),
                  topRight: Radius.circular(isMobile ? 20 : 24),
                  bottomRight: Radius.circular(isMobile ? 20 : 24),
                  bottomLeft: const Radius.circular(4),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: isMobile ? 14 : 16,
                        ),
                      ),
                      SizedBox(height: isMobile ? 4 : 6),
                      Text(
                        timeString,
                        style: TextStyle(
                          color: AppColors.textCyan200.withOpacity(0.5),
                          fontSize: isMobile ? 11 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 20,
                vertical: isMobile ? 12 : 14,
              ),
              decoration: BoxDecoration(
                gradient: AppColors.buttonGradient,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isMobile ? 20 : 24),
                  topRight: Radius.circular(isMobile ? 20 : 24),
                  bottomLeft: Radius.circular(isMobile ? 20 : 24),
                  bottomRight: const Radius.circular(4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 14 : 16,
                    ),
                  ),
                  SizedBox(height: isMobile ? 4 : 6),
                  Text(
                    timeString,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: isMobile ? 11 : 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum MessageSender { user, ai }

class Message {
  final int id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
  });
}
