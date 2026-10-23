import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';

/// Floating Pill Bottom Navigation Bar
/// Inspired by the Leafora reference design:
/// - Floating warm white/card surface with soft rounded corners
/// - Subtle natural drop shadow
/// - Active tab highlighted with a soft sage pill container & forest green icons
/// - Big 26px icons with permanent 10px bold text labels beneath
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
    final navBg = isDark ? AppTheme.cardDark : Colors.white;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: bottomInset > 0 ? bottomInset + 4 : 16,
        top: 6,
      ),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: navBg,
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.07),
              blurRadius: 20,
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
                fallbackIcon: Icons.camera_alt_outlined,
                isDark: isDark,
              ),
            ),
            Expanded(
              child: _buildNavItem(
                index: 1,
                label: 'Ledger',
                svgPath: 'assets/icons/ledger_icon.svg',
                fallbackIcon: Icons.receipt_long_outlined,
                isDark: isDark,
              ),
            ),
            Expanded(
              child: _buildNavItem(
                index: 2,
                label: 'Review',
                svgPath: 'assets/icons/review_icon.svg',
                fallbackIcon: Icons.rate_review_outlined,
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

    // Reference active style: deep forest green pill with white text & icon
    const Color activePillBg = AppTheme.forestPrimary;
    const Color activeContent = Colors.white;
    const Color inactiveContent = AppTheme.textMuted;

    return GestureDetector(
      onTap: () => onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activePillBg : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bigger 26px Icon with badge
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
                    right: -10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.badgeRed,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? AppTheme.cardDark : Colors.white,
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
