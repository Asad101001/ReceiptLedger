import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/fade_slide_transition.dart';
import '../widgets/hoverable.dart';

/// Cohesive, Luxury Login & Sign Up Screen
/// Matching the warm organic financial ledger aesthetic:
/// - Smooth tab switcher between Sign In & Create Account
/// - 1-Click Instant Demo Login (user@receiptledger.com / demo1234)
/// - Robust input validation with zero keyboard overflow
/// - Full ApiService integration with graceful offline mode
/// - Desktop/Web hover effects and micro-interactions
class AuthScreen extends StatefulWidget {
  final bool initialIsSignUp;

  const AuthScreen({super.key, this.initialIsSignUp = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ApiService _api = ApiService();

  // Login form controllers
  final TextEditingController _loginEmailCtrl = TextEditingController(text: 'user@receiptledger.com');
  final TextEditingController _loginPassCtrl = TextEditingController(text: 'demo1234');
  bool _loginObscure = true;
  bool _rememberMe = true;
  bool _biometricsQuickLogin = true;
  bool _isLoginLoading = false;

  // Sign up form controllers
  final TextEditingController _regNameCtrl = TextEditingController();
  final TextEditingController _regEmailCtrl = TextEditingController();
  final TextEditingController _regPassCtrl = TextEditingController();
  final TextEditingController _regConfirmPassCtrl = TextEditingController();
  String _selectedCurrency = 'PKR';
  bool _regObscure = true;
  bool _regConfirmObscure = true;
  bool _acceptTerms = true;
  bool _isRegisterLoading = false;

  final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIsSignUp ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _regNameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    _regConfirmPassCtrl.dispose();
    super.dispose();
  }

  void _fillDemoCredentials() {
    setState(() {
      _loginEmailCtrl.text = 'user@receiptledger.com';
      _loginPassCtrl.text = 'demo1234';
    });
    AppToast.showSuccess(context, 'Filled Demo Account: user@receiptledger.com');
  }

  Future<void> _handleLogin() async {
    final email = _loginEmailCtrl.text.trim();
    final password = _loginPassCtrl.text;

    if (email.isEmpty) {
      AppToast.showError(context, 'Please enter your email address.');
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      AppToast.showError(context, 'Please enter a valid email format.');
      return;
    }
    if (password.isEmpty) {
      AppToast.showError(context, 'Please enter your password.');
      return;
    }

    setState(() => _isLoginLoading = true);

    try {
      final user = await _api.login(email: email, password: password);
      if (!mounted) return;
      AppToast.showSuccess(context, 'Welcome back, ${user.fullName}!');

      Navigator.of(context).pushReplacement(
        AppPageTransition(page: const MainNavigationScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceAll('Exception: ', '');
      AppToast.showError(context, msg);
    } finally {
      if (mounted) {
        setState(() => _isLoginLoading = false);
      }
    }
  }

  Future<void> _handleRegister() async {
    final name = _regNameCtrl.text.trim();
    final email = _regEmailCtrl.text.trim();
    final pass = _regPassCtrl.text;
    final confirm = _regConfirmPassCtrl.text;

    if (name.isEmpty) {
      AppToast.showError(context, 'Please enter your full name.');
      return;
    }
    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      AppToast.showError(context, 'Please enter a valid email address.');
      return;
    }
    if (pass.length < 6) {
      AppToast.showError(context, 'Password must be at least 6 characters.');
      return;
    }
    if (pass != confirm) {
      AppToast.showError(context, 'Passwords do not match.');
      return;
    }
    if (!_acceptTerms) {
      AppToast.showError(context, 'Please accept the Terms & Privacy Policy.');
      return;
    }

    setState(() => _isRegisterLoading = true);

    try {
      final user = await _api.register(email: email, password: pass, fullName: name);
      _api.setCurrency(_selectedCurrency == 'PKR' ? 'Rs.' : _selectedCurrency);
      if (!mounted) return;
      AppToast.showSuccess(context, 'Account created! Welcome, ${user.fullName}');

      Navigator.of(context).pushReplacement(
        AppPageTransition(page: const MainNavigationScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceAll('Exception: ', '');
      AppToast.showError(context, msg);
    } finally {
      if (mounted) {
        setState(() => _isRegisterLoading = false);
      }
    }
  }

  void _continueAsGuest() {
    _api.login(email: 'guest@receiptledger.com', password: 'guestpassword');
    AppToast.showInfo(context, 'Entering Guest / Offline Ledger Session.');
    Navigator.of(context).pushReplacement(
      AppPageTransition(page: const MainNavigationScreen()),
    );
  }

  void _showForgotPasswordSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reset Password',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'In dev & local mode, demo credentials are pre-configured: email user@receiptledger.com with password demo1234.',
                  style: TextStyle(fontSize: 14, color: AppTheme.textMuted, height: 1.4),
                ),
                const SizedBox(height: 20),
                HoverButton(
                  label: 'Use Demo Credentials',
                  icon: Icons.auto_fix_high_rounded,
                  onPressed: () {
                    Navigator.pop(ctx);
                    _fillDemoCredentials();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canvasBg = isDark ? AppTheme.canvasDark : AppTheme.canvasLight;
    final cardBg = isDark ? AppTheme.cardDark : Colors.white;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final textPrimary = isDark ? AppTheme.textLight : AppTheme.textDark;
    final textMuted = isDark ? AppTheme.textMutedDark : AppTheme.textMuted;
    final brandColor = isDark ? const Color(0xFF86AB93) : AppTheme.forestPrimary;

    return Scaffold(
      backgroundColor: canvasBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),

                  // Brand Header
                  FadeSlideTransition(
                    duration: const Duration(milliseconds: 400),
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: borderColor, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(13),
                            child: SvgPicture.asset(
                              'assets/icons/app_icon.svg',
                              colorFilter: ColorFilter.mode(
                                brandColor,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'ReceiptLedger',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: textPrimary,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Smart OCR & Financial Intelligence',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Sliding Tab Switcher Pill
                  FadeSlideTransition(
                    delay: const Duration(milliseconds: 100),
                    duration: const Duration(milliseconds: 400),
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.cardDarkElevated : const Color(0xFFEAF0EB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: 1.0),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: brandColor,
                        unselectedLabelColor: textMuted,
                        labelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        tabs: const [
                          Tab(text: 'Sign In'),
                          Tab(text: 'Create Account'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Tab Views Container
                  AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: _tabController.index == 0
                            ? _buildLoginForm(cardBg, borderColor, textPrimary, textMuted, brandColor, isDark)
                            : _buildSignUpForm(cardBg, borderColor, textPrimary, textMuted, brandColor, isDark),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Guest / Offline Mode Link
                  Center(
                    child: Hoverable(
                      scale: 1.03,
                      onTap: _continueAsGuest,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_open_rounded, size: 16, color: brandColor),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Continue as Guest',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: brandColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Login Form ─────────────────────────────────────────────────────────────
  Widget _buildLoginForm(
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textMuted,
    Color brandColor,
    bool isDark,
  ) {
    return Container(
      key: const ValueKey('login_form'),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1-Click Demo Account Banner
          Hoverable(
            scale: 1.015,
            onTap: _fillDemoCredentials,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF22352A) : AppTheme.sageLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF2D4637) : AppTheme.borderLight,
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.cardDarkElevated : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.flash_on_rounded, size: 16, color: brandColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '1-Click Demo Credentials',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: brandColor,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'user@receiptledger.com • demo1234',
                          style: TextStyle(
                            fontSize: 11,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.touch_app_rounded, size: 16, color: brandColor),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Email Field
          _buildFieldLabel('EMAIL ADDRESS', textMuted),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _loginEmailCtrl,
            hintText: 'name@company.com',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            isDark: isDark,
          ),

          const SizedBox(height: 16),

          // Password Field
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFieldLabel('PASSWORD', textMuted),
              GestureDetector(
                onTap: _showForgotPasswordSheet,
                child: Text(
                  'Forgot?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: brandColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _loginPassCtrl,
            hintText: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscureText: _loginObscure,
            isDark: isDark,
            suffixIcon: IconButton(
              icon: Icon(
                _loginObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20,
                color: textMuted,
              ),
              onPressed: () => setState(() => _loginObscure = !_loginObscure),
            ),
          ),

          const SizedBox(height: 14),

          // Remember Me & Biometrics Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _rememberMe,
                      activeColor: brandColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                      onChanged: (v) => setState(() => _rememberMe = v ?? true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Remember me',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.fingerprint_rounded, size: 18, color: brandColor),
                  const SizedBox(width: 6),
                  Text(
                    'Biometric',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMuted),
                  ),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: _biometricsQuickLogin,
                      activeColor: brandColor,
                      onChanged: (v) => setState(() => _biometricsQuickLogin = v),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Sign In Button
          HoverButton(
            label: 'Sign In to Ledger',
            icon: Icons.login_rounded,
            isLoading: _isLoginLoading,
            onPressed: _handleLogin,
          ),
        ],
      ),
    );
  }

  // ── Sign Up Form ───────────────────────────────────────────────────────────
  Widget _buildSignUpForm(
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textMuted,
    Color brandColor,
    bool isDark,
  ) {
    return Container(
      key: const ValueKey('signup_form'),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full Name
          _buildFieldLabel('FULL NAME', textMuted),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _regNameCtrl,
            hintText: 'Muhammad Asad Khan',
            icon: Icons.person_outline_rounded,
            isDark: isDark,
          ),

          const SizedBox(height: 14),

          // Email Field
          _buildFieldLabel('EMAIL ADDRESS', textMuted),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _regEmailCtrl,
            hintText: 'asad@example.com',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            isDark: isDark,
          ),

          const SizedBox(height: 14),

          // Currency Dropdown
          _buildFieldLabel('BASE CURRENCY', textMuted),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDarkElevated : AppTheme.canvasLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCurrency,
                isExpanded: true,
                dropdownColor: isDark ? AppTheme.cardDark : Colors.white,
                icon: const Icon(Icons.arrow_drop_down_rounded),
                items: const [
                  DropdownMenuItem(value: 'PKR', child: Text('PKR (Rs. Pakistani Rupee)')),
                  DropdownMenuItem(value: 'USD', child: Text('USD (\$ US Dollar)')),
                  DropdownMenuItem(value: 'EUR', child: Text('EUR (€ Euro)')),
                  DropdownMenuItem(value: 'GBP', child: Text('GBP (£ British Pound)')),
                  DropdownMenuItem(value: 'AED', child: Text('AED (UAE Dirham)')),
                  DropdownMenuItem(value: 'SAR', child: Text('SAR (Saudi Riyal)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCurrency = val);
                },
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Password Field
          _buildFieldLabel('PASSWORD', textMuted),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _regPassCtrl,
            hintText: 'Min 6 characters',
            icon: Icons.lock_outline_rounded,
            obscureText: _regObscure,
            isDark: isDark,
            suffixIcon: IconButton(
              icon: Icon(
                _regObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20,
                color: textMuted,
              ),
              onPressed: () => setState(() => _regObscure = !_regObscure),
            ),
          ),

          const SizedBox(height: 14),

          // Confirm Password Field
          _buildFieldLabel('CONFIRM PASSWORD', textMuted),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _regConfirmPassCtrl,
            hintText: 'Repeat password',
            icon: Icons.lock_reset_rounded,
            obscureText: _regConfirmObscure,
            isDark: isDark,
            suffixIcon: IconButton(
              icon: Icon(
                _regConfirmObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20,
                color: textMuted,
              ),
              onPressed: () => setState(() => _regConfirmObscure = !_regConfirmObscure),
            ),
          ),

          const SizedBox(height: 14),

          // Terms Checkbox
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _acceptTerms,
                  activeColor: brandColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  onChanged: (v) => setState(() => _acceptTerms = v ?? true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'I agree to the Terms of Service & Privacy Policy',
                  style: TextStyle(
                    fontSize: 12,
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Create Account Button
          HoverButton(
            label: 'Create Account',
            icon: Icons.person_add_alt_1_rounded,
            isLoading: _isRegisterLoading,
            onPressed: _handleRegister,
          ),
        ],
      ),
    );
  }

  // Helper field builders
  Widget _buildFieldLabel(String label, Color color) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool isDark,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDarkElevated : AppTheme.canvasLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
          width: 1.2,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppTheme.textDark,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 14,
            color: Color(0xFF9EAAA2),
            fontWeight: FontWeight.normal,
          ),
          prefixIcon: Icon(icon, size: 20, color: const Color(0xFF7A8D80)),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
      ),
    );
  }
}
