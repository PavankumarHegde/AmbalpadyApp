import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For loading user data
import 'package:intl/intl.dart'; // For date formatting, add to pubspec.yaml if not present

// Assuming these paths are correct for your project
import '../../Config/Theme/AppTheme.dart';
import '../ComingSoonScreen.dart';
import '../Subscription/SubscriptionScreen.dart'; // Placeholder for other screens

class MembershipDetailsScreen extends StatefulWidget {
  const MembershipDetailsScreen({super.key});

  @override
  State<MembershipDetailsScreen> createState() => _MembershipDetailsScreenState();
}

class _MembershipDetailsScreenState extends State<MembershipDetailsScreen> {
  String _membershipTier = 'Standard'; // Default or loaded
  String _membershipId = 'N/A';
  DateTime? _renewalDate;
  List<String> _benefits = [];

  @override
  void initState() {
    super.initState();
    _loadMembershipData();
  }

  Future<void> _loadMembershipData() async {
    // In a real app, this data would come from an API call
    // or a local database after user authentication.
    // For demonstration, we'll use SharedPreferences or dummy data.
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _membershipTier = prefs.getString('membershipTier') ?? 'Standard';
      _membershipId = prefs.getString('membershipId') ?? 'MEM-XYZ-7890';
      String? renewalDateStr = prefs.getString('renewalDate');
      if (renewalDateStr != null) {
        try {
          _renewalDate = DateTime.parse(renewalDateStr);
        } catch (e) {
          _renewalDate = null; // Handle parsing errors
        }
      } else {
        // Default renewal date for demonstration
        _renewalDate = DateTime.now().add(const Duration(days: 30));
      }

      // Populate benefits based on tier
      if (_membershipTier == 'Premium') {
        _benefits = [
          'Ad-free experience',
          'Exclusive content access',
          'Priority customer support',
          'Early access to new features',
          'Monthly premium rewards',
        ];
      } else {
        _benefits = [
          'Standard content access',
          'Basic customer support',
        ];
      }
    });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String formattedRenewalDate = _renewalDate != null
        ? DateFormat('MMM dd, yyyy').format(_renewalDate!)
        : 'N/A';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Membership Details',
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Membership Summary Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: isDark ? Colors.grey.shade900 : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Membership Tier',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _membershipTier,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryRed,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      context,
                      Icons.card_membership,
                      'Membership ID:',
                      _membershipId,
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      context,
                      Icons.calendar_today_outlined,
                      'Renewal Date:',
                      formattedRenewalDate,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Membership Benefits Section
            Text(
              'Benefits',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              color: isDark ? Colors.grey.shade900 : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _benefits.map((benefit) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle_outline, size: 20, color: AppTheme.primaryRed),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              benefit,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Call to Action Button (e.g., Upgrade/Manage)
            ElevatedButton.icon(
              icon: Icon(_membershipTier == 'Premium' ? Icons.settings_outlined : Icons.upgrade, size: 24),
              label: Text(
                _membershipTier == 'Premium' ? 'Manage Subscription' : 'Upgrade Membership',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 6,
              ),
              onPressed: () {
                // Navigate to subscription screen for upgrade/management
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 20, color: isDark ? Colors.white54 : Colors.black45),
        const SizedBox(width: 10),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? Colors.white70 : Colors.black54,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white : Colors.black87,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
