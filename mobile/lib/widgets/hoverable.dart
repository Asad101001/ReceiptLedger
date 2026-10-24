import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable hover interaction wrapper for Flutter Web and Desktop.
/// Gracefully no-ops on touch devices while providing elegant micro-interactions
/// on pointer-enabled platforms.
class Hoverable extends StatefulWidget {
  final Widget child;
  final double scale;
  final Duration duration;
  final Curve curve;
  final BorderRadius? borderRadius;
  final Color? hoverBorderColor;
  final Color? hoverColor;
  final List<BoxShadow>? hoverShadow;
  final VoidCallback? onTap;
  final bool enabled;
  final MouseCursor cursor;

  const Hoverable({
    super.key,
    required this.child,
    this.scale = 1.02,
    this.duration = const Duration(milliseconds: 180),
    this.curve = Curves.easeOutCubic,
    this.borderRadius,
    this.hoverBorderColor,
    this.hoverColor,
    this.hoverShadow,
    this.onTap,
    this.enabled = true,
    this.cursor = SystemMouseCursors.click,
  });

  @override
  State<Hoverable> createState() => _HoverableState();
}

class _HoverableState extends State<Hoverable> {
  bool _isHovered = false;

  void _onEnter(PointerEvent event) {
    if (widget.enabled && !_isHovered) {
      setState(() => _isHovered = true);
    }
  }

  void _onExit(PointerEvent event) {
    if (_isHovered) {
      setState(() => _isHovered = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultHoverShadow = [
      BoxShadow(
        color: (isDark ? Colors.black : AppTheme.forestPrimary).withOpacity(isDark ? 0.35 : 0.12),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
    ];

    Widget content = widget.child;

    return MouseRegion(
      cursor: widget.onTap != null ? widget.cursor : SystemMouseCursors.basic,
      onEnter: _onEnter,
      onExit: _onExit,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: (_isHovered && widget.enabled) ? widget.scale : 1.0,
          duration: widget.duration,
          curve: widget.curve,
          child: AnimatedContainer(
            duration: widget.duration,
            curve: widget.curve,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              color: (_isHovered && widget.hoverColor != null) ? widget.hoverColor : Colors.transparent,
              border: widget.hoverBorderColor != null && _isHovered
                  ? Border.all(color: widget.hoverBorderColor!, width: 1.5)
                  : null,
              boxShadow: _isHovered ? (widget.hoverShadow ?? defaultHoverShadow) : null,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Reusable Luxury Hover Button with organic financial ledger styling
class HoverButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final double height;
  final double? width;
  final Color? customColor;

  const HoverButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.height = 54,
    this.width,
    this.customColor,
  });

  @override
  State<HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<HoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = widget.customColor ?? (isDark ? const Color(0xFF86AB93) : AppTheme.forestPrimary);
    final secondaryBg = isDark ? AppTheme.cardDarkElevated : AppTheme.sageLight;

    return MouseRegion(
      cursor: widget.onPressed != null && !widget.isLoading
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: (_isHovered && widget.onPressed != null && !widget.isLoading) ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          height: widget.height,
          width: widget.width ?? double.infinity,
          decoration: BoxDecoration(
            color: widget.isSecondary
                ? (_isHovered ? (isDark ? const Color(0xFF2B3F33) : const Color(0xFFDCE6DE)) : secondaryBg)
                : (_isHovered ? AppTheme.forestLight : primaryColor),
            borderRadius: BorderRadius.circular(16),
            border: widget.isSecondary
                ? Border.all(
                    color: _isHovered ? AppTheme.forestPrimary : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
                    width: 1.2,
                  )
                : null,
            boxShadow: _isHovered && !widget.isSecondary
                ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: widget.isLoading ? null : widget.onPressed,
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: widget.isSecondary ? primaryColor : Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              size: 20,
                              color: widget.isSecondary
                                  ? (isDark ? Colors.white : AppTheme.forestPrimary)
                                  : Colors.white,
                            ),
                            const SizedBox(width: 9),
                          ],
                          Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: widget.isSecondary
                                  ? (isDark ? Colors.white : AppTheme.forestPrimary)
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
