import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:url_launcher/url_launcher.dart'; // For launching email client

// Assuming these paths are correct for your project
import '../../Config/Theme/AppTheme.dart';
import '../ComingSoonScreen.dart'; // Placeholder for screens not yet implemented
// Removed: import '../../Widgets/MenuCard.dart'; // buildMenuCard is now defined locally

// --- Competition Data Model ---
class Competition {
  final String id;
  final String title;
  final String tagline;
  final String topic;
  final List<String> subtopics;
  final String prize;
  final String certificateInfo;
  final DateTime startDate;
  final DateTime endDate;
  final String contactEmail;

  Competition({
    required this.id,
    required this.title,
    required this.tagline,
    required this.topic,
    required this.subtopics,
    required this.prize,
    required this.certificateInfo,
    required this.startDate,
    required this.endDate,
    required this.contactEmail,
  });
}

class CompetitionScreen extends StatefulWidget {
  const CompetitionScreen({super.key});

  @override
  State<CompetitionScreen> createState() => _CompetitionScreenState();
}

class _CompetitionScreenState extends State<CompetitionScreen> {
  Competition? _currentCompetition; // Hold a single competition for the main display
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompetitionDetails();
  }

  Future<void> _loadCompetitionDetails() async {
    // Simulate fetching competition data from an API
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    setState(() {
      _currentCompetition = Competition(
        id: 'COMP001',
        title: 'My Invention – Open Competition to All Participant',
        tagline: 'Entry Free',
        topic: 'ANY THING RELATED TO SMART CITY CENTER',
        subtopics: [
          'Renewable Energy',
          'Next-Generation Networks',
          'Smart Buildings',
          'Smart Transport',
          'Smart Governance for Smart City Development',
          'Digital Technology in Public and Private Sectors',
          'Smart Factory Principles',
          'Research Paper Specific to Your Location',
          'Business Case Study Related to Industry 5.0',
          'Technology Improvements for Industry 5.0',
          'Human-Centric Services: Healthcare',
          'Human-Centric Services: Transport',
          'Human-Centric Services: Utilities that Adapt to Citizens\' Needs',
          'Sustainable Urban Infrastructure: Green Buildings',
          'Sustainable Urban Infrastructure: Solar-Powered Streetlights',
          'Sustainable Urban Infrastructure: Smart Water Systems',
          'Resilient Systems: Decentralized Energy',
          'Resilient Systems: Digital Twins for Emergency Response Planning',
        ],
        prize: '₹10,000 Cash Prize',
        certificateInfo: 'Medal Certificate for All Participant',
        startDate: DateTime(2025, 5, 20),
        endDate: DateTime(2025, 7, 21),
        contactEmail: 'info@competitionedge.org',
      );
      _isLoading = false;
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

  Future<void> _launchEmail(String email) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': Uri.encodeComponent('Query about Competition'),
      },
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      _showSnackBar('Could not launch email app. Please contact $email directly.', backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Competition Details',
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
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed)),
      );
    }

    if (_currentCompetition == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Competition Details',
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Competition details not found.',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isDark ? Colors.white54 : Colors.black45,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Determine if competition is active, upcoming, or ended
    final DateTime now = DateTime.now();
    Color statusColor;
    String statusText;
    if (now.isBefore(_currentCompetition!.startDate)) {
      statusText = 'Upcoming';
      statusColor = Colors.blue.shade400;
    } else if (now.isAfter(_currentCompetition!.endDate)) {
      statusText = 'Ended';
      statusColor = Colors.grey.shade600;
    } else {
      statusText = 'Active';
      statusColor = Colors.green.shade600;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Competition Details',
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
            // --- Main Competition Details Card ---
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: isDark ? Colors.grey.shade900 : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentCompetition!.title,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryRed,
                                  fontFamily: 'Poppins',
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                              Text(
                                _currentCompetition!.tagline,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isDark ? Colors.white70 : Colors.black54,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.emoji_events, size: 40, color: Colors.amber.shade600),
                      ],
                    ),
                    const Divider(height: 30, thickness: 0.5),
                    _buildInfoRow(
                      context,
                      Icons.topic_outlined,
                      'Main Topic:',
                      _currentCompetition!.topic,
                      isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      Icons.money,
                      'Prize:',
                      _currentCompetition!.prize,
                      isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      Icons.card_membership,
                      'Certificate:',
                      _currentCompetition!.certificateInfo,
                      isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      Icons.date_range,
                      'Start Date:',
                      DateFormat('MMM dd, yyyy').format(_currentCompetition!.startDate),
                      isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      Icons.calendar_today,
                      'Due Date:',
                      DateFormat('MMM dd, yyyy').format(_currentCompetition!.endDate),
                      isDark,
                      valueColor: statusColor, // Highlight due date based on status
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Status: $statusText',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.send_outlined, size: 20),
                      label: Text(
                        'Send Your Content to ${_currentCompetition!.contactEmail}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                      ),
                      onPressed: () => _launchEmail(_currentCompetition!.contactEmail),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // --- Topics Section ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Text(
                'Explore Topics',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Use ListView.builder for scrollable list of topics
            ListView.builder(
              shrinkWrap: true, // Important for nested scrollables
              physics: const NeverScrollableScrollPhysics(), // Disable internal scrolling
              itemCount: _currentCompetition!.subtopics.length,
              itemBuilder: (context, index) {
                final topic = _currentCompetition!.subtopics[index];
                return _buildMenuCard( // Using the local _buildMenuCard function
                  context: context,
                  icon: Icons.lightbulb_outline, // Generic icon for topics
                  title: topic,
                  subtitle: 'Explore this area for your invention.', // Generic subtitle
                  color: Colors.blueGrey, // A neutral color for topics
                  onTap: () {
                    _showSnackBar('Exploring topic: $topic');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ComingSoonScreen()),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, bool isDark, {Color? valueColor}) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: isDark ? Colors.grey.shade600 : Colors.grey.shade500),
        const SizedBox(width: 12),
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
              color: valueColor ?? (isDark ? Colors.white : Colors.black87),
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            maxLines: 2, // Allow value to wrap if needed
          ),
        ),
      ],
    );
  }

  // Moved _buildMenuCard definition here from a separate file
  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Consistent margin
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: isDark ? Colors.grey.shade900 : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                        fontFamily: 'Poppins',
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontFamily: 'Poppins',
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
