import 'package:flutter/material.dart';
import '../Config/Theme/AppTheme.dart';

class AppTitleBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackArrow;
  final Color? backArrowColor;
  final VoidCallback? onBack;
  final String? title;
  final Color? titleColor;

  const AppTitleBar({
    super.key,
    this.showBackArrow = true,
    this.backArrowColor,
    this.onBack,
    this.title,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        height: preferredSize.height + 12,
        color: theme.scaffoldBackgroundColor, // Neutral base, not red
        child: Row(
          children: [
            // Back Arrow
            if (showBackArrow)
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: backArrowColor ?? (isDark ? Colors.white70 : Colors.black87),
                ),
                onPressed: onBack ?? () => Navigator.of(context).pop(),
                tooltip: 'Back',
              ),
            if (showBackArrow) const SizedBox(width: 4),

            // Title or Logo
            Expanded(
              child: title != null
                  ? Text(
                title!,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: titleColor ?? (isDark ? Colors.white : Colors.black87),
                  fontFamily: 'Poppins',
                ),
              )
                  : RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                  children: [
                    TextSpan(
                      text: 'Club-',
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    ),
                    const TextSpan(
                      text: 'Ignite',
                      style: TextStyle(color: AppTheme.primaryRed),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}
