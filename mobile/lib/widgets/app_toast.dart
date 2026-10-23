import 'package:flutter/material.dart';

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
        bgColor = isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5);
        borderColor = isDark ? const Color(0xFF059669) : const Color(0xFFA7F3D0);
        iconColor = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
        textColor = isDark ? const Color(0xFFECFDF5) : const Color(0xFF065F46);
        iconData = Icons.check_circle_rounded;
        break;
      case ToastType.error:
        bgColor = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2);
        borderColor = isDark ? const Color(0xFFDC2626) : const Color(0xFFFECACA);
        iconColor = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
        textColor = isDark ? const Color(0xFFFEF2F2) : const Color(0xFF991B1B);
        iconData = Icons.error_rounded;
        break;
      case ToastType.warning:
        bgColor = isDark ? const Color(0xFF78350F) : const Color(0xFFFFFBEB);
        borderColor = isDark ? const Color(0xFFD97706) : const Color(0xFFFDE68A);
        iconColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
        textColor = isDark ? const Color(0xFFFFFBEB) : const Color(0xFF92400E);
        iconData = Icons.warning_amber_rounded;
        break;
      case ToastType.info:
        bgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF);
        borderColor = isDark ? const Color(0xFF3B82F6) : const Color(0xFFBFDBFE);
        iconColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
        textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E40AF);
        iconData = Icons.info_rounded;
        break;
    }

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 86, // Floats above the floating navbar
        ),
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 3),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                blurRadius: 14,
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
                  color: iconColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: iconColor, size: 18),
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
                      color: iconColor.withOpacity(0.2),
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
