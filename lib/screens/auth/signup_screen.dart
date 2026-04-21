import 'package:flutter/material.dart';
import '../../core/api_services.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import 'otp_verification_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  String selectedRole = "customer";

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool _isPasswordVisible = false;

  void handleSignup() async {
    String username = usernameController.text.trim();
    String email = emailController.text.trim().toLowerCase();
    String phone = phoneController.text.trim();
    String password = passwordController.text.trim();
    String formattedUsername = username.replaceAll(' ', '_').toLowerCase();

    // 1. Empty Field Check
    if (username.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      _showMessage("Please fill all fields");
      return;
    }

    // 2. Strict Email Validation (Wahi Regex jo pehle banaya tha)
    String emailPattern = r"^[a-zA-Z0-9.]+@(gmail|yahoo|outlook|vastrafix|hotmail)\.(com|in|net|org|co\.in)$";
    RegExp regExp = RegExp(emailPattern);
    if (!regExp.hasMatch(email)) {
      _showMessage("Enter a valid email (e.g. name@gmail.com)");
      return;
    }

    // 3. Phone Number Validation (Exactly 10 digits)
    if (phone.length != 10) {
      _showMessage("Phone number must be exactly 10 digits");
      return;
    }

    // 4. Password Length Check
    if (password.length < 6) {
      _showMessage("Password must be at least 6 characters");
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await ApiService.signup(
        username: formattedUsername,
        email: email,
        phone: phone,
        password: password,
        role: selectedRole,
      );

      setState(() => isLoading = false);

      // 🔥 CHECK LOGIC: Django aksar error mein email ya phone key bhejta hai
      if (result.containsKey('id') || result.containsKey('message')) {
        _showMessage("Registration successful! Verify your email.", isError: false);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EmailOTPVerificationScreen(email: email)),
          );
        }
      }
      // 🚨 AGAR EMAIL ALREADY HAI: Django bhejega {"email": ["user with this email already exists."]}
      else if (result.containsKey('email')) {
        _showMessage("This email is already registered. Please login.");
      }
      else if (result.containsKey('username')) {
        _showMessage("Username already taken. Try another.");
      }
      else if (result.containsKey('phone')) {
        _showMessage("Phone number already in use.");
      }
      else {
        // Backup error message
        _showMessage(result['error'] ?? "Registration failed. Please try again.");
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showMessage("Server Connection Error");
    }
  }

  void _showMessage(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: isError ? AppTheme.navyDark : AppTheme.freshGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 NAYA ADD KIYA: isDark check
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // 🔥 FIX 1: Hardcoded hata ke Theme background use kiya
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          // 🔥 FIX 2: Dark mode me icon white hoga
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : AppTheme.navyDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      // 🔥 FIX 3: Dark mode logo container background
                      color: isDark ? Colors.white10 : AppTheme.primaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_add_alt_1_rounded, size: 50, color: AppTheme.primaryBlue),
                  ),
                  const SizedBox(height: 24),
                  Text(
                      "Create Account",
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppTheme.navyDark, // 🔥 FIX 4
                          letterSpacing: 0.5
                      )
                  ),
                  const SizedBox(height: 8),
                  const Text(
                      "Join VastraFix Premium Laundry",
                      style: TextStyle(
                          color: AppTheme.greyText,
                          fontSize: 14,
                          fontWeight: FontWeight.w500
                      )
                  ),
                  const SizedBox(height: 40),

                  // --- FORM SECTION ---
                  _buildThemedField(
                      usernameController,
                      "Full Name",
                      Icons.person_outline_rounded,
                      isDark: isDark // 🔥 FIX 5: Pass isDark
                  ),
                  const SizedBox(height: 16),
                  _buildThemedField(
                      emailController,
                      "Email Address",
                      Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      isDark: isDark
                  ),
                  const SizedBox(height: 16),
                  _buildThemedField(
                      phoneController,
                      "Phone Number",
                      Icons.phone_android_outlined,
                      keyboardType: TextInputType.phone,
                      isDark: isDark
                  ),
                  const SizedBox(height: 16),
                  _buildThemedField(
                      passwordController,
                      "Password",
                      Icons.lock_outline_rounded,
                      isPassword: true,
                      isDark: isDark
                  ),
                  const SizedBox(height: 35),

                  isLoading
                      ? const CircularProgressIndicator(color: AppTheme.primaryBlue)
                      : SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: handleSignup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.freshGreen,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.radiusMedium)
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                          "Sign Up",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: RichText(
                      text: const TextSpan(
                        text: "Already have an account? ",
                        style: TextStyle(color: AppTheme.greyText),
                        children: [
                          TextSpan(
                            text: "Login",
                            style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
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

  // ✅ UI Helper for Consistent Input Styling
  Widget _buildThemedField(
      TextEditingController controller,
      String hint,
      IconData icon,
      {bool isPassword = false,
        TextInputType keyboardType = TextInputType.text,
        required bool isDark}
      ) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? !_isPasswordVisible : false,
      keyboardType: keyboardType,
      // 🔥 NAYA: Phone number ke liye 10 digit limit
      maxLength: keyboardType == TextInputType.phone ? 10 : null,
      style: TextStyle(color: isDark ? Colors.white : AppTheme.navyDark, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        counterText: "", // Taaki niche 0/10 na dikhe
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.greyText, fontWeight: FontWeight.normal),
        prefixIcon: Icon(icon, color: AppTheme.primaryBlue, size: 22),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: AppTheme.greyText,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        )
            : null,
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white, // 🔥 FIX 7
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: BorderSide.none, // 🔹 Cleaner look in dark mode
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