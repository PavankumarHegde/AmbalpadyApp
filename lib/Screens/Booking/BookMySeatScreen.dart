import 'package:flutter/material.dart';

// Assuming this path is correct for your project
import '../../Config/Theme/AppTheme.dart';
import '../ComingSoonScreen.dart'; // Placeholder for booking confirmation screen

// --- Seat Data Model ---
class Seat {
  final String id;
  final int row;
  final int column;
  bool isBooked; // True if already booked by someone else
  bool isSelected; // True if currently selected by the user

  Seat({
    required this.id,
    required this.row,
    required this.column,
    this.isBooked = false,
    this.isSelected = false,
  });

  // Factory constructor for creating a Seat from a map (useful for API responses)
  factory Seat.fromJson(Map<String, dynamic> json) {
    return Seat(
      id: json['id'],
      row: json['row'],
      column: json['column'],
      isBooked: json['isBooked'] ?? false,
      isSelected: json['isSelected'] ?? false,
    );
  }

  // Convert Seat to a map (useful for saving to backend/local storage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'row': row,
      'column': column,
      'isBooked': isBooked,
      'isSelected': isSelected,
    };
  }
}

class BookMySeatScreen extends StatefulWidget {
  const BookMySeatScreen({super.key});

  @override
  State<BookMySeatScreen> createState() => _BookMySeatScreenState();
}

class _BookMySeatScreenState extends State<BookMySeatScreen> {
  // Simulate a bus layout: 5 rows, 4 columns (2+aisle+2)
  // Rows: A, B, C, D, E
  // Columns: 1, 2, (aisle), 3, 4
  final int _numRows = 5;
  final int _seatsPerRowSide = 2; // Seats on each side of the aisle
  final double _seatPrice = 250.0; // Price per seat

  List<Seat> _seats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBusSeats();
  }

  Future<void> _loadBusSeats() async {
    // Simulate fetching seat layout and availability from an API
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    List<Seat> loadedSeats = [];
    for (int r = 0; r < _numRows; r++) {
      for (int c = 0; c < _seatsPerRowSide * 2; c++) { // Total columns including aisle space
        // Skip the aisle column (e.g., between column 1 and 2 if 0-indexed)
        if (c == _seatsPerRowSide) {
          continue; // This represents the aisle space
        }

        String seatId = '${String.fromCharCode(65 + r)}${c < _seatsPerRowSide ? c + 1 : c}'; // A1, A2, B1, B2, etc.
        bool isBooked = (r == 0 && c == 0) || (r == 2 && c == 3) || (r == 4 && c == 1); // Simulate some booked seats

        loadedSeats.add(Seat(
          id: seatId,
          row: r,
          column: c,
          isBooked: isBooked,
        ));
      }
    }

    setState(() {
      _seats = loadedSeats;
      _isLoading = false;
    });
  }

  void _toggleSeatSelection(Seat seat) {
    if (seat.isBooked) {
      _showSnackBar('This seat is already booked.', backgroundColor: Colors.orange);
      return;
    }

    setState(() {
      seat.isSelected = !seat.isSelected;
    });
  }

  List<Seat> _getSelectedSeats() {
    return _seats.where((seat) => seat.isSelected).toList();
  }

  double _getTotalPrice() {
    return _getSelectedSeats().length * _seatPrice;
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

  void _proceedToBooking() {
    final selectedSeats = _getSelectedSeats();
    if (selectedSeats.isEmpty) {
      _showSnackBar('Please select at least one seat.', backgroundColor: Colors.red);
      return;
    }

    String seatList = selectedSeats.map((s) => s.id).join(', ');
    double totalPrice = _getTotalPrice();

    _showSnackBar('Booking seats: $seatList for ₹${totalPrice.toStringAsFixed(2)}', backgroundColor: Colors.green);

    // In a real app, you would navigate to a payment screen or confirmation page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComingSoonScreen(),
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
          'Book Your Seat',
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
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Driver's side
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 24.0, bottom: 20),
                      child: Icon(
                        Icons.drive_eta,
                        size: 40,
                        color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      ),
                    ),
                  ),
                  // Seat Layout
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                    ),
                    child: Column(
                      children: List.generate(_numRows, (rowIndex) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_seatsPerRowSide * 2 + 1, (colIndex) { // +1 for aisle
                              if (colIndex == _seatsPerRowSide) {
                                // This is the aisle
                                return SizedBox(width: 30); // Aisle width
                              }

                              // Adjust column index for actual seat data
                              final int actualColIndex = colIndex < _seatsPerRowSide ? colIndex : colIndex - 1;

                              // Find the seat for this position
                              Seat? currentSeat;
                              try {
                                currentSeat = _seats.firstWhere(
                                      (s) => s.row == rowIndex && s.column == actualColIndex,
                                );
                              } catch (e) {
                                // Seat not found, might be an empty space
                                return SizedBox(width: 40); // Placeholder for missing seat
                              }


                              return GestureDetector(
                                onTap: () => _toggleSeatSelection(currentSeat!),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: currentSeat.isBooked
                                        ? Colors.grey.shade600
                                        : (currentSeat.isSelected ? AppTheme.primaryRed : Colors.green.shade400),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: currentSeat.isBooked
                                          ? Colors.grey.shade700
                                          : (currentSeat.isSelected ? AppTheme.primaryRed : Colors.green.shade600),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      currentSeat.id,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: currentSeat.isBooked ? Colors.white70 : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Legend
                  _buildLegend(context, isDark),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Bottom Bar with Price and Button
          _buildBottomBar(context, isDark),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _legendItem(context, Colors.green.shade400, 'Available', isDark),
        _legendItem(context, AppTheme.primaryRed, 'Selected', isDark),
        _legendItem(context, Colors.grey.shade600, 'Booked', isDark),
      ],
    );
  }

  Widget _legendItem(BuildContext context, Color color, String text, bool isDark) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? Colors.white70 : Colors.black54,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final selectedSeats = _getSelectedSeats();
    final totalPrice = _getTotalPrice();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey.shade200).withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selected Seats:',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                selectedSeats.isEmpty ? 'None' : selectedSeats.map((s) => s.id).join(', '),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                  fontFamily: 'Poppins',
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Price:',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                '₹${totalPrice.toStringAsFixed(2)}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryRed,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _proceedToBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 5,
            ),
            child: Text(
              'Book ${selectedSeats.length} Seat${selectedSeats.length == 1 ? '' : 's'}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
