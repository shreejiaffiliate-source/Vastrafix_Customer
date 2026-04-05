import 'package:flutter/material.dart';
import '../orders/order_detail_screen.dart';
import '../user/home_screen.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';

class OrderSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderSuccessScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    // 🔹 Theme Status
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    const Color successGreen = AppTheme.freshGreen;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // ================= SUCCESS CARD =================
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: BoxDecoration(
                // 🔹 FIX: Card color according to theme
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Icon
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) =>
                        Transform.scale(scale: value, child: child),
                    child: Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: successGreen.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: successGreen.withOpacity(0.2), width: 2),
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: successGreen,
                        size: 70,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    "Order Confirmed!",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      // 🔹 FIX: Adaptive Color
                      color: isDark ? Colors.white : AppTheme.navyDark,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    "Your laundry request has been received successfully. Our partner will arrive at your doorstep as per the schedule.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.greyText,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome,
                            size: 16, color: AppTheme.primaryBlue),
                        SizedBox(width: 8),
                        Text(
                          "Awaiting Partner Pickup",
                          style: TextStyle(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // ================= BUTTONS =================
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Track Order Button
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          // Argument 1: Ye aapka naya Route hai
                          MaterialPageRoute(
                            builder: (context) => OrderDetailScreen(order: order),
                          ),
                          // Argument 2: Ye batata hai ki kitne purane pages delete karne hain
                              (route) => route.isFirst,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        // 🔹 FIX: Explicit minimum size to prevent row issues
                        minimumSize: const Size(0, 58),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Track My Order",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.location_searching_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Go Home Button
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const UserHomeScreen()),
                              (route) => false,
                        );
                      },
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                        ),
                      ),
                      child: Text(
                        "Back to Home",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          // 🔹 FIX: Adaptive Color
                          color: isDark ? Colors.white70 : AppTheme.navyDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}