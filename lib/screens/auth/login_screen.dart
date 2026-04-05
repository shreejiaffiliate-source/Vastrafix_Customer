import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../core/api_services.dart';
import '../auth/signup_screen.dart';
import '../user/home_screen.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/auth_service.dart';

class LoginCustomerScreen extends StatefulWidget {
  const LoginCustomerScreen({super.key});

  @override
  State<LoginCustomerScreen> createState() => _LoginCustomerScreenState();
}

class _LoginCustomerScreenState extends State<LoginCustomerScreen> {
  final TextEditingController emailOrPhoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    emailOrPhoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool isEmail(String value) => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value);
  bool isPhone(String value) => RegExp(r'^[0-9]{10}$').hasMatch(value);

  void loginCustomer() async {
    String input = emailOrPhoneController.text.trim();
    String password = passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      _showMessage("All fields are required");
      return;
    }
    if (!isEmail(input) && !isPhone(input)) {
      _showMessage("Enter valid Email or 10-digit Phone");
      return;
    }
    if (password.length < 6) {
      _showMessage("Password must be at least 6 characters");
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await ApiService.login(input, password);

      if (result.containsKey('access')) {
        if (result['role'] != 'customer') {
          setState(() => isLoading = false);
          _showMessage("Only Customers can login here");
          return;
        }

        String token = result['access'];
        await ApiService.saveToken(token);

        try {
          String? fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null) {
            await ApiService.updateFCMToken(fcmToken);
          }
        } catch (fcmError) {
          print("FCM Token update failed: $fcmError");
        }

        setState(() => isLoading = false);

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const UserHomeScreen()),
                (route) => false,
          );
        }
      } else {
        setState(() => isLoading = false);
        _showMessage(result['error'] ?? result['detail'] ?? "Login Failed");
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showMessage("Connection error. Check your server.");
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.navyDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void handleGoogleLogin() async {
    setState(() => isLoading = true);
    try {
      final user = await AuthService().signInWithGoogle();

      if (user != null) {
        _showMessage("Google Login Successful: ${user.displayName}");
        await Future.delayed(const Duration(milliseconds: 300));

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const UserHomeScreen()),
                (route) => false,
          );
        }
      } else {
        _showMessage("Login Cancelled or Failed");
      }
    } catch (e) {
      _showMessage("Google Sign-In Failed");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 Theme detect kar rahe hain
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // 🔥 FIX 1: Hardcoded AppTheme.scaffoldBg hata diya, ab context se background color lega
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  Container(
                    height: 130,
                    width: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? AppTheme.navyDark : Colors.white, // 🔥 FIX 2
                      border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black26 : AppTheme.navyDark.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(65),
                      child: Image.asset(
                        "assets/images/logo.png",
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text(
                    "VastraFix",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppTheme.navyDark,
                      letterSpacing: 1,
                    ),
                  ),
                  const Text(
                    "Ironing & Laundry at Your Doorstep",
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 50),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.navyDark : Colors.white,
                      borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Welcome Back",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.navyDark,
                          ),
                        ),
                        const SizedBox(height: 30),

                        _buildUserIdField(
                          controller: emailOrPhoneController,
                          hint: "Email or Phone",
                          icon: Icons.alternate_email_rounded,
                          type: TextInputType.emailAddress,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),

                        _buildPasswordField(
                          controller: passwordController,
                          isDark: isDark,
                        ),

                        const SizedBox(height: 30),

                        isLoading
                            ? const CircularProgressIndicator(color: AppTheme.primaryBlue)
                            : SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: loginCustomer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.freshGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                              ),
                              elevation: 0,
                              minimumSize: const Size(0, 56),
                            ),
                            child: const Text(
                              "Login",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(child: Divider(color: isDark ? Colors.white10 : AppTheme.borderGrey)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text("OR", style: TextStyle(color: AppTheme.greyText, fontSize: 12)),
                      ),
                      Expanded(child: Divider(color: isDark ? Colors.white10 : AppTheme.borderGrey)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  isLoading
                      ? const SizedBox.shrink()
                      : SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : handleGoogleLogin,
                      icon: Image.asset(
                        'assets/images/google.png',
                        height: 24,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.login),
                      ),
                      label: Text(
                        "Continue with Google",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppTheme.navyDark
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isDark ? Colors.white24 : AppTheme.borderGrey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMedium)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: const TextStyle(color: AppTheme.greyText),
                        children: [
                          TextSpan(
                            text: "Sign Up",
                            style: TextStyle(
                              color: isDark ? Colors.white : AppTheme.primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserIdField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required TextInputType type,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: TextStyle(
          color: isDark ? Colors.white : AppTheme.navyDark,
          fontWeight: FontWeight.w500
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.greyText, fontWeight: FontWeight.normal),
        prefixIcon: Icon(icon, color: AppTheme.primaryBlue, size: 22),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white, // 🔥 FIX 3
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: BorderSide(color: isDark ? Colors.white10 : AppTheme.borderGrey, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      obscureText: _obscurePassword,
      keyboardType: TextInputType.visiblePassword,
      style: TextStyle(
          color: isDark ? Colors.white : AppTheme.navyDark,
          fontWeight: FontWeight.w500
      ),
      decoration: InputDecoration(
        hintText: "Password",
        hintStyle: const TextStyle(color: AppTheme.greyText, fontWeight: FontWeight.normal),
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryBlue, size: 22),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: AppTheme.greyText,
            size: 20,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white, // 🔥 FIX 4
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: BorderSide(color: isDark ? Colors.white10 : AppTheme.borderGrey, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }
}