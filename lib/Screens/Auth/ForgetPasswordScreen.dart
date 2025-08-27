import 'package:flutter/material.dart';
import '../../Config/Localization/AppLocalizations.dart';
import '../../Config/Theme/AppTheme.dart';
import '../../Widgets/AppTitleBar.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final emailController = TextEditingController();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const AppTitleBar(
        showBackArrow: true,
        title: "Forgot Password",
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.08,
          vertical: screenHeight * 0.04,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header text
            Text(
              local.translate('forgotPasswordIntro'),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),

            SizedBox(height: screenHeight * 0.04),

            // Email input
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                labelText: local.translate('email'),
                labelStyle: TextStyle(color: theme.textTheme.bodyLarge?.color),
                filled: true,
                fillColor: isDark ? Colors.grey[850] : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),

            SizedBox(height: screenHeight * 0.05),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Add logic to send password reset email
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  local.translate('resetPassword'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
