import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';

/// Floating Pill Bottom Navigation Bar
/// Meets specifications:
/// 1. Floating above the bottom with elevation and margins
/// 2. Bigger icons (26px)
/// 3. Text label always visible in smaller font beneath every tab
/// 4. 3 primary tabs (Settings moved to the Sidebar)
class FloatingBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final int reviewBadgeCount;

  const FloatingBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.reviewBadgeCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final navBg = isDark ? const Color(0xFF1E293B) : AppTheme.headerBlue;
    final shadowColor = isDark
        ? Colors.black.withOpacity(0.45)
        : AppTheme.headerBlue.withOpacity(0.38);

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: bottomInset > 0 ? bottomInset + 4 : 16,
        top: 6,
      ),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: navBg,
          borderRadius: BorderRadius.circular(34),
          border: isDark ? Border.all(color: const Color(0xFF334155), width: 1.2) : null,
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: _buildNavItem(
                index: 0,
                label: 'Capture',
                svgPath: 'assets/icons/capture_icon.svg',
                fallbackIcon: Icons.camera_alt_rounded,
                isDark: isDark,
              ),
            ),
            Expanded(
              child: _buildNavItem(
                index: 1,
                label: 'Ledger',
                svgPath: 'assets/icons/ledger_icon.svg',
                fallbackIcon: Icons.receipt_long_rounded,
                isDark: isDark,
              ),
            ),
            Expanded(
              child: _buildNavItem(
                index: 2,
                label: 'Review',
                svgPath: 'assets/icons/review_icon.svg',
                fallbackIcon: Icons.rate_review_rounded,
                badge: reviewBadgeCount,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required String svgPath,
    required IconData fallbackIcon,
    required bool isDark,
    int badge = 0,
  }) {
    final isSelected = currentIndex == index;

    final Color activeBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final Color activeContent = isDark ? const Color(0xFF93C5FD) : AppTheme.navyBrand;
    final Color inactiveContent = isDark ? const Color(0xFF94A3B8) : Colors.white.withOpacity(0.85);

    return GestureDetector(
      onTap: () => onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bigger Icon with badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  width: 26,
                  height: 26,
                  child: SvgPicture.asset(
                    svgPath,
                    colorFilter: ColorFilter.mode(
                      isSelected ? activeContent : inactiveContent,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                // Review badge count
                if (badge > 0)
                  Positioned(
                    top: -4,
                    right: -9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.badgeRed,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? activeBg : (isDark ? const Color(0xFF1E293B) : AppTheme.headerBlue),
                          width: 1.5,
                        ),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$badge',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            // Always-visible smaller text label beneath icon
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? activeContent : inactiveContent,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.2,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
