import 'package:flutter/material.dart';
import '../../Widgets/AppTitleBar.dart';
import '../../Widgets/BottomMenu.dart';
import 'HomeContent.dart';
import 'NotificationsScreen.dart';
import 'MoreScreen.dart';
import 'FestivalCalendarScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeContent(),        // Placeholder for home dashboard
    const FestivalCalendarScreen(),
    const NotificationsScreen(),
    const MoreScreen(),
  ];

  void _onNavTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTitleBar(

        showBackArrow: false,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomMenu(
        currentIndex: _currentIndex,
        onTap: _onNavTapped,
      ),
    );
  }
}