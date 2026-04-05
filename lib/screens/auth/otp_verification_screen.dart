import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/api_services.dart';
import '../../core/theme.dart';
import 'login_screen.dart';

class EmailOTPVerificationScreen extends StatefulWidget {
  final String email;

  const EmailOTPVerificationScreen({super.key, required this.email});

  @override
  State<EmailOTPVerificationScreen> createState() => _EmailOTPVerificationScreenState();
}

class _EmailOTPVerificationScreenState extends State<EmailOTPVerificationScreen> {
  final TextEditingController otpController = TextEditingController();
  bool isLoading = false;
  int _start = 30; // Timer 30 seconds ka
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    _start = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    otpController.dispose();
    super.dispose();
  }

  void verifyOTP() async {
    String otp = otpController.text.trim();

    // 🔥 Change: Django 6 digit OTP use kar raha hai
    if (otp.length != 6) {
      _showMessage("Please enter 6-digit OTP");
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await ApiService.verifyEmailOTP(widget.email, otp);

      if (result['success'] == true) {
        _showMessage("Email Verified! You can login now.", isError: false);

        await Future.delayed(const Duration(seconds: 1)); // Thoda wait taaki msg dikhe

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginCustomerScreen()),
                (route) => false,
          );
        }
      } else {
        _showMessage(result['error'] ?? "Invalid OTP");
      }
    } catch (e) {
      _showMessage("Verification failed. Try again.");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

// 🔥 Add: Resend OTP Logic
  void handleResend() async {
    setState(() => isLoading = true);
    final result = await ApiService.resendOTP(widget.email);
    setState(() => isLoading = false);

    if (result['success'] == true) {
      _showMessage("New OTP sent to ${widget.email}", isError: false);
      startTimer(); // Timer restart
    } else {
      _showMessage(result['error']);
    }
  }

  void _showMessage(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.navyDark : AppTheme.freshGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mark_email_read_outlined, size: 80, color: AppTheme.primaryBlue),
              const SizedBox(height: 24),
              const Text(
                "Verify Your Email",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.navyDark),
              ),
              const SizedBox(height: 10),
              Text(
                "We have sent an OTP to\n${widget.email}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.greyText),
              ),
              const SizedBox(height: 40),

              // OTP Input Field
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6, // Agar 6 digit ka OTP hai
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 10),
                decoration: InputDecoration(
                  counterText: "",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 30),

              isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: verifyOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Verify & Proceed", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),

              const SizedBox(height: 20),

              // Resend Timer Logic
              _start == 0
                  ? TextButton(
                onPressed: () {
                  // Resend OTP API call logic yahan aayega
                  handleResend();
                },
                child: const Text("Resend OTP", style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
              )
                  : Text("Resend OTP in 00:$_start", style: const TextStyle(color: AppTheme.greyText)),
            ],
          ),
        ),
      ),
    );
  }
}