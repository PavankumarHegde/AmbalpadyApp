import 'package:ambalpady/Screens/Auth/ChangePasswordScreen.dart';
import 'package:ambalpady/Screens/Membership/MembershipDetailsScreen.dart';
import 'package:ambalpady/Screens/Setting/SettingScreen.dart';
import 'package:ambalpady/Screens/Subscription/SubscriptionScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for Clipboard
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

// Assuming these paths are correct for your project
import '../../Config/Theme/AppTheme.dart';
import '../Auth/LoginScreen.dart';
import '../ComingSoonScreen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';
  String _userCode = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'Guest';
      _userEmail = prefs.getString('userEmail') ?? 'unknown@example.com';
      _userPhone = prefs.getString('userPhone') ?? '';
      _userCode = prefs.getString('userCode') ?? '';
    });
    // Add this line to see what's loaded
    print('Loaded User Name: $_userName');
    print('Loaded User Email: $_userEmail');
  }

  Future<void> _logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating, // For a more modern look
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16), // Margin from edges
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        // Optional: Add leading or actions if needed, e.g., a back button
        // leading: IconButton(
        //   icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white : Colors.black),
        //   onPressed: () => Navigator.of(context).pop(),
        // ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0), // Consistent padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24), // Spacing below app bar

            // Avatar
            CircleAvatar(
              radius: 50, // Slightly larger avatar
              backgroundColor: AppTheme.primaryRed.withOpacity(0.15), // Slightly more opaque
              child: Icon(
                Icons.person,
                size: 55, // Slightly larger icon
                color: AppTheme.primaryRed, // A bit darker red for contrast
              ),
            ),

            const SizedBox(height: 20), // Increased spacing

            // Name
            Text(
              _userName,
              textAlign: TextAlign.center, // Centers the text horizontally
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.blue : Colors.black87,
                fontFamily: 'Poppins',
                fontSize: 18, // Adjust this value to make the text smaller
              ),
            ),

            const SizedBox(height: 8),

            // Email
            Text(
              _userEmail,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : Colors.black54,
                fontFamily: 'Poppins',
              ),
            ),

            if (_userPhone.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                "📞 $_userPhone",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white54 : Colors.black45,
                  fontFamily: 'Poppins',
                ),
              ),
            ],

            if (_userCode.isNotEmpty) ...[
              const SizedBox(height: 30), // More spacing before code block
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade50, // More subtle background
                  borderRadius: BorderRadius.circular(16), // More rounded corners
                  border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200), // Lighter border
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.black : Colors.grey.shade200).withOpacity(0.5),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      "Your Unique Code", // More descriptive
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10), // Increased spacing
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible( // Ensure text wraps if too long
                          child: Text(
                            _userCode,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700, // Bolder
                              color: isDark ? AppTheme.primaryRed : AppTheme.primaryRed, // Use red for code
                              fontFamily: 'Poppins',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Tooltip( // Add tooltip for better UX
                          message: "Copy Code",
                          child: IconButton(
                            icon: Icon(Icons.copy, size: 22, color: isDark ? Colors.white70 : Colors.grey.shade700),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _userCode)).then((_) {
                                _showSnackBar("User code copied!");
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30), // Increased spacing

            SizedBox(
              width: screenWidth * 0.7, // Make the button slightly wider
              child: ElevatedButton.icon(
                icon: const Icon(Icons.share_outlined, size: 20),
                label: const Text(
                  "Invite Friends",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), // More vertical padding
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Slightly more rounded
                  elevation: 5, // Add a subtle shadow
                ),
                onPressed: () {
                  final link = "http://club-ignite.com/invite?code=$_userCode";
                  Share.share("Join me on this awesome app!\nUse my code: $_userCode\n$link");
                },
              ),
            ),

            const SizedBox(height: 40), // More spacing before tiles

            // Using Column for list of tiles for better organization
            Column(
              children: [
                _buildProfileTile(context, Icons.bookmark_outline, "My Bookings", onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
                }),
                _buildProfileTile(context, Icons.group, "Membership Details", onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MembershipDetailsScreen()));
                }),
                _buildProfileTile(context, Icons.lock_outline, "Change Password", onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
                }),
                _buildProfileTile(context, Icons.settings_outlined, "App Settings", onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen()));
                }),
              ],
            ),

            const SizedBox(height: 16), // Spacing before logout

            _buildProfileTile(context, Icons.logout, "Logout", isLogout: true, onTap: _logoutUser),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Renamed _buildTile to _buildProfileTile for clarity
  Widget _buildProfileTile(BuildContext context, IconData icon, String label,
      {bool isLogout = false, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8), // Increased vertical margin for separation
      elevation: 2, // Slightly more elevation
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), // More rounded
      color: isDark ? Colors.grey.shade900 : Colors.white, // Explicit card background
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), // More padding
        leading: Icon(
          icon,
          size: 24, // Slightly larger icon
          color: isLogout ? Colors.red.shade600 : (isDark ? AppTheme.primaryRed : AppTheme.primaryRed), // Consistent color with theme
        ),
        title: Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            color: isLogout ? Colors.red.shade600 : (isDark ? Colors.white : Colors.black87),
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 18, // Slightly larger arrow
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400, // Subtler arrow color
        ),
        onTap: onTap,
        splashColor: AppTheme.primaryRed.withOpacity(0.1), // Add a subtle splash effect
      ),
    );
  }
}