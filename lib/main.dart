import 'package:flutter/material.dart';
import 'core/constants.dart';
import 'core/theme.dart';
// Screens
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/firebase_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/navigation_service.dart';
import 'screens/orders/order_detail_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Background message aagaya!: ${message.messageId}");

}

void main() async {
  // 1. Ensure bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase
  await Firebase.initializeApp();

  // 3. Register Background Message Handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 4. Initialize your Custom Firebase Service (FCM token, channels, etc.)
  await FirebaseService.initialize();

  runApp(const VastraFix());
}

class VastraFix extends StatelessWidget {
  const VastraFix({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔥 MASTER FIX: ValueListenableBuilder ensures theme changes reflect everywhere instantly
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          navigatorKey: navigatorKey, // 🔥 Ye line add karo
          debugShowCheckedModeBanner: false,
          title: AppConstants.appName,

          // --- 🎨 THEME SETTINGS (Adaptive) ---
          theme: AppTheme.vastraFixTheme, // Light Theme logic
          darkTheme: AppTheme.darkTheme,  // Dark Theme logic
          themeMode: currentMode,         // Toggle between Light/Dark

          initialRoute: '/splash',

          routes: {
            '/splash': (context) => const SplashScreen(),
            '/login': (context) => const LoginCustomerScreen(),
            '/signup': (context) => const SignupScreen(),
            // 🔥 NAYA SMART ROUTE
            '/order_detail': (context) {
              final args = ModalRoute.of(context)!.settings.arguments;

              if (args is Map<String, dynamic>) {
                // Agar normal click karke aaye hain, toh poora data bhej do
                return OrderDetailScreen(order: args);
              } else if (args is String) {
                // Agar notification se aaye hain, toh sirf ID ka ek chota Map bhej do
                return OrderDetailScreen(order: {"id": args});
              }
              // Fallback error screen
              return const Scaffold(body: Center(child: Text("Error Loading Order")));
            },
          },
        );
      },
    );
  }
}