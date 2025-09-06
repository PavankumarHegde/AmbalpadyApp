import 'package:ambalpady/Screens/AboutScreen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart'; // For launching URLs

// Assuming these paths are correct for your project
import '../../Config/Theme/AppTheme.dart';
import '../ComingSoonScreen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _areNotificationsEnabled = true;
  String _appVersion = '1.0.0'; // Example app version

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _areNotificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    try {
      if (value) {
        await FirebaseMessaging.instance.subscribeToTopic('topic');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('notificationsEnabled', true);
        setState(() => _areNotificationsEnabled = true);
        _showSnackBar('Subscribed for notifications (topic).');
      } else {
        await FirebaseMessaging.instance.unsubscribeFromTopic('topic');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('notificationsEnabled', false);
        setState(() => _areNotificationsEnabled = false);
        _showSnackBar('Unsubscribed from notifications (topic).');
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notificationsEnabled', value);
      setState(() => _areNotificationsEnabled = value);
    } catch (e) {
      _showSnackBar('Notification setting failed: $e', backgroundColor: Colors.red);
    }
  }


  void _showSnackBar(String message, {Color? backgroundColor, Color? textColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: textColor ?? Colors.white),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        backgroundColor: backgroundColor,
      ),
    );
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
      _showSnackBar('Could not open $url', backgroundColor: Colors.red);
    }
  }


  Future<void> _confirmDeleteAccount() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Account?'),
          content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _showSnackBar('Account deletion initiated (simulated).', backgroundColor: Colors.orange);
      // TODO: Call backend & navigate accordingly.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // General Settings
            _buildSectionHeader(context, 'General'),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              color: isDark ? Colors.grey.shade900 : Colors.white,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  // Dark Mode switch REMOVED

                  // Notifications switch
                  _buildSwitchTile(
                    context,
                    Icons.notifications_none_outlined,
                    'Notifications',
                    _areNotificationsEnabled,
                    _toggleNotifications,
                  ),

                  _buildDivider(isDark),

                  _buildTile(
                    context,
                    Icons.language_outlined,
                    'Language',
                    subtitle: 'English',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ComingSoonScreen()));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Legal & About
            _buildSectionHeader(context, 'Legal & About'),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              color: isDark ? Colors.grey.shade900 : Colors.white,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _buildTile(
                    context,
                    Icons.privacy_tip_outlined,
                    'Privacy Policy',
                    onTap: () => _launchURL('https://pavankumarhegde.com/ambalpady/privacy.html'), // Replace with actual URL
                  ),
                  _buildDivider(isDark),

                  // Refund Policy REMOVED

                  _buildTile(
                    context,
                    Icons.description_outlined,
                    'Terms of Service',
                    onTap: () => _launchURL('https://pavankumarhegde.com/ambalpady/terms.html'), // Replace with actual URL
                  ),
                  _buildDivider(isDark),
                  _buildTile(
                    context,
                    Icons.info_outline,
                    'App Version',
                    subtitle: _appVersion,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AboutScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Account Actions
            // _buildSectionHeader(context, 'Account Actions'),
            // Card(
            //   elevation: 2,
            //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            //   color: isDark ? Colors.grey.shade900 : Colors.white,
            //   margin: const EdgeInsets.symmetric(vertical: 8),
            //   child: _buildTile(
            //     context,
            //     Icons.delete_forever_outlined,
            //     'Delete Account',
            //     isDestructive: true,
            //     onTap: _confirmDeleteAccount,
            //   ),
            // ),
            // const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white70 : Colors.black54,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
      BuildContext context, IconData icon, String title, bool value, ValueChanged<bool> onChanged) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: isDark ? Colors.white : Colors.black87,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
      ),
      secondary: Icon(
        icon,
        size: 24,
        color: AppTheme.primaryRed,
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primaryRed,
      inactiveTrackColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
      inactiveThumbColor: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
    );
  }

  Widget _buildTile(
      BuildContext context,
      IconData icon,
      String title, {
        String? subtitle,
        bool isDestructive = false,
        required VoidCallback onTap,
      }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(
        icon,
        size: 24,
        color: isDestructive ? Colors.red.shade600 : AppTheme.primaryRed,
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: isDestructive ? Colors.red.shade600 : (isDark ? Colors.white : Colors.black87),
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: isDark ? Colors.white54 : Colors.black45,
          fontFamily: 'Poppins',
        ),
      )
          : null,
      trailing: isDestructive
          ? null
          : Icon(
        Icons.arrow_forward_ios_rounded,
        size: 18,
        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
      ),
      onTap: onTap,
      splashColor: AppTheme.primaryRed.withOpacity(0.1),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 0,
      thickness: 0.5,
      indent: 20,
      endIndent: 20,
      color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
    );
  }
}
