import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../Config/Localization/AppLocalizations.dart';
import '../../Config/Theme/AppTheme.dart';
import '../../Widgets/AppTitleBar.dart';
import '../Dashboard/HomeScreen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final dobController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final referralCodeController = TextEditingController();

  bool isLoading = false;

  Future<void> registerUser() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final dob = dobController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    final referralCode = referralCodeController.text.trim();

    if ([name, email, phone, dob, password, confirmPassword].any((e) => e.isEmpty)) {
      showSnackBar("Please fill in all required fields");
      return;
    }

    if (password != confirmPassword) {
      showSnackBar("Passwords do not match");
      return;
    }

    setState(() => isLoading = true);

    final url = Uri.parse('https://pavankumarhegde.com/club-ignite/api/auth/register.php'); // Replace with your actual endpoint

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "name": name,
          "email": email,
          "phone": phone,
          "dob": dob,
          "password": password,
          "referred_by_code": referralCode,
        }),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = body['token'];
        final userCode = body['user_code'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('token', token);
        await prefs.setString('userCode', userCode);
        await prefs.setString('userEmail', email);
        await prefs.setString('userName', name);
        await prefs.setString('userPhone', phone);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        showSnackBar(body['message'] ?? "Registration failed");
      }
    } catch (e) {
      showSnackBar("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }


  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now().subtract(const Duration(days: 365 * 18));
    DateTime firstDate = DateTime(1900);
    DateTime lastDate = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const AppTitleBar(showBackArrow: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.08,
          vertical: screenHeight * 0.04,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              local.translate('createAccount'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),

            SizedBox(height: screenHeight * 0.06),

            _buildTextField(local.translate('name'), nameController, TextInputType.name, theme, isDark),
            SizedBox(height: screenHeight * 0.025),
            _buildTextField(local.translate('email'), emailController, TextInputType.emailAddress, theme, isDark),
            SizedBox(height: screenHeight * 0.025),
            _buildTextField(local.translate('phone'), phoneController, TextInputType.phone, theme, isDark),
            SizedBox(height: screenHeight * 0.025),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: _buildTextField(local.translate('dob'), dobController, TextInputType.datetime, theme, isDark),
              ),
            ),

            SizedBox(height: screenHeight * 0.025),
            _buildTextField(local.translate('password'), passwordController, TextInputType.visiblePassword, theme, isDark, obscure: true),
            SizedBox(height: screenHeight * 0.025),
            _buildTextField(local.translate('confirmPassword'), confirmPasswordController, TextInputType.visiblePassword, theme, isDark, obscure: true),
            SizedBox(height: screenHeight * 0.025),
            _buildTextField('Referral Code (Optional)', referralCodeController, TextInputType.text, theme, isDark),

            SizedBox(height: screenHeight * 0.04),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : registerUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text(
                  local.translate('register'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),

            SizedBox(height: screenHeight * 0.04),

            Center(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    children: [
                      TextSpan(text: "${local.translate('alreadyHaveAccount')} "),
                      const TextSpan(
                        text: 'Sign In',
                        style: TextStyle(
                          color: AppTheme.primaryRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller,
      TextInputType inputType,
      ThemeData theme,
      bool isDark, {
        bool obscure = false,
      }) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      obscureText: obscure,
      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.textTheme.bodyLarge?.color),
        filled: true,
        fillColor: isDark ? Colors.grey[850] : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}
