import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum CategoryBadgeSize { small, medium, large }

/// Reusable, executive category badge pill for receipts, filters, and charts
class CategoryBadge extends StatelessWidget {
  final String category;
  final bool showIcon;
  final CategoryBadgeSize size;
  final VoidCallback? onTap;
  final bool isSelected;
  final String? customLabel;

  const CategoryBadge({
    super.key,
    required this.category,
    this.showIcon = true,
    this.size = CategoryBadgeSize.medium,
    this.onTap,
    this.isSelected = false,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = CategoryTheme.getStyle(category);

    final double fontSize = switch (size) {
      CategoryBadgeSize.small => 10.0,
      CategoryBadgeSize.medium => 11.5,
      CategoryBadgeSize.large => 13.0,
    };

    final double iconSize = switch (size) {
      CategoryBadgeSize.small => 12.0,
      CategoryBadgeSize.medium => 14.0,
      CategoryBadgeSize.large => 16.0,
    };

    final EdgeInsets padding = switch (size) {
      CategoryBadgeSize.small => const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      CategoryBadgeSize.medium => const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      CategoryBadgeSize.large => const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    };

    final Color bgColor = isSelected
        ? style.primary
        : style.backgroundColor(isDark);

    final Color borderColor = isSelected
        ? style.primary
        : style.borderColor(isDark);

    final Color fgColor = isSelected
        ? Colors.white
        : style.primary;

    final badge = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              style.icon,
              size: iconSize,
              color: fgColor,
            ),
            SizedBox(width: size == CategoryBadgeSize.small ? 4 : 5),
          ],
          Text(
            customLabel ?? style.label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: fgColor,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: badge,
      );
    }
    return badge;
  }
}

/// Category icon container for list items and receipt headers
class CategoryAvatar extends StatelessWidget {
  final String category;
  final double size;
  final double iconSize;
  final double borderRadius;

  const CategoryAvatar({
    super.key,
    required this.category,
    this.size = 44,
    this.iconSize = 22,
    this.borderRadius = 13,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = CategoryTheme.getStyle(category);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: style.backgroundColor(isDark),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: style.borderColor(isDark).withOpacity(0.6), width: 1.0),
      ),
      child: Center(
        child: Icon(
          style.icon,
          size: iconSize,
          color: style.primary,
        ),
      ),
    );
  }
}
