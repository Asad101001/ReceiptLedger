import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Refined Editorial Header matching the organic luxury aesthetic
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
    final headerBg = isDark ? AppTheme.canvasDark : AppTheme.canvasLight;
    final primaryTextColor = isDark ? Colors.white : AppTheme.textDark;

    return Container(
      color: headerBg,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        bottom: 10,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Brand Logo & Title
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(7),
                    child: SvgPicture.asset(
                      'assets/icons/app_icon.svg',
                      colorFilter: ColorFilter.mode(
                        isDark ? const Color(0xFF86AB93) : AppTheme.forestPrimary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ReceiptLedger',
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF22352A)
                              : AppTheme.sageLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          subCaption.toUpperCase(),
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF86AB93)
                                : AppTheme.forestPrimary,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Right: Live Backend Indicator & Profile Avatar
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Backend Connection Status Indicator
                  ValueListenableBuilder<bool>(
                    valueListenable: ApiService().backendOnlineNotifier,
                    builder: (ctx, isOnline, _) {
                      return GestureDetector(
                        onTap: onAvatarTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: isOnline
                                ? (isDark ? const Color(0xFF142C1F) : const Color(0xFFEAF5EE))
                                : (isDark ? const Color(0xFF241F1A) : const Color(0xFFFBF4EB)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isOnline
                                  ? (isDark ? const Color(0xFF2D6946) : const Color(0xFFBFE0CE))
                                  : (isDark ? const Color(0xFF5A4632) : const Color(0xFFEEDCC8)),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: isOnline ? AppTheme.greenVerified : AppTheme.amberWarning,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isOnline ? 'Live API' : 'Demo Mode',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isOnline
                                      ? (isDark ? const Color(0xFF5DBB8D) : const Color(0xFF1C5C3D))
                                      : (isDark ? const Color(0xFFFBBF24) : const Color(0xFF9A5506)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // User Avatar button that opens drawer
                  GestureDetector(
                    onTap: onAvatarTap,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.forestPrimary,
                        border: Border.all(
                          color: isDark ? const Color(0xFF3B5646) : Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'AK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
