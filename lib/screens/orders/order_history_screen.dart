import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api_services.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../orders/order_detail_screen.dart'; // 🔹 Detail screen import karein

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<dynamic> orders = [];
  List<dynamic> allOrders = [];
  bool isLoading = true;
  String selectedFilter = "all";

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => isLoading = true);
    try {
      final List<dynamic> data = await ApiService.getOrderHistory();
      allOrders = data;
      _applyFilter();
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _applyFilter() {
    setState(() {
      if (selectedFilter == "all") {
        orders = allOrders.where((order) {
          String status = order['status'].toString().toLowerCase();
          return status == 'delivered' || status == 'cancelled';
        }).toList();
      } else {
        orders = allOrders.where((order) {
          return order['status'].toString().toLowerCase() == selectedFilter;
        }).toList();
      }
      isLoading = false;
    });
  }

  void _showFilterSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      // 🔹 FIX: BottomSheet background color adaptive
      backgroundColor: isDark ? AppTheme.navyDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  "Filter History",
                  style: TextStyle(
                      color: isDark ? Colors.white : AppTheme.navyDark,
                      fontSize: 20,
                      fontWeight: FontWeight.bold
                  )
              ),
              const SizedBox(height: 20),
              _buildFilterOption("all", "Show All", isDark),
              _buildFilterOption("delivered", "Only Delivered", isDark),
              _buildFilterOption("cancelled", "Only Cancelled", isDark),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String value, String title, bool isDark) {
    bool isSelected = selectedFilter == value;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppTheme.primaryBlue : (isDark ? Colors.white70 : AppTheme.greyText),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppTheme.primaryBlue)
          : null,
      onTap: () {
        Navigator.pop(context);
        selectedFilter = value;
        _applyFilter();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text("Order History", style: TextStyle(color: isDark ? Colors.white : AppTheme.navyDark, fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: isDark ? scaffoldBg : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: isDark ? Colors.white : AppTheme.navyDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.tune_rounded, color: isDark ? Colors.white : AppTheme.navyDark),
            onPressed: _showFilterSheet,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : orders.isEmpty
          ? _buildEmptyState(isDark)
          : RefreshIndicator(
        color: AppTheme.primaryBlue,
        onRefresh: _fetchOrders,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: orders.length,
          itemBuilder: (context, index) => _buildOrderCard(orders[index], isDark),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, bool isDark) {
    String status = order['status'].toString().toLowerCase();
    bool isCancelled = status == 'cancelled';
    Color statusColor = isCancelled ? Colors.red : AppTheme.freshGreen;

    String formattedDate = "";
    try {
      if (order['created_at'] != null) {
        DateTime parsedDate = DateTime.parse(order['created_at']).toLocal();
        formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(parsedDate);
      }
    } catch (_) {
      formattedDate = order['created_at'] ?? "";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        // 🔹 FIX: Card color theme based
        color: isDark ? AppTheme.navyDark : Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: isDark ? Colors.white10 : AppTheme.borderGrey),
        boxShadow: [
          if(!isDark) BoxShadow(
            color: AppTheme.navyDark.withOpacity(0.03),
            blurRadius: 10, offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          onTap: () {
            // 🔹 FIX: Detail Screen par navigation add kiya
            Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)));
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : AppTheme.scaffoldBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isCancelled ? Icons.close_rounded : Icons.check_circle_outline_rounded,
                        color: isCancelled ? Colors.red : AppTheme.freshGreen,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Order #${order['id']}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppTheme.navyDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(formattedDate,
                              style: const TextStyle(color: AppTheme.greyText, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isCancelled ? "Cancelled" : "Delivered",
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: isDark ? Colors.white10 : AppTheme.borderGrey),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                        "Final Amount",
                        style: TextStyle(color: AppTheme.greyText, fontSize: 13, fontWeight: FontWeight.w500)
                    ),
                    Text(
                      "₹${order['total_amount']}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.navyDark,
                      ),
                    ),
                  ],
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
          Icon(Icons.history_rounded, size: 80, color: AppTheme.borderGrey),
          const SizedBox(height: 16),
          Text(
            "No Order History",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.navyDark
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Your completed orders will appear here.",
            style: TextStyle(color: AppTheme.greyText),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 150,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryBlue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Go Back"),
            ),
          )
        ],
      ),
    );
  }
}