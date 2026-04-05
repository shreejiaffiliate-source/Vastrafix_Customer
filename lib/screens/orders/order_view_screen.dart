import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api_services.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../orders/order_detail_screen.dart';

class OrdersViewScreen extends StatefulWidget {
  const OrdersViewScreen({super.key});

  @override
  State<OrdersViewScreen> createState() => _OrdersViewScreenState();
}

class _OrdersViewScreenState extends State<OrdersViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> inProcessOrders = [];
  List<dynamic> completedOrders = [];
  List<dynamic> cancelledOrders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      final orders = await ApiService.getOrderHistory();
      if (!mounted) return;

      setState(() {
        inProcessOrders = orders
            .where((o) =>
        o["status"] != "delivered" && o["status"] != "cancelled")
            .toList();
        completedOrders =
            orders.where((o) => o["status"] == "delivered").toList();
        cancelledOrders =
            orders.where((o) => o["status"] == "cancelled").toList();
        isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 Theme colors access karein taaki light/dark mode auto chale
    final bool isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
    final Color cardColor = Theme
        .of(context)
        .cardTheme
        .color ?? Colors.white;
    final Color scaffoldBg = Theme
        .of(context)
        .scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text(
            "My Orders", style: TextStyle(fontWeight: FontWeight.bold)),
        // 🔹 Hardcoded white color hataya
        backgroundColor: isDark ? scaffoldBg : Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.navyDark : AppTheme.scaffoldBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderGrey.withOpacity(0.3)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppTheme.primaryBlue,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.greyText,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: "Active"),
                Tab(text: "Done"),
                Tab(text: "Cancelled"),
              ],
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildOrderList(inProcessOrders, "No active orders",
              Icons.local_laundry_service_outlined),
          _buildOrderList(completedOrders, "No completed orders",
              Icons.check_circle_outline),
          _buildOrderList(
              cancelledOrders, "No cancelled orders", Icons.cancel_outlined),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<dynamic> orders, String emptyTitle,
      IconData emptyIcon) {
    return RefreshIndicator(
      color: AppTheme.primaryBlue,
      onRefresh: fetchOrders,
      child: orders.isEmpty
          ? SingleChildScrollView( // 🔹 Simple ScrollView use karein crash se bachne ke liye
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery
              .of(context)
              .size
              .height * 0.6, // Screen ka 60% height
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(emptyIcon, size: 70, color: AppTheme.borderGrey),
              const SizedBox(height: 16),
              Text(emptyTitle, style: const TextStyle(
                  color: AppTheme.greyText, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: fetchOrders,
                child: const Text(
                    "Refresh", style: TextStyle(color: AppTheme.primaryBlue)),
              )
            ],
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return _OrderCard(
            order: orders[index],
            onRefresh: fetchOrders,
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final dynamic order;
  final VoidCallback onRefresh;

  const _OrderCard({required this.order, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    String formattedDate = "Unknown Date";
    // 🔹 Null check safety added
    if (order != null && order["created_at"] != null) {
      try {
        DateTime dateTime = DateTime.parse(order["created_at"]).toLocal();
        formattedDate = DateFormat('dd MMM, hh:mm a').format(dateTime);
      } catch (_) {}
    }

    String currentStatus = order?["status"] ?? "pending";
    // Status color logic (Direct use of colors for safety)
    Color statusColor = AppTheme.primaryBlue;
    if (currentStatus == 'delivered') statusColor = AppTheme.freshGreen;
    if (currentStatus == 'cancelled') statusColor = Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color, // 🔹 Theme card color
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppTheme.borderGrey.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Order #${order?["id"] ?? '0'}",
                    style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.navyDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 16
                    )),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    currentStatus.toUpperCase(),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(formattedDate, style: const TextStyle(color: AppTheme.greyText, fontSize: 12)),
            const Divider(height: 24, color: AppTheme.borderGrey),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Total Payable", style: TextStyle(color: AppTheme.greyText, fontSize: 11)),
                    Text(
                      "₹${double.tryParse(order?["total_amount"]?.toString() ?? "0")?.toStringAsFixed(0)}",
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: isDark ? Colors.white : AppTheme.navyDark
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 38,
                  // 🔹 FIX: width hatayi taaki infinity wala crash na ho
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppTheme.navyDark : Colors.white,
                      foregroundColor: AppTheme.primaryBlue,
                      elevation: 0,
                      // 🔹 YAHAN DHAYAN DEIN: double.infinity hatana hai
                      minimumSize: const Size(0, 38), // Infinity ko 0 ya fix value kar dein
                      side: const BorderSide(color: AppTheme.primaryBlue, width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onPressed: () async {
                      final bool? shouldRefresh = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
                      );
                      if (shouldRefresh == true) onRefresh();
                    },
                    child: const Text("Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}