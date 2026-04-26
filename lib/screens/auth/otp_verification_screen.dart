import 'package:flutter/material.dart';
import 'dart:async';
import 'package:pinput/pinput.dart'; // Ensure: flutter pub add pinput
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
  int _start = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    _start = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() => timer.cancel());
      } else {
        setState(() => _start--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    otpController.dispose();
    super.dispose();
  }

  // 🔥 OTP Verify Logic
  void verifyOTP() async {
    String otp = otpController.text.trim();
    if (otp.length != 6) {
      _showMessage("Please enter 6-digit OTP");
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await ApiService.verifyEmailOTP(widget.email, otp);

      debugPrint("API RESPONSE: $result"); // Terminal mein check karo

      // ✅ SUCCESS CONDITION: success true ho ya message mein success likha ho
      if (result['success'] == true ||
          result['message'].toString().toLowerCase().contains("success")) {

        _showMessage("Verified Successfully!", isError: false);

        // Timer stop karo
        _timer?.cancel();

        if (mounted) {
          // Thoda delay taaki user ko green SnackBar dikhe
          Future.delayed(const Duration(milliseconds: 600), () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginCustomerScreen()),
                  (route) => false,
            );
          });
        }
      } else {
        // Backend ka error dikhao
        String error = "Invalid OTP";
        if (result['error'] is Map) {
          error = "Data already exists or invalid";
        } else {
          error = result['error']?.toString() ?? "Invalid OTP";
        }
        _showMessage(error);
      }
    } catch (e) {
      _showMessage("Connection error. Is your server running?");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // 🔥 Resend OTP Logic
  void handleResend() async {
    setState(() => isLoading = true);
    final result = await ApiService.resendOTP(widget.email);
    setState(() => isLoading = false);

    if (result['success'] == true) {
      _showMessage("New OTP sent to your email", isError: false);
      startTimer();
    } else {
      _showMessage(result['error'] ?? "Could not resend OTP");
    }
  }

  void _showMessage(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: isError ? AppTheme.navyDark : AppTheme.freshGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Premium Pin Decoration
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 60,
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.navyDark),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderGrey),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: AppTheme.primaryBlue, width: 2),
      ),
    );

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: const BackButton(color: AppTheme.navyDark)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.mark_email_read_outlined, size: 80, color: AppTheme.primaryBlue),
              const SizedBox(height: 24),
              const Text("Verify Email", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.navyDark)),
              const SizedBox(height: 10),
              Text(
                "OTP sent to ${widget.email}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.greyText, fontSize: 15),
              ),
              const SizedBox(height: 50),

              // 🔥 6-Digit Individual Boxes
              Pinput(
                length: 6,
                controller: otpController,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                hapticFeedbackType: HapticFeedbackType.lightImpact,
                onCompleted: (pin) => verifyOTP(), // Auto-submit when last digit entered
              ),

              const SizedBox(height: 50),

              isLoading
                  ? const CircularProgressIndicator(color: AppTheme.primaryBlue)
                  : SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: verifyOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: const Text("Verify & Proceed", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 30),

              // Timer & Resend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Didn't get the code? ", style: TextStyle(color: AppTheme.greyText)),
                  _start == 0
                      ? TextButton(
                    onPressed: handleResend,
                    child: const Text("Resend OTP", style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                  )
                      : Text("Resend in 00:$_start", style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}