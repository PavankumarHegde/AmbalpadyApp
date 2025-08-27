import 'package:ambalpady/Widgets/AppTitleBar.dart';
import 'package:flutter/material.dart';
import '../../Config/Theme/AppTheme.dart';

class ProgramsEventsScreen extends StatelessWidget {
  const ProgramsEventsScreen({super.key});

  final List<Map<String, String>> programs = const [
    {"program": "Innovation Center Membership", "event": ""},
    {"program": "Club-Ignite Membership", "event": ""},
    {"program": "PM Program", "event": "Mysore (26 July)"},
    {"program": "PM Program", "event": "Mysore (27 July)"},
    {"program": "Innovation Center Program", "event": "Ooty (2nd - 3rd August)"},
    {"program": "Innovation Center Program", "event": "Ooty (9th - 10th August)"},
    {"program": "Innovation Center Program", "event": "Coorg (16th - 17th August)"},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.grey[100];

    return Scaffold(
      appBar: const AppTitleBar(
        title: "Programs & Events",
        showBackArrow: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sprint 1',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: programs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = programs[index];
                  final program = item['program']!;
                  final event = item['event']!;
                  final isEvent = event.isNotEmpty;

                  return Container(
                    decoration: BoxDecoration(
                      color: isEvent
                          ? Colors.yellow.shade100
                          : backgroundColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
                        child: Icon(Icons.event, color: AppTheme.primaryRed),
                      ),
                      title: Text(
                        program,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isEvent ? Colors.black87 : textColor,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      subtitle: isEvent
                          ? Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          event,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      )
                          : null,
                    ),
                  );

                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
