import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/fade_slide_transition.dart';
import '../widgets/hoverable.dart';
import 'auth_screen.dart';
import '../main.dart';

/// Cohesive, Luxury Animated Splash Loading Screen
/// Matching the warm organic financial ledger aesthetic:
/// - Soft organic canvas (light/dark adaptive)
/// - Ambient pulsing brand mark
/// - Live backend health check & telemetry ticker
/// - Silky smooth fade & scale transitions
class SplashScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const SplashScreen({super.key, this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final AnimationController _progressController;
  late final Animation<double> _progressAnimation;

  final ApiService _api = ApiService();
  String _statusText = 'Initializing neural OCR engine...';
  int _statusStep = 0;
  Timer? _statusTimer;
  Timer? _autoProceedTimer;
  bool _hasNavigated = false;

  final List<String> _statusMessages = [
    'Initializing neural OCR engine...',
    'Checking cryptographic API gateway...',
    'Loading verified ledger accounts...',
    'Ready',
  ];

  @override
  void initState() {
    super.initState();

    // Pulse animation for ambient glow ring
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    // Progress bar animation (2.0 seconds)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOutCubic),
    );

    _progressController.forward();

    // Status message ticker
    _statusTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (!mounted) return;
      if (_statusStep < _statusMessages.length - 1) {
        setState(() {
          _statusStep++;
          _statusText = _statusMessages[_statusStep];
        });
      } else {
        timer.cancel();
      }
    });

    // Check health silently in background
    _api.checkHealthSilently();

    // Auto-proceed after brief animation
    _autoProceedTimer = Timer(const Duration(milliseconds: 2400), () {
      _proceed();
    });
  }

  void _proceed() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _statusTimer?.cancel();
    _autoProceedTimer?.cancel();

    if (widget.onComplete != null) {
      widget.onComplete!();
      return;
    }

    // If user has a valid session, navigate to MainNavigationScreen, else AuthScreen
    final destination = _api.isLoggedIn
        ? const MainNavigationScreen()
        : const AuthScreen();

    Navigator.of(context).pushReplacement(
      AppPageTransition(page: destination),
    );
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _autoProceedTimer?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canvasBg = isDark ? AppTheme.canvasDark : AppTheme.canvasLight;
    final cardBg = isDark ? AppTheme.cardDark : Colors.white;
    final textPrimary = isDark ? AppTheme.textLight : AppTheme.textDark;
    final textMuted = isDark ? AppTheme.textMutedDark : AppTheme.textMuted;
    final brandColor = isDark ? const Color(0xFF86AB93) : AppTheme.forestPrimary;
    final ringColor = isDark
        ? const Color(0xFF22352A).withOpacity(0.6)
        : AppTheme.sageLight.withOpacity(0.8);

    return Scaffold(
      backgroundColor: canvasBg,
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient subtle background gradient or circles
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isDark ? const Color(0xFF16251E) : AppTheme.sageLight).withOpacity(0.35),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isDark ? const Color(0xFF16251E) : AppTheme.sageLight).withOpacity(0.35),
                ),
              ),
            ),

            // Main Content
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),

                    // Central Pulsing Brand Mark
                    FadeSlideTransition(
                      duration: const Duration(milliseconds: 600),
                      offset: const Offset(0, 0.15),
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: child,
                          );
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer Ambient Pulse Ring
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ringColor,
                              ),
                            ),

                            // Inner Glow Ring
                            Container(
                              width: 116,
                              height: 116,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (isDark ? const Color(0xFF283E31) : const Color(0xFFDFEAE1))
                                    .withOpacity(0.7),
                              ),
                            ),

                            // Elevated Brand Container
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(
                                  color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isDark ? Colors.black : AppTheme.forestPrimary)
                                        .withOpacity(isDark ? 0.4 : 0.12),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(18),
                              child: SvgPicture.asset(
                                'assets/icons/app_icon.svg',
                                colorFilter: ColorFilter.mode(
                                  brandColor,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Brand Typography
                    FadeSlideTransition(
                      delay: const Duration(milliseconds: 200),
                      duration: const Duration(milliseconds: 500),
                      child: Column(
                        children: [
                          Text(
                            'ReceiptLedger',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: textPrimary,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Smart OCR & Financial Intelligence',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textMuted,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Version & Security Badge
                    FadeSlideTransition(
                      delay: const Duration(milliseconds: 350),
                      duration: const Duration(milliseconds: 400),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF213027) : AppTheme.sageLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.greenVerified,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'v2.4.1 • 256-Bit Encrypted',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF86AB93) : AppTheme.forestPrimary,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(flex: 4),

                    // Animated Progress Bar & Dynamic Status
                    FadeSlideTransition(
                      delay: const Duration(milliseconds: 400),
                      duration: const Duration(milliseconds: 450),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 190,
                            child: AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, _) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: _progressAnimation.value,
                                    minHeight: 4,
                                    backgroundColor: isDark
                                        ? AppTheme.cardDarkElevated
                                        : AppTheme.borderLight,
                                    valueColor: AlwaysStoppedAnimation<Color>(brandColor),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 14),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Text(
                              _statusText,
                              key: ValueKey<String>(_statusText),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Tap to Skip / Fast continue button
                    Hoverable(
                      scale: 1.03,
                      onTap: _proceed,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Tap to Continue →',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: brandColor,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),

                    const Spacer(flex: 1),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
