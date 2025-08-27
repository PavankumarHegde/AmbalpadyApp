import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart'; // For launching URLs

// Assuming these paths are correct for your project
import '../../Config/Theme/AppTheme.dart';
import '../ComingSoonScreen.dart'; // Placeholder for screens not yet implemented
// Removed: import '../../Utils/theme_notifier.dart'; // No longer using global theme notifier

class SettingsScreen extends StatefulWidget {
  // No parameters needed as theme changes are now handled locally or by external mechanisms.
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _areNotificationsEnabled = true;
  String _appVersion = '1.0.0'; // Example app version

  @override
  void initState() {
    super.initState();
    _loadSettings();
    // Removed: themeModeNotifier.addListener(_updateThemeToggle); // No longer listening to global notifier
  }

  @override
  void dispose() {
    // Removed: themeModeNotifier.removeListener(_updateThemeToggle); // No longer listening to global notifier
    super.dispose();
  }

  // Removed: _updateThemeToggle() method as it relied on themeModeNotifier

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Load dark mode preference directly from SharedPreferences.
      // The app's root widget (e.g., MaterialApp) will need to read this
      // preference on its own to apply the theme globally.
      _isDarkMode = prefs.getBool('isDarkMode') ?? false; // Default to false (light mode) if not set
      _areNotificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      // In a real app, you'd fetch the actual app version from package_info_plus or similar
    });
  }

  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = value; // Update local state for the switch
    });
    // Save the preference to SharedPreferences.
    // Your MaterialApp will need to read this to apply the theme.
    await prefs.setBool('isDarkMode', value);
    _showSnackBar('Theme changed to ${value ? 'Dark' : 'Light'} mode.');
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _areNotificationsEnabled = value;
    });
    await prefs.setBool('notificationsEnabled', value);
    _showSnackBar('Notifications ${value ? 'enabled' : 'disabled'}.');
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
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
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
      // Perform account deletion logic here
      _showSnackBar('Account deletion initiated (simulated).', backgroundColor: Colors.orange);
      // In a real app: call API, clear local data, navigate to login/onboarding
      // Example: await _authService.deleteUserAccount();
      // Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
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
          color: isDark ? Colors.white : Colors.black, // Back button color
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // General Settings Section
            _buildSectionHeader(context, 'General'),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              color: isDark ? Colors.grey.shade900 : Colors.white,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _buildSwitchTile(
                    context,
                    Icons.brightness_6_outlined,
                    'Dark Mode',
                    _isDarkMode,
                    _toggleTheme,
                  ),
                  _buildDivider(isDark),
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
                    subtitle: 'English', // Example subtitle
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ComingSoonScreen()));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Legal & About Section
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
                    onTap: () => _launchURL('https://www.example.com/privacy'), // Replace with actual URL
                  ),
                  _buildDivider(isDark),
                  _buildTile(
                    context,
                    Icons.currency_bitcoin_outlined,
                    'Refund Policy',
                    onTap: () => _launchURL('https://www.example.com/privacy'), // Replace with actual URL
                  ),
                  _buildDivider(isDark),
                  _buildTile(
                    context,
                    Icons.description_outlined,
                    'Terms of Service',
                    onTap: () => _launchURL('https://www.example.com/terms'), // Replace with actual URL
                  ),
                  _buildDivider(isDark),
                  _buildTile(
                    context,
                    Icons.info_outline,
                    'App Version',
                    subtitle: _appVersion,
                    onTap: () {
                      // Optionally show app info dialog
                      showAboutDialog(
                        context: context,
                        applicationName: 'Club Ignite',
                        applicationVersion: _appVersion,
                        applicationLegalese: '© 2023 Club Ignite. All rights reserved.',
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 15.0),
                            child: Text(
                              'Designed to enhance your club experience.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Account Actions Section
            _buildSectionHeader(context, 'Account Actions'),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              color: isDark ? Colors.grey.shade900 : Colors.white,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: _buildTile(
                context,
                Icons.delete_forever_outlined,
                'Delete Account',
                isDestructive: true,
                onTap: _confirmDeleteAccount,
              ),
            ),
            const SizedBox(height: 40),
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
        color: isDark ? AppTheme.primaryRed : AppTheme.primaryRed,
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primaryRed,
      inactiveTrackColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
      inactiveThumbColor: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
    );
  }

  Widget _buildTile(
      BuildContext context, IconData icon, String title, {String? subtitle, bool isDestructive = false, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(
        icon,
        size: 24,
        color: isDestructive ? Colors.red.shade600 : (isDark ? AppTheme.primaryRed : AppTheme.primaryRed),
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
          ? null // No arrow for destructive actions, handled by button in dialog
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
      indent: 20, // Align with list tile content
      endIndent: 20,
      color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
    );
  }
}
