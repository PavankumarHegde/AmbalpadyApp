import 'package:flutter/material.dart';
import '../../Config/Theme/AppTheme.dart';
import '../ComingSoonScreen.dart';

class ProgramsScreen extends StatelessWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildProgramCard(
            context: context,
            theme: theme,
            isDark: isDark,
            title: "Project Management Essentials",
            subtitle:
            "Master core skills, methodologies (Agile, Waterfall, Hybrid), and tools like MS Project & ProjectCube.",
            details:
            "Includes training on:\n• Gantt charts & project documentation\n• Agile (Scrum, Kanban) & Traditional approaches\n• Soft skills: leadership, communication, time management",
          ),
          _buildProgramCard(
            context: context,
            theme: theme,
            isDark: isDark,
            title: "Product Management and New Innovation",
            subtitle:
            "Learn to define strategies, design user-centric products, and foster innovation.",
            details:
            "Includes:\n• Product lifecycle & go-to-market strategy\n• Innovation techniques & design thinking\n• User research, product roadmap & product testing"
            ,
          ),
        ],
      ),
    );
  }

  Widget _buildProgramCard({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required String title,
    required String subtitle,
    required String details,
  }) {
    final cardColor = isDark ? Colors.grey[850] : Colors.white;
    final titleColor = theme.textTheme.titleLarge?.color;
    final subtitleColor = isDark ? Colors.grey[300] : Colors.grey[800];

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      color: cardColor,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ComingSoonScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.school, color: AppTheme.primaryRed),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        fontFamily: 'Poppins',
                        color: titleColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: subtitleColor,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                details,
                style: TextStyle(
                  fontSize: 13,
                  color: subtitleColor,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Text(
                    "Learn More",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryRed,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.primaryRed),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
