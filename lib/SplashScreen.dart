// lib/SplashScreen.dart
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'Config/Theme/AppTheme.dart';
import 'Screens/Auth/LoginScreen.dart';
import 'Screens/Dashboard/HomeScreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final Animation<double> _logoAnimation;

  late final AnimationController _developerController;
  late final Animation<Offset> _developerOffset;

  bool _subscribed = false;

  @override
  void initState() {
    super.initState();

    // Status bar to match brand
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppTheme.primaryRed,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // Animations
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );

    _developerController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _developerOffset = Tween<Offset>(
      begin: const Offset(0.0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _developerController, curve: Curves.easeOut),
    );

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 550), () {
      if (mounted) _developerController.forward();
    });

    _boot();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache logo for smooth show
    precacheImage(const AssetImage('assets/images/ambalpady.png'), context);
  }

  Future<void> _boot() async {
    // 1) Ask to enable notifications → request permission → subscribe → show “Subscribed”
    await _ensureNotificationsThenProceed();

    // 2) Continue with update → login flow
    await checkForUpdate();
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    try {
      // Try external browser first
      final extOk = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (extOk) return;

      // Fallback to Chrome Custom Tabs / SFSafariViewController
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } catch (e) {
    }
  }

  Future<void> _ensureNotificationsThenProceed() async {
    final prefs = await SharedPreferences.getInstance();
    const promptedKey = 'notif_permission_prompted_v1';

    final granted = await _isNotificationsAuthorized();
    final subscribed = await _isAlreadySubscribed();

    if (granted && subscribed) {
      setState(() => _subscribed = true);
      return;
    }

    // Gate dialog
    final proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Enable Notifications'),
        content: const Text(
          'Enable notifications to receive important updates and alerts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Skip
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true), // Enable
            child: const Text('Enable'),
          ),
        ],
      ),
    );

    await prefs.setBool(promptedKey, true);

    if (proceed == true) {
      // Runtime permission (Android 13+/iOS/macOS/web)
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (!_authorizationGranted(settings)) {
        // Offer one retry
        if (!mounted) return;
        final retry = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text(
              'Notifications are disabled. You can enable them in Settings or retry.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Continue without'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
        if (retry == true) {
          final s2 = await FirebaseMessaging.instance.requestPermission();
          if (!_authorizationGranted(s2)) return;
        } else {
          return;
        }
      }

      // Authorized → subscribe (first time only)
      await _subscribeTopicsIfNeeded(['topic', 'default', 'all', 'appupdate']);


      if (!mounted) return;
      setState(() => _subscribed = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscribed to notifications')),
      );
    }
  }

  bool _authorizationGranted(NotificationSettings s) {
    return s.authorizationStatus == AuthorizationStatus.authorized ||
        s.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<bool> _isNotificationsAuthorized() async {
    try {
      final s = await FirebaseMessaging.instance.getNotificationSettings();
      return _authorizationGranted(s);
    } catch (_) {
      return false;
    }
  }

  Future<bool> _isAlreadySubscribed() async {
    final prefs = await SharedPreferences.getInstance();
    // consider user "already subscribed" if *any one* of the per-topic flags is set
    final topics = ['topic', 'default', 'all', 'appupdate'];
    for (final t in topics) {
      if (prefs.getBool('fcm_topic_subscribed_$t') == true) {
        return true;
      }
    }
    return false;
  }


  Future<void> _subscribeToTopicIfNeeded({required String topic}) async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'fcm_topic_subscribed';
    final already = prefs.getBool(key) ?? false;
    if (already) return;

    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      await prefs.setBool(key, true);
    } catch (e) {
      debugPrint('FCM subscribe failed: $e');
    }
  }


  Future<void> _subscribeTopicsIfNeeded(List<String> topics) async {
    final prefs = await SharedPreferences.getInstance();
    for (final t in topics) {
      final key = 'fcm_topic_subscribed_$t';
      final already = prefs.getBool(key) ?? false;
      if (already) continue;
      try {
        await FirebaseMessaging.instance.subscribeToTopic(t);
        await prefs.setBool(key, true);
      } catch (e) {
        debugPrint('FCM subscribe($t) failed: $e');
      }
    }
  }


  // ===== Update → Login flow =====
  Future<void> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final packageName = packageInfo.packageName;

      final resp = await http.get(
        Uri.parse("https://pavankumarhegde.com/RUST/api/check_update.php"),
      );
      if (resp.statusCode == 200) {
        final map = jsonDecode(resp.body) as Map<String, dynamic>;

        // Accept both old/new shapes
        final latestVersion =
        (map['version'] ?? map['current_version'])?.toString();
        final forceUpdate = (map['force_update'] == true) ||
            (map['update_mandatory'] == true);
        final updateAvailable = (map['update_available'] == true);

        String? storeUrl;

// Prefer API-provided link if present
        if (Platform.isIOS) {
          storeUrl = (map['ios_url'] ?? map['store_url'])?.toString();
          // fallback App Store link if missing
          storeUrl ??= "https://apps.apple.com/app/idYOUR_APP_ID";
        } else {
          storeUrl = (map['android_url'] ?? map['store_url'])?.toString();
          // fallback Play Store link if missing
          storeUrl ??= "https://play.google.com/store/apps/details?id=$packageName";
        }


        if (latestVersion != null &&
            _compareVersions(currentVersion, latestVersion) < 0) {
          if (forceUpdate && storeUrl != null && storeUrl.isNotEmpty) {
            // NEW: subscribe to the two topics on forced update
            await _subscribeTopicsIfNeeded(['default', 'ambalpady']);

            if (!mounted) return;
            await _showUpdateDialog(storeUrl: storeUrl, mandatory: true);
            return; // stop flow until the user updates
          } else if (updateAvailable && storeUrl != null && storeUrl.isNotEmpty) {
            if (!mounted) return;
            final go = await _showUpdateDialog(storeUrl: storeUrl, mandatory: false);
            if (go == true) return; // user chose to update
          }
        }

      }
    } catch (_) {
      // ignore and continue
    }

    await checkLoginStatus();
  }

  /// Returns negative if a<b, 0 if equal, positive if a>b
  int _compareVersions(String a, String b) {
    List<int> parse(String v) => v
        .split('.')
        .map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
    final aa = parse(a);
    final bb = parse(b);
    final len = (aa.length > bb.length) ? aa.length : bb.length;
    for (int i = 0; i < len; i++) {
      final x = i < aa.length ? aa[i] : 0;
      final y = i < bb.length ? bb[i] : 0;
      if (x != y) return x - y;
    }
    return 0;
  }

  Future<bool?> _showUpdateDialog({
    required String storeUrl,
    required bool mandatory,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: !mandatory,
      builder: (_) => AlertDialog(
        title: Text(mandatory ? 'Update Required' : 'Update Available'),
        content: Text(
          mandatory
              ? 'Please update the app to continue.'
              : 'A new version is available. Would you like to update now?',
        ),
        actions: [
          if (!mandatory)
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Later'),
            ),
          FilledButton(
            onPressed: () async {
              String url = (storeUrl).trim();

              // If API returned nothing or just root domain, fallback to store link
              if (url.isEmpty || url == "https://pavankumarhegde.com/ambalpady/update.html") {
                final packageInfo = await PackageInfo.fromPlatform();
                final packageName = packageInfo.packageName;
                url = Platform.isIOS
                    ? "https://apps.apple.com/app/idYOUR_APP_ID"
                    : "https://play.google.com/store/apps/details?id=$packageName";
              }

              try {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  debugPrint("Could not launch update URL: $url");
                }
              } catch (e) {
                debugPrint("Launch failed: $e");
              }

              Navigator.of(context).pop(true);
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
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
              final uri = Uri.parse(storeUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
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

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => isLoggedIn ? const HomeScreen() : HomeScreen(),
      ),
    );
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
      body: SafeArea(
        child: Column(
          children: [
            // Centered logo + trust line
            Expanded(
              child: Center(
                child: ScaleTransition(
                  scale: _logoAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo image
                      Image.asset(
                        'assets/images/ambalpady.png',
                        width: MediaQuery.of(context).size.width * 0.5,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 12),
                      // Trust text
                      Text(
                        'Ambalpady Nayak Trust (R)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Subscribed badge (after successful permission + subscribe)
            if (_subscribed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Chip(
                  label: const Text('Notifications: Subscribed'),
                  avatar: const Icon(Icons.check_circle),
                  backgroundColor: Colors.green.withOpacity(0.15),
                ),
              ),

            // Developer credit
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
      ),
    );
  }
}
