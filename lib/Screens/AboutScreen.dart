import 'package:ambalpady/Widgets/AppTitleBar.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Config/Theme/AppTheme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppTitleBar(title: "About Club-Ignite"),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              "Ready to take your career to the next level? Welcome to Club-Ignite – where your learning journey never stops!",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              "Join a vibrant community of ambitious students, educators, and professionals who are serious about continuous growth and meaningful connections. Club-Ignite isn't just another networking app – it's your gateway to an entire ecosystem of career-accelerating resources.",
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),

            const SizedBox(height: 24),

            Text(
              "What's waiting for you inside:",
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 12),

            _buildBullet(
              "Exclusive Access",
              "Unlock premium tools including Project Cube software, CompetitionEdge platform, Innovation Center resources, Smart City initiatives, and My Financials – all in one place.",
              theme,
            ),
            _buildBullet(
              "Endless Learning",
              "Continue your education with cutting-edge resources and stay ahead of industry trends.",
              theme,
            ),
            _buildBullet(
              "Powerful Network",
              "Connect with like-minded professionals, mentors, and peers who share your drive for excellence.",
              theme,
            ),
            _buildBullet(
              "Career Growth",
              "Access tools and insights that give you a competitive edge in today's fast-paced market.",
              theme,
            ),

            const SizedBox(height: 24),

            Text(
              "The best part?",
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "If you've participated in our training programs, you get FREE membership – giving you instant access to this comprehensive professional development ecosystem.",
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),

            const SizedBox(height: 24),

            Text(
              "Don't let your learning end with a weekend workshop. Join Club-Ignite and become part of a community that's committed to your long-term success. Whether you're launching your career, switching industries, or climbing the corporate ladder, we've got the resources and connections you need.",
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),

            const SizedBox(height: 24),

            Text(
              "Ready to ignite your potential?",
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Your professional journey is just getting started.",
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),

            const SizedBox(height: 32),

      Center(
          child: ElevatedButton.icon(
          onPressed: () async {
    final url = Uri.parse('http://club-ignite.com/appdownload');

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Could not open browser')),
    );
    }
    },
      icon: const Icon(Icons.download),
      label: const Text("Download Club-Ignite"),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryRed,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    ),

    ],
        ),
      ),
    );
  }

  Widget _buildBullet(String title, String content, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 20, color: AppTheme.primaryRed),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                children: [
                  TextSpan(
                    text: "$title: ",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: content),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
