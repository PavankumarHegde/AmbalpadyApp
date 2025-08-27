import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Config/Theme/AppTheme.dart';
import 'Screens/Auth/LoginScreen.dart';
import 'Screens/Dashboard/HomeScreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoAnimation;

  late AnimationController _developerController;
  late Animation<Offset> _developerOffset;

  @override
  void initState() {
    super.initState();

    // Status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppTheme.primaryRed,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // Logo animation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );

    // Developer text animation
    _developerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _developerOffset = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _developerController,
      curve: Curves.easeOut,
    ));

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      _developerController.forward();
    });

    // Start update check
    checkForUpdate();
  }

  Future<void> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await http.get(
        Uri.parse("https://pavankumarhegde.com/club-ignite/api/check_update.php"),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final latestVersion = json['version'];
        final forceUpdate = json['force_update'] ?? false;
        final storeUrl = Theme.of(context).platform == TargetPlatform.iOS
            ? json['ios_url']
            : json['android_url'];

        if (latestVersion != currentVersion && forceUpdate == true) {
          showUpdateDialog(storeUrl);
        } else {
          checkLoginStatus();
        }
      } else {
        checkLoginStatus();
      }
    } catch (e) {
      checkLoginStatus();
    }
  }

  void showUpdateDialog(String storeUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Update Required"),
        content: const Text("Please update the app to continue."),
        actions: [
          TextButton(
            onPressed: () async {
              if (await canLaunchUrl(Uri.parse(storeUrl))) {
                await launchUrl(Uri.parse(storeUrl), mode: LaunchMode.externalApplication);
              }
            },
            child: const Text("Update Now"),
          ),
        ],
      ),
    );
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    Future.delayed(const Duration(seconds: 2), () {
      if (isLoggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _developerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: ScaleTransition(
                scale: _logoAnimation,
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 38,
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
            ),
          ),
          SlideTransition(
            position: _developerOffset,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Text(
                "Developed by Pavankumar Hegde",
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
        ],
      ),
    );
  }
}
