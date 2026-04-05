import 'package:flutter/material.dart';
// 🔥 Required for userName
import '../../core/theme.dart';
import '../../core/api_services.dart';
import '../orders/order_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final data = await ApiService.getNotifications();
    if (mounted) {
      setState(() {
        notifications = data ?? [];
        isLoading = false;
      });
    }
  }

  void _navigateToOrder(dynamic note) async {
    if (note == null) return;

    // 🔥 PEHLA TRY: Agar backend se order_id key aa rahi ho
    dynamic orderIdRaw = note['order_id'] ?? note['order'];

    // 🔥 DOOSRA TRY: Agar ID null hai, toh Message se nikalne ki koshish (RegExp)
    if (orderIdRaw == null && note['message'] != null) {
      RegExp regExp = RegExp(r'#(\d+)'); // Ye #449 mein se 449 nikal lega
      Match? match = regExp.firstMatch(note['message']);
      if (match != null) {
        orderIdRaw = match.group(1);
      }
    }

    if (orderIdRaw == null) {
      _showErrorMessage("ID nahi mili. Backend mein order_id add karein.");
      return;
    }

    final int orderId = int.parse(orderIdRaw.toString());

    setState(() => isLoading = true);

    try {
      final orderData = await ApiService.getOrderDetail(orderId);

      if (orderData != null && mounted) {
        setState(() => isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(order: orderData),
          ),
        );
      } else {
        if (mounted) setState(() => isLoading = false);
        _showErrorMessage("Order details not found on server.");
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      _showErrorMessage("Failed to load order detail");
      print("Error: $e");
    }
  }

  void _showErrorMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  String _formatTime(String? dateString) {
    if (dateString == null) return '';
    try {
      DateTime date = DateTime.parse(dateString).toLocal();
      Duration diff = DateTime.now().difference(date);
      if (diff.inDays > 7) return "${date.day}/${date.month}/${date.year}";
      if (diff.inDays >= 2) return "${diff.inDays} days ago";
      if (diff.inDays >= 1) return "Yesterday";
      if (diff.inHours >= 1) return "${diff.inHours}h ago";
      if (diff.inMinutes >= 1) return "${diff.inMinutes}m ago";
      return "Just now";
    } catch (e) { return ''; }
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear Notifications?"),
        content: const Text("Kya aap saare notifications permanent delete karna chahte hain?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => isLoading = true);
              bool success = await ApiService.clearAllNotifications();
              if (success) {
                setState(() {
                  notifications = [];
                  isLoading = false;
                });
                _showErrorMessage("All notifications cleared!");
              } else {
                setState(() => isLoading = false);
                _showErrorMessage("Failed to clear notifications on server");
              }
            },
            child: const Text("Clear All", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.navyDark)),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: _showClearDialog,
              child: const Text("Clear All", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
        ],
        centerTitle: false,
        backgroundColor: isDark ? scaffoldBg : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: isDark ? Colors.white : AppTheme.navyDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : notifications.isEmpty
          ? _buildEmptyState(isDark)
          : RefreshIndicator(
        onRefresh: _fetchNotifications,
        color: AppTheme.primaryBlue,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: notifications.length,
          itemBuilder: (context, index) => _buildNotificationCard(notifications[index], isDark),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> note, bool isDark) {
    String title = note['title'] ?? "Notification";
    String message = note['message'] ?? "";
    String time = _formatTime(note['created_at']);
    String iconType = note['icon_type'] ?? "default";

    print("DEBUG: Notification Data -> $note");

    // 🔥 Backend Mapping: order_id ya order key ko pakdenge
    dynamic orderIdRaw = note['order_id'] ?? note['order'];

    IconData iconData;
    Color brandColor;

    switch (iconType.toLowerCase()) {
      case 'accepted': iconData = Icons.assignment_turned_in_sharp; brandColor = AppTheme.primaryBlue; break;
      case 'pickup': iconData = Icons.local_mall_rounded; brandColor = Colors.orange; break;
      case 'processing': iconData = Icons.layers_rounded; brandColor = Colors.purple; break;
      case 'shipping': iconData = Icons.local_shipping_rounded; brandColor = Colors.blue; break;
      case 'delivered': iconData = Icons.task_alt_rounded; brandColor = AppTheme.freshGreen; break;
      default: iconData = Icons.notifications_active_outlined; brandColor = isDark ? Colors.white70 : AppTheme.navyDark;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.navyDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : AppTheme.borderGrey),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToOrder(note),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: brandColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(iconData, color: brandColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              // 🔥 ID Display: Title ke saath (#ID) dikhayen
                                orderIdRaw != null ? "$title (#$orderIdRaw)" : title,
                                style: TextStyle(color: isDark ? Colors.white : AppTheme.navyDark, fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                          Text(time, style: const TextStyle(fontSize: 11, color: AppTheme.greyText)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(message, style: const TextStyle(color: AppTheme.greyText, fontSize: 13, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 60, color: AppTheme.primaryBlue.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text("Nothing new here", style: TextStyle(color: isDark ? Colors.white : AppTheme.navyDark, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}