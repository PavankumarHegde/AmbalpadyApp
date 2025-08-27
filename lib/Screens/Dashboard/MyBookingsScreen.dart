import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date and time formatting

// Assuming these paths are correct for your project
import '../../Config/Theme/AppTheme.dart';
import '../ComingSoonScreen.dart'; // Placeholder for detailed booking screen

// --- Booking Data Model ---
class Booking {
  final String id;
  final String type; // e.g., 'Event', 'Bus'
  final String title;
  final String? subtitle; // e.g., Event organizer, Bus route
  final DateTime dateTime;
  final String location;
  final String status; // e.g., 'Confirmed', 'Pending', 'Cancelled'
  final String? busNumber;
  final List<String>? seatNumbers; // List of seat numbers
  final String? eventCategory; // e.g., 'Concert', 'Workshop'

  Booking({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    required this.dateTime,
    required this.location,
    this.status = 'Confirmed',
    this.busNumber,
    this.seatNumbers,
    this.eventCategory,
  });
}

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  List<Booking> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    // Simulate fetching bookings from an API or local storage
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    setState(() {
      _bookings = [
        Booking(
          id: 'EVT001',
          type: 'Event',
          title: 'Annual Tech Summit 2024 - A very long title to test overflow handling in the UI',
          subtitle: 'Global Innovators Inc. - The leading force in technology',
          dateTime: DateTime.now().add(const Duration(days: 7, hours: 10)),
          location: 'Convention Center, City Hall, 123 Main Street, Anytown, State, Country, 12345',
          eventCategory: 'Conference',
          status: 'Confirmed',
        ),
        Booking(
          id: 'BUS001',
          type: 'Bus',
          title: 'Bangalore to Chennai Express Service',
          subtitle: 'Luxury Sleeper with AC and Wi-Fi',
          dateTime: DateTime.now().add(const Duration(days: 2, hours: 20)),
          location: 'Majestic Bus Stand, Platform 5, Near Railway Station, Bangalore',
          busNumber: 'KA-01-AB-1234',
          seatNumbers: ['A1', 'A2', 'B3', 'C4', 'D5', 'E6'],
          status: 'Confirmed',
        ),
        Booking(
          id: 'EVT002',
          type: 'Event',
          title: 'Live Music Night Featuring Local Bands and Guest Artists',
          subtitle: 'The Jazz Club - An evening of soulful melodies',
          dateTime: DateTime.now().add(const Duration(days: 15, hours: 21)),
          location: 'Downtown Arena, 456 Oak Avenue, Metropolis',
          eventCategory: 'Concert',
          status: 'Confirmed',
        ),
        Booking(
          id: 'BUS002',
          type: 'Bus',
          title: 'Chennai to Hyderabad Overnight Journey',
          subtitle: 'Volvo Multi-Axle Semi-Sleeper',
          dateTime: DateTime.now().add(const Duration(days: 5, hours: 18)),
          location: 'CMBT Bus Terminal, Koyambedu, Chennai',
          busNumber: 'TN-02-CD-5678',
          seatNumbers: ['C5'],
          status: 'Pending',
        ),
        Booking(
          id: 'EVT003',
          type: 'Event',
          title: 'Startup Pitch Fest and Networking Event for Aspiring Entrepreneurs',
          subtitle: 'Innovation Hub - Connecting ideas with investors',
          dateTime: DateTime.now().add(const Duration(days: 20, hours: 14)),
          location: 'Tech Park Auditorium, Building 7, Silicon Valley East',
          eventCategory: 'Workshop',
          status: 'Cancelled',
        ),
      ];
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'My Bookings',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed))
          : _bookings.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note_outlined, size: 80, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No bookings found.',
              style: theme.textTheme.titleMedium?.copyWith(
                color: isDark ? Colors.white54 : Colors.black45,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Looks like you haven\'t booked anything yet!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white38 : Colors.black26,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _bookings.length,
        itemBuilder: (context, index) {
          final booking = _bookings[index];
          return _buildBookingCard(context, booking);
        },
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Booking booking) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color statusColor;
    IconData statusIcon;
    switch (booking.status) {
      case 'Confirmed':
        statusColor = Colors.green.shade600;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'Pending':
        statusColor = Colors.orange.shade600;
        statusIcon = Icons.pending_actions;
        break;
      case 'Cancelled':
        statusColor = Colors.red.shade600;
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = Colors.grey.shade600;
        statusIcon = Icons.info_outline;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? Colors.grey.shade900 : Colors.white,
      child: InkWell(
        onTap: () {
          _showSnackBar('Viewing details for Booking ID: ${booking.id}');
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ComingSoonScreen()));
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded( // Wrap the main content column with Expanded
                    child: Row(
                      children: [
                        Icon(
                          booking.type == 'Event' ? Icons.event : Icons.directions_bus,
                          color: AppTheme.primaryRed,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded( // Wrap the text column with Expanded
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.title,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontFamily: 'Poppins',
                                ),
                                overflow: TextOverflow.ellipsis, // Handle overflow
                                maxLines: 2, // Allow up to 2 lines for title
                              ),
                              if (booking.subtitle != null)
                                Text(
                                  booking.subtitle!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isDark ? Colors.white70 : Colors.black54,
                                    fontFamily: 'Poppins',
                                  ),
                                  overflow: TextOverflow.ellipsis, // Handle overflow
                                  maxLines: 1, // Allow up to 1 line for subtitle
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8), // Add some space between text and status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          booking.status,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 0.5),
              _buildInfoRow(
                context,
                Icons.calendar_today_outlined,
                'Date:',
                DateFormat('MMM dd, yyyy').format(booking.dateTime),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                context,
                Icons.access_time,
                'Time:',
                DateFormat('hh:mm a').format(booking.dateTime),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                context,
                Icons.location_on_outlined,
                'Location:',
                booking.location,
              ),
              if (booking.busNumber != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  context,
                  Icons.bus_alert,
                  'Bus No:',
                  booking.busNumber!,
                ),
              ],
              if (booking.seatNumbers != null && booking.seatNumbers!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  context,
                  Icons.airline_seat_recline_normal,
                  'Seats:',
                  booking.seatNumbers!.join(', '),
                ),
              ],
              if (booking.eventCategory != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  context,
                  Icons.category_outlined,
                  'Category:',
                  booking.eventCategory!,
                ),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  'Booking ID: ${booking.id}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark ? Colors.white38 : Colors.black26,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: isDark ? Colors.grey.shade600 : Colors.grey.shade500),
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
        Expanded( // Wrap the value text with Expanded
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white : Colors.black87,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis, // Handle overflow
            maxLines: 1, // Ensure it stays on one line
          ),
        ),
      ],
    );
  }
}
