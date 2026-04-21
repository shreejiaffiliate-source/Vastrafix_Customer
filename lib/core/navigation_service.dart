// lib/core/navigation_service.dart
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 🔥 NAYA: Pending order ID store karne ke liye
String? pendingOrderIdToNavigate;