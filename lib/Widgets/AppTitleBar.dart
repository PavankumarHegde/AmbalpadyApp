import 'package:flutter/material.dart';
import '../Config/Theme/AppTheme.dart';

class AppTitleBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackArrow;
  final Color? backArrowColor;
  final VoidCallback? onBack;
  /// Defaults to "Ambalpady Nayak Family Trust (R)".
  final String? title;
  final Color? titleColor;
  final bool showLogo;

  const AppTitleBar({
    super.key,
    this.showBackArrow = true,
    this.backArrowColor,
    this.onBack,
    this.title,
    this.titleColor,
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveTitle = title ?? 'Ambalpady Nayak Trust (R)';

    return SafeArea(
      bottom: false,
      child: Container(
        // Increased left padding for more space at the start
        padding: const EdgeInsetsDirectional.fromSTEB(24, 12, 16, 12),
        height: preferredSize.height,
        color: theme.scaffoldBackgroundColor,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;

            // Responsive sizes
            final double fontSize = (w / 13.5).clamp(18.0, 26.0);
            // Make icon a bit larger than text for better visual balance
            final double logoHeight = (fontSize * 1.35).clamp(28.0, 44.0);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (showBackArrow)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: backArrowColor ?? (isDark ? Colors.white70 : Colors.black87),
                      ),
                      onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                      tooltip: 'Back',
                    ),
                  ),

                if (showLogo) ...[
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 10),
                    child: Image.asset(
                      'assets/images/ambalpady.png',
                      height: logoHeight,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, st) => Icon(
                        Icons.image_outlined,
                        size: logoHeight,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      semanticLabel: 'Ambalpady logo',
                    ),
                  ),
                ],

                // Title scales down gracefully if space is tight
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      effectiveTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                        color: titleColor ?? (isDark ? Colors.white : Colors.black87),
                        fontFamily: 'Poppins',
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Slightly taller to accommodate larger logo
  @override
  Size get preferredSize => const Size.fromHeight(72);
}
