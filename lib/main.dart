// lib/main.dart
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
import 'core/navigation_service.dart'; // 👈 Important
import 'screens/orders/order_detail_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Background message: ${message.messageId}");
}

void _handleNotificationTap(RemoteMessage message) {
  print("🔥 Notification Clicked! Data: ${message.data}");
  print("🔥 Notification Clicked! Notification Body: ${message.notification?.body}");

  String? orderId;

  // Pehle proper data key dhundho (Best Practice)
  if (message.data.containsKey('order_id')) {
    orderId = message.data['order_id'].toString();
  } else if (message.data.containsKey('order')) {
    orderId = message.data['order'].toString();
  }
  // 🔥 TEMPORARY JUGAD: Agar data nahi hai, toh notification body mein se #Number nikal lo
  else if (message.notification != null && message.notification!.body != null) {
    RegExp regExp = RegExp(r'#(\d+)');
    Match? match = regExp.firstMatch(message.notification!.body!);
    if (match != null) {
      orderId = match.group(1);
      print("🔥 JUGAD WORKED! ID Found: $orderId");
    }
  }

  if (orderId != null) {
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState?.pushNamed('/order_detail', arguments: orderId);
    } else {
      pendingOrderIdToNavigate = orderId;
    }
  } else {
    print("❌ KOI ID NAHI MILI! Redirect nahi hoga.");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FirebaseService.initialize();

  // 🔥 1. Jab app Background (Minimize) mein ho
  FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

  RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

  if (initialMessage != null) {
    print("🔥 APP KILLED THA, NOTIFICATION MILI: ${initialMessage.data}");
    String? orderId;

    // 1. Direct Data Keys check karo
    if (initialMessage.data.containsKey('order_id')) {
      orderId = initialMessage.data['order_id'].toString();
    } else if (initialMessage.data.containsKey('order')) {
      orderId = initialMessage.data['order'].toString();
    }
    // 2. Jugad: Notification Body se nikalne ki koshish (Agar Firebase structure theek de raha hai)
    else if (initialMessage.notification != null && initialMessage.notification!.body != null) {
      RegExp regExp = RegExp(r'#(\d+)');
      Match? match = regExp.firstMatch(initialMessage.notification!.body!);
      if (match != null) orderId = match.group(1);
    }
    // 3. 🚨 NAYA JUGAD: Data object ke andar wali body se nikalne ki koshish
    else if (initialMessage.data.containsKey('body')) {
      RegExp regExp = RegExp(r'#(\d+)');
      Match? match = regExp.firstMatch(initialMessage.data['body'].toString());
      if (match != null) orderId = match.group(1);
    }

    if (orderId != null) {
      print("🔥 JUGAD SE MIL GAYA: ID = $orderId"); // Yeh check karne ke liye ki id mili ya nahi
      pendingOrderIdToNavigate = orderId;
    } else {
      print("❌ ORDER ID KAHIN NAHI MILI BRO!");
    }
  }

  // 🚀 Ab app start karo
  runApp(const VastraFix());
}

class VastraFix extends StatelessWidget {
  const VastraFix({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          navigatorKey: navigatorKey, // 👈 Ensures connection
          debugShowCheckedModeBanner: false,
          title: AppConstants.appName,
          theme: AppTheme.vastraFixTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          initialRoute: '/splash',
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/login': (context) => const LoginCustomerScreen(),
            '/signup': (context) => const SignupScreen(),
            '/order_detail': (context) {
              final args = ModalRoute.of(context)!.settings.arguments;

              if (args is Map<String, dynamic>) {
                return OrderDetailScreen(order: args);
              } else if (args is String) {
                return OrderDetailScreen(order: {"id": args});
              }
              return const Scaffold(body: Center(child: Text("Error Loading Order")));
            },
          },
        );
      },
    );
  }
}