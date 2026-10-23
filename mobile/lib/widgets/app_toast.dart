import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ToastType { success, error, info, warning }

class AppToast {
  static void showSuccess(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(context, message, ToastType.success, actionLabel: actionLabel, onAction: onAction);
  }

  static void showError(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(context, message, ToastType.error, actionLabel: actionLabel, onAction: onAction);
  }

  static void showInfo(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(context, message, ToastType.info, actionLabel: actionLabel, onAction: onAction);
  }

  static void showWarning(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(context, message, ToastType.warning, actionLabel: actionLabel, onAction: onAction);
  }

  // Convenient shorthand aliases
  static void success(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      showSuccess(context, message, actionLabel: actionLabel, onAction: onAction);

  static void error(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      showError(context, message, actionLabel: actionLabel, onAction: onAction);

  static void info(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      showInfo(context, message, actionLabel: actionLabel, onAction: onAction);

  static void warning(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      showWarning(context, message, actionLabel: actionLabel, onAction: onAction);

  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      _show(context, message, type, actionLabel: actionLabel, onAction: onAction);

  static void _show(
    BuildContext context,
    String message,
    ToastType type, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor;
    Color borderColor;
    Color iconColor;
    Color textColor;
    IconData iconData;

    switch (type) {
      case ToastType.success:
        bgColor = isDark ? const Color(0xFF14271D) : const Color(0xFFEAF4EE);
        borderColor = isDark ? const Color(0xFF2E7D5B) : const Color(0xFFBFE0CE);
        iconColor = isDark ? const Color(0xFF5DBB8D) : const Color(0xFF2E7D5B);
        textColor = isDark ? const Color(0xFFEAF4EE) : const Color(0xFF184431);
        iconData = Icons.check_circle_rounded;
        break;
      case ToastType.error:
        bgColor = isDark ? const Color(0xFF2B1313) : const Color(0xFFFDF0F0);
        borderColor = isDark ? const Color(0xFFD9534F) : const Color(0xFFF6C3C1);
        iconColor = isDark ? const Color(0xFFF28B87) : const Color(0xFFD9534F);
        textColor = isDark ? const Color(0xFFFDF0F0) : const Color(0xFF8B2522);
        iconData = Icons.error_rounded;
        break;
      case ToastType.warning:
        bgColor = isDark ? const Color(0xFF291F0E) : const Color(0xFFFEF8EC);
        borderColor = isDark ? const Color(0xFFD97706) : const Color(0xFFFDE68A);
        iconColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
        textColor = isDark ? const Color(0xFFFEF8EC) : const Color(0xFF92400E);
        iconData = Icons.warning_amber_rounded;
        break;
      case ToastType.info:
        bgColor = isDark ? const Color(0xFF18241D) : const Color(0xFFF3F6F3);
        borderColor = isDark ? const Color(0xFF3B5646) : const Color(0xFFD0DDD3);
        iconColor = isDark ? const Color(0xFF86AB93) : AppTheme.forestPrimary;
        textColor = isDark ? const Color(0xFFF3F6F4) : AppTheme.textDark;
        iconData = Icons.info_outline_rounded;
        break;
    }

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.only(
          left: 18,
          right: 18,
          bottom: 92, // Floats comfortably above the floating navbar
        ),
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 3),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: iconColor, size: 17),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    messenger.hideCurrentSnackBar();
                    onAction();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      actionLabel,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
