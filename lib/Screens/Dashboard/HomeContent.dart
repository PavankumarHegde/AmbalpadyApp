import 'package:carousel_slider/carousel_slider.dart';
import 'package:ambalpady/Screens/Dashboard/CompititionScreen.dart';
import 'package:ambalpady/Screens/ProgramsEventsScreen.dart';
import 'package:flutter/material.dart';
import '../../Config/Theme/AppTheme.dart';
import '../AboutScreen.dart';
import '../Booking/BookMySeatScreen.dart';
import '../ComingSoonScreen.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final bannerImages = [
      'assets/images/banner1.jpg',
      'assets/images/banner3.png',
      'assets/images/banner2.png',
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔥 Banner slider
          CarouselSlider(
            options: CarouselOptions(
              height: screenHeight * 0.25,
              autoPlay: true,
              enlargeCenterPage: true,
              viewportFraction: 0.9,
              autoPlayInterval: const Duration(seconds: 4),
            ),
            items: bannerImages.map((imgPath) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  imgPath,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              );
            }).toList(),
          ),

          SizedBox(height: screenHeight * 0.03),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to ClubIgnite!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Explore learning, fun and innovation with our community programs.',
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
                ),
                SizedBox(height: screenHeight * 0.03),

                // Feature cards
                _buildCard(
                  context: context,
                  icon: Icons.event,
                  title: 'Programs & Events',
                  subtitle: 'Innovation, learning and travel programs',
                  color: Colors.deepPurpleAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProgramsEventsScreen()),
                    );
                  },
                ),

                _buildCard(
                  context: context,
                  icon: Icons.book_online,
                  title: 'Book Your Seat',
                  subtitle: 'Secure your spot with UPI payment',
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BookMySeatScreen()),
                    );
                  },
                ),
                _buildCard(
                  context: context,
                  icon: Icons.emoji_events_outlined, // A more relevant icon for competitions
                  title: 'Competition Edge',
                  subtitle: 'Showcase your innovation and win big prizes!',
                  color: AppTheme.primaryRed, // Using your app's primary color for consistency
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CompetitionScreen()),
                    );
                  },
                ),
                _buildCard(
                  context: context,
                  icon: Icons.lightbulb_outline,
                  title: 'Innovation Center',
                  subtitle: 'Register and explore creative projects',
                  color: Colors.orangeAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ComingSoonScreen()),
                    );
                  },
                ),
                _buildCard(
                  context: context,
                  icon: Icons.explore_outlined,
                  title: 'Travel & Activities',
                  subtitle: 'Waterfalls, adventure, and more fun!',
                  color: Colors.teal,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ComingSoonScreen()),
                    );
                  },
                ),
                _buildCard(
                  context: context,
                  icon: Icons.card_membership,
                  title: 'ClubIgnite Membership',
                  subtitle: 'Get access to exclusive features',
                  color: AppTheme.primaryRed,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ComingSoonScreen()),
                    );
                  },
                ),

                _buildCard(
                  context: context,
                  icon: Icons.info_outline,
                  title: 'About Club-Ignite',
                  subtitle: 'Learn what makes this platform unique',
                  color: Colors.indigoAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    );
                  },
                ),

              ],
            ),
          ),

          SizedBox(height: screenHeight * 0.04),
        ],
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        color: theme.cardColor,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: theme.iconTheme.color?.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
