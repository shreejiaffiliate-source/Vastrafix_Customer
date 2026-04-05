import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'navigation_service.dart';
import 'api_services.dart';

class FirebaseService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> handleNotificationClick(String? orderId) async {
    if (orderId != null && orderId.isNotEmpty) {
      print("🔔 Notification Tap Detected! Order ID: $orderId");

      // App ki screen load hone ke liye thoda sa time dete hain (Adha second)
      await Future.delayed(const Duration(milliseconds: 500));

      // Fir navigate karte hain
      navigatorKey.currentState?.pushNamed(
        '/order_detail',
        arguments: orderId,
      );
    }
  }

  static Future<void> initialize() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );


    String? token = await messaging.getToken();
    print("FCM TOKEN: $token");
    if (token != null) {
      await ApiService.updateFCMToken(token);
    }

    // 🔥 YAHAN ADD KARO
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      ApiService.updateFCMToken(newToken);
    });

    // Android ke liye High Importance Channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'vastrafix_urgent_channel', // 🔥 NAYA NAAM
      'Urgent Orders', // title
      description: 'This channel is used for order notifications.', // description
      importance: Importance.max, // Max importance for popup
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
    InitializationSettings(android: androidSettings);

    // 🔥 FIX 1: 'settings:' parameter naam wapas add kiya
    await flutterLocalNotificationsPlugin.initialize(settings: settings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        // 🔥 FIX 2: 'id:', 'title:', 'body:', 'notificationDetails:' wapas add kiye
        flutterLocalNotificationsPlugin.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              'vastrafix_urgent_channel',
              'Urgent Orders',
              channelDescription: channel.description,
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
              icon: '@mipmap/ic_launcher',
            ),
          ),
          // Ye line sabse zaroori hai local click ke liye!
          payload: message.data['order_id']?.toString(),
        );
      }
    });

    // 🔥 UPDATE 4: Jab app background mein ho aur click ho
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      handleNotificationClick(message.data['order_id']?.toString());
    });

    // 🔥 UPDATE 5: Jab app poori tarah band ho aur click ho
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        handleNotificationClick(message.data['order_id']?.toString());
      }
    });

  }
}