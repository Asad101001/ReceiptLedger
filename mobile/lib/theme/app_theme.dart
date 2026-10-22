import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/api_service.dart';

/// ReceiptLedger Design System & Theme Tokens
/// Matches the high-fidelity mockups in UI mockups/ui and UI mockups/Icons
class AppTheme {
  // Brand Colors
  static const Color headerBlue = Color(0xFF749DF8); // Calm periwinkle blue from mockups
  static const Color headerBlueDark = Color(0xFF5E8AF3);
  static const Color navyBrand = Color(0xFF0C1E4A); // Deep midnight navy for buttons & branding
  static const Color navyBrandLight = Color(0xFF162A86);
  static const Color canvasLight = Color(0xFFF7F9FC); // Off-white modern canvas
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textMutedLight = Color(0xFF94A3B8);

  // Status & Accent Colors
  static const Color greenVerified = Color(0xFF10B981);
  static const Color greenVerifiedBg = Color(0xFFE8F7F0);
  static const Color badgeRed = Color(0xFFEF4444);
  static const Color amberWarning = Color(0xFFF59E0B);
  static const Color avatarGreen = Color(0xFF194D33); // Dark green avatar from SETTINGS.png

  // ThemeData Definition
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: canvasLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: headerBlue,
        primary: navyBrand,
        surface: cardWhite,
        brightness: Brightness.light,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: headerBlue,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF0B1120),
      colorScheme: ColorScheme.fromSeed(
        seedColor: headerBlue,
        primary: const Color(0xFF60A5FA),
        surface: const Color(0xFF1E293B),
        brightness: Brightness.dark,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E293B),
        elevation: 0,
      ),
    );
  }
}

/// Persistent Header used across all 4 screens, matching CAPTURE.png, LEDGER.png, REVIEW.png, SETTINGS.png
class AppHeader extends StatelessWidget {
  final String subCaption; // e.g. "CAPTURE", "LEDGER", "REVIEW", "SETTINGS"
  final VoidCallback? onAvatarTap;

  const AppHeader({
    super.key,
    required this.subCaption,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.headerBlue,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
        left: 16,
        right: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: App brand mark & title
          Row(
            children: [
              // White rounded container with receipt brand icon
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(6),
                child: SvgPicture.asset(
                  'assets/icons/app_icon.svg',
                  colorFilter: const ColorFilter.mode(
                    AppTheme.navyBrandLight,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Wordmark & sub-caption
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'ReceiptLedger',
                    style: TextStyle(
                      color: AppTheme.navyBrand,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    subCaption.toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.navyBrand.withOpacity(0.65),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Right: User Profile Avatar with green online dot
          GestureDetector(
            onTap: onAvatarTap,
            child: Stack(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    color: AppTheme.avatarGreen,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'AK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Green active status dot
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating pill bottom navigation bar matching the mockups
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final int reviewBadgeCount;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.reviewBadgeCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 12,
        top: 6,
      ),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppTheme.headerBlue,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppTheme.headerBlue.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, 'Capture', 'assets/icons/capture_icon.svg', Icons.camera_alt_outlined),
            _buildNavItem(1, 'Ledger', 'assets/icons/ledger_icon.svg', Icons.receipt_long_outlined),
            _buildNavItem(2, 'Review', 'assets/icons/review_icon.svg', Icons.rate_review_outlined, badge: reviewBadgeCount),
            _buildNavItem(3, 'Settings', 'assets/icons/setting_icon.svg', Icons.settings_outlined),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, String svgPath, IconData fallbackIcon, {int badge = 0}) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 18 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: SvgPicture.asset(
                    svgPath,
                    colorFilter: ColorFilter.mode(
                      isSelected ? AppTheme.navyBrand : Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                if (badge > 0 && !isSelected)
                  Positioned(
                    top: -6,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.badgeRed,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.2),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$badge',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.navyBrand,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Secret Slide-Out Profile Drawer from Section 3 of MOBILE_DESIGN_BRIEF.md
class AppProfileDrawer extends StatelessWidget {
  const AppProfileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiService();

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // User Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.avatarGreen,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'AK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Asad Khan',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'user@receiptledger.com',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.greenVerifiedBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, size: 12, color: AppTheme.greenVerified),
                              SizedBox(width: 4),
                              Text(
                                'Sync Active',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.greenVerified,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Quick Stats Card
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.headerBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.headerBlue.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem('Receipts', '24'),
                    Container(height: 24, width: 1, color: AppTheme.borderLight),
                    _statItem('Oct Spend', '${api.currency} 42,850'),
                    Container(height: 24, width: 1, color: AppTheme.borderLight),
                    _statItem('Pending', '3'),
                  ],
                ),
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _drawerTile(Icons.attach_money, 'Currency', api.currency, () {
                    Navigator.pop(context);
                  }),
                  _drawerTile(Icons.palette_outlined, 'Appearance', 'Light', () {
                    Navigator.pop(context);
                  }),
                  _drawerTile(Icons.download_outlined, 'Export Data (CSV/PDF)', 'Reports', () {
                    Navigator.pop(context);
                  }),
                  _drawerTile(Icons.dns_outlined, 'Backend Server', api.baseUrl.replaceAll('http://', ''), () {
                    Navigator.pop(context);
                  }),
                  _drawerTile(Icons.security, 'Security & Biometrics', 'Active', () {
                    Navigator.pop(context);
                  }),
                  _drawerTile(Icons.info_outline, 'About ReceiptLedger', 'v2.4.1', () {
                    Navigator.pop(context);
                  }),
                ],
              ),
            ),

            // Logout Button at bottom
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logged out of local session.')),
                  );
                },
                icon: const Icon(Icons.logout, size: 18, color: AppTheme.badgeRed),
                label: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: AppTheme.badgeRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.navyBrand,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _drawerTile(IconData icon, String title, String value, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, size: 20, color: AppTheme.navyBrand),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 16, color: AppTheme.textMutedLight),
        ],
      ),
      onTap: onTap,
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
