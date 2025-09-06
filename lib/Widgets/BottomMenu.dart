import 'package:flutter/material.dart';
import '../Config/Theme/AppTheme.dart';

class BottomMenu extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomMenu({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      elevation: 12,
      backgroundColor: theme.bottomNavigationBarTheme.backgroundColor ??
          (isDark ? AppTheme.darkTheme.scaffoldBackgroundColor : Colors.white),

      selectedItemColor: AppTheme.primaryRed,
      unselectedItemColor: isDark ? Colors.white70 : Colors.grey,

      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
      ),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w400,
        fontFamily: 'Poppins',
      ),

      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.event_note_outlined),
          label: 'Events',
        ),
        BottomNavigationBarItem(
          icon: Badge.count(
            count: 1,
            child: const Icon(Icons.notifications_none),
          ),
          activeIcon: Badge.count(
            count: 1,
            child: Icon(Icons.notifications),
          ),
          label: 'Notifications',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz),
          label: 'More',
        ),
      ],
    );
  }
}
