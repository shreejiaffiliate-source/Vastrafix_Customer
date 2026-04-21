import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';

class CustomErrorScreen extends StatelessWidget {
  final IconData errorIcon; // 👈 NAYA: ImagePath ki jagah IconData le liya
  final String title;
  final String subtitle;
  final VoidCallback onTryAgain;

  const CustomErrorScreen({
    super.key,
    required this.errorIcon,
    required this.title,
    required this.subtitle,
    required this.onTryAgain,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.navyDark : AppTheme.scaffoldBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 🎨 Badiya sa Icon Design (Bina image ke)
              Container(
                height: 180,
                width: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.white.withOpacity(0.05) : AppTheme.primaryBlue.withOpacity(0.1),
                  border: Border.all(
                    color: isDark ? Colors.white10 : AppTheme.primaryBlue.withOpacity(0.2),
                    width: 4,
                  ),
                ),
                child: Center(
                  child: Icon(
                    errorIcon,
                    size: 80,
                    color: isDark ? Colors.white70 : AppTheme.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // 🔴 Main Error Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppTheme.navyDark,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),

              // 📝 Subtitle / Message
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.greyText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),

              // 🔄 Try Again Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: onTryAgain,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primaryBlue, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                    ),
                  ),
                  child: const Text(
                    "TRY AGAIN",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}