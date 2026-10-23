import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';

/// Persistent Header matching the design in CAPTURE.png, LEDGER.png, REVIEW.png
class AppHeader extends StatelessWidget {
  final String subCaption; // e.g. "CAPTURE", "LEDGER", "REVIEW"
  final VoidCallback? onAvatarTap;

  const AppHeader({
    super.key,
    required this.subCaption,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerBg = isDark ? AppTheme.headerBlueDark : AppTheme.headerBlue;
    final primaryTextColor = isDark ? Colors.white : AppTheme.navyBrand;
    final subTextColor = isDark ? Colors.white70 : AppTheme.navyBrand.withOpacity(0.65);

    return Container(
      color: headerBg,
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
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
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
                  Text(
                    'ReceiptLedger',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    subCaption.toUpperCase(),
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Right: User Profile Avatar with green online dot + quick menu cue
          GestureDetector(
            onTap: onAvatarTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.white,
                          width: 1.8,
                        ),
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
                          border: Border.all(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.menu_rounded,
                  size: 20,
                  color: isDark ? Colors.white70 : AppTheme.navyBrand.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
