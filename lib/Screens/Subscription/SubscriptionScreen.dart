import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:url_launcher/url_launcher.dart'; // For launching UPI apps

// Assuming these paths are correct for your project
import '../../Config/Theme/AppTheme.dart';
import '../ComingSoonScreen.dart'; // Example placeholder screen

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final TextEditingController _couponCodeController = TextEditingController();
  double _originalPrice = 500.0;
  double _currentPrice = 299.0; // Initial discounted price
  bool _isCouponApplied = false;
  String _couponMessage = '';

  // Define your valid coupon code and its discount amount
  final String _validCoupon = 'IGNITE20';
  final double _couponDiscountAmount = 50.0; // Example: 50 Rs off

  @override
  void dispose() {
    _couponCodeController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        backgroundColor: backgroundColor,
      ),
    );
  }

  void _applyCoupon() {
    String enteredCoupon = _couponCodeController.text.trim().toUpperCase();

    if (_isCouponApplied) {
      _showSnackBar('A coupon has already been applied!', backgroundColor: Colors.orange);
      return;
    }

    if (enteredCoupon == _validCoupon) {
      setState(() {
        _currentPrice -= _couponDiscountAmount;
        _isCouponApplied = true;
        _couponMessage = 'Coupon applied successfully! You saved ₹${_couponDiscountAmount.toStringAsFixed(2)}. New price: ₹${_currentPrice.toStringAsFixed(2)}';
      });
      _showSnackBar('Coupon applied successfully!', backgroundColor: Colors.green);
    } else {
      setState(() {
        _couponMessage = 'Invalid coupon code.';
      });
      _showSnackBar('Invalid coupon code.', backgroundColor: Colors.red);
    }
  }

  Future<void> _initiateUpiPayment() async {
    // Replace with your actual UPI details
    final String payeeVPA = 'your_upi_id@bank'; // e.g., 'johndoe@ybl'
    final String payeeName = 'Club Ignite';
    final String transactionNote = 'Premium Subscription for Club Ignite';

    // Construct the UPI deep link
    final String upiUrl = 'upi://pay?'
        'pa=$payeeVPA&'
        'pn=${Uri.encodeComponent(payeeName)}&'
        'am=${_currentPrice.toStringAsFixed(2)}&'
        'cu=INR&'
        'tn=${Uri.encodeComponent(transactionNote)}';

    final Uri uri = Uri.parse(upiUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showSnackBar(
        'Could not launch UPI app. Please ensure a UPI app is installed.',
        backgroundColor: Colors.red,
      );
      // Optionally, provide a fallback like showing the UPI ID to copy
      // _showSnackBar('Please copy UPI ID: $payeeVPA and pay manually.', backgroundColor: Colors.orange);
      // Clipboard.setData(ClipboardData(text: payeeVPA)); // To copy UPI ID
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
          'Premium Subscription',
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
            // Subscription Offer Card
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
                      'Unlock Premium Features',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryRed,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Enjoy an ad-free experience, exclusive content, and priority support.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Original Price:',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark ? Colors.white54 : Colors.black45,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            Text(
                              '₹${_originalPrice.toStringAsFixed(2)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: isDark ? Colors.white54 : Colors.black45,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Your Price:',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '₹${_currentPrice.toStringAsFixed(2)}',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryRed,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Coupon Code Section
            Text(
              'Have a coupon code?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponCodeController,
                    decoration: InputDecoration(
                      hintText: 'Enter coupon code',
                      hintStyle: TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.primaryRed, width: 2),
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isDark ? Colors.white : Colors.black87,
                      fontFamily: 'Poppins',
                    ),
                    textCapitalization: TextCapitalization.characters, // For coupon codes
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isCouponApplied ? null : _applyCoupon, // Disable if already applied
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isCouponApplied ? Colors.grey : AppTheme.primaryRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                  ),
                  child: Text(
                    _isCouponApplied ? 'Applied' : 'Apply',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
            if (_couponMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _couponMessage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _couponMessage.contains('successfully') ? Colors.green : Colors.red,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),

            const SizedBox(height: 40),

            // Proceed to Payment Button
            ElevatedButton.icon(
              icon: const Icon(Icons.payment, size: 24),
              label: Text(
                'Pay ₹${_currentPrice.toStringAsFixed(2)} via UPI',
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
              onPressed: _initiateUpiPayment,
            ),
            const SizedBox(height: 20),
            Text(
              'By proceeding, you agree to our Terms of Service.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white54 : Colors.black45,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
