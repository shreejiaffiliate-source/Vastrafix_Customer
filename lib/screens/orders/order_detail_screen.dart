import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_services.dart';
import '../../core/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';


class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Map<String, dynamic> order;
  bool isLoading = false; // 🔥 NAYA: Loading spinner ke liye variable

  @override
  void initState() {
    super.initState();
    order = widget.order;

    // 🔥 SMART CHECK: Agar "order_items" nahi hai, matlab ye sirf ID hai!
    if (order["order_items"] == null) {
      isLoading = true; // Spinner on karo
      _fetchDataFromId(); // Data fetch karo
    }
  }

  // image upload for complaint
  File? _selectedImage; // Isme photo store hogi
  final ImagePicker _picker = ImagePicker();

  // 🔥 NAYA: Ab yeh function Camera aur Gallery dono ke liye kaam karega
  Future<void> _pickImage(ImageSource source) async {
    final XFile? photo = await _picker.pickImage(source: source);
    if (photo != null) {
      setState(() => _selectedImage = File(photo.path));
    }
  }

  // 🔥 NAYA FUNCTION: Jo ID se data fetch karega
  Future<void> _fetchDataFromId() async {
    await _refreshOrder(); // Aapka purana refresh function hi API call kar lega

    if (mounted) {
      setState(() {
        isLoading = false; // Spinner off karo
      });
    }
  }

  // 🔹 Refresh Logic
  Future<void> _refreshOrder() async {
    try {
      final orderId = int.parse(order["id"].toString());
      Map<String, dynamic>? updatedOrder = await ApiService.getOrderDetail(orderId);

      if (updatedOrder == null || !updatedOrder.containsKey("status")) {
        final allOrders = await ApiService.getOrderHistory();
        final matchingOrder = allOrders.firstWhere(
              (o) => o["id"].toString() == orderId.toString(),
          orElse: () => null,
        );
        if (matchingOrder != null) updatedOrder = Map<String, dynamic>.from(matchingOrder);
      }

      if (updatedOrder != null && mounted) {
        setState(() => order = updatedOrder!);
      }
    } catch (e) {
      debugPrint("Refresh Error: $e");
    }
  }

  // 🔹 Items ko Service (Steam Iron, Wash & Fold) ke hisaab se group karne ke liye
  Map<String, List<dynamic>> groupItemsByService(List items) {
    Map<String, List<dynamic>> grouped = {};
    for (var item in items) {
      String service = item["service_name"] ?? "Other Service";
      if (!grouped.containsKey(service)) grouped[service] = [];
      grouped[service]!.add(item);
    }
    return grouped;
  }

  int _getCurrentStep(String? status) {
    switch (status?.toLowerCase()) {
      case 'accepted': return 0;
      case 'pickup': return 1;
      case 'processing': return 2;
      case 'shipping': return 3;
      case 'delivered': return 4;
      default: return -1;
    }
  }

  //====== Order Complaint ======//

  final TextEditingController _complaintController = TextEditingController();

  Future<void> _submitComplaint() async {
    // 1. Controller se message nikalen
    String userMessage = _complaintController.text.trim();

    if (userMessage.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please write your issue first")),
      );
      return;
    }

    // 2. SharedPreferences se name nikalen
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String savedName = prefs.getString("user_name") ?? "Customer";

    setState(() => isLoading = true);

    try {
      // 🔥 FIX: 'final' keyword add kiya success ke pehle
      final bool success = await ApiService.submitOrderComplaint(
        orderId: int.parse(order["id"].toString()),
        complaintText: userMessage,
        nameOfUser: savedName,
        imageFile: _selectedImage, // 🔥 Image pass ho rahi hai
      );

      if (mounted) {
        setState(() => isLoading = false);

        // Ab 'success' yahan accessible hoga
        if (success) {
          Navigator.pop(context); // BottomSheet band karein
          _complaintController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Complaint submitted successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to submit. Try again."), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        print("Error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("An error occurred"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 🔥 NAYA: Complaint wala BottomSheet
  void _showComplaintDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.navyDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder( // 👈 StatefulBuilder zaroori hai photo preview update ke liye
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20, right: 20, top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Raise a Complaint",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.navyDark)),
                const SizedBox(height: 8),
                Text("Tell us what went wrong with Order #${order["id"]}",
                    style: const TextStyle(color: AppTheme.greyText, fontSize: 13)),
                const SizedBox(height: 16),

                // --- Complaint Text Field ---
                TextField(
                  controller: _complaintController,
                  maxLines: 4,
                  style: TextStyle(color: isDark ? Colors.white : AppTheme.navyDark),
                  decoration: InputDecoration(
                    hintText: "E.g. My shirt has a burn mark / Clothes are still dirty...",
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.05) : AppTheme.scaffoldBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),

                // --- Image Upload Section ---
                Text("Attach Proof (Optional)",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : AppTheme.navyDark)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    // 🔥 NAYA: Click karte hi ek chhota menu khulega (Camera ya Gallery)
                    showModalBottomSheet(
                        context: context,
                        backgroundColor: isDark ? AppTheme.navyDark : Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (BuildContext bc) {
                          return SafeArea(
                            child: Wrap(
                              children: <Widget>[
                                ListTile(
                                  leading: const Icon(Icons.photo_camera, color: AppTheme.primaryBlue),
                                  title: Text('Take a Photo', style: TextStyle(color: isDark ? Colors.white : AppTheme.navyDark, fontWeight: FontWeight.w500)),
                                  onTap: () async {
                                    Navigator.of(context).pop(); // Menu band karo
                                    await _pickImage(ImageSource.camera); // 📸 Camera open karo
                                    setModalState(() {}); // UI update karo
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.photo_library, color: AppTheme.primaryBlue),
                                  title: Text('Choose from Gallery', style: TextStyle(color: isDark ? Colors.white : AppTheme.navyDark, fontWeight: FontWeight.w500)),
                                  onTap: () async {
                                    Navigator.of(context).pop(); // Menu band karo
                                    await _pickImage(ImageSource.gallery); // 🖼️ Gallery open karo
                                    setModalState(() {}); // UI update karo
                                  },
                                ),
                              ],
                            ),
                          );
                        }
                    );
                  },
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isDark ? Colors.white10 : Colors.grey.shade300,
                          style: BorderStyle.solid
                      ),
                    ),
                    child: _selectedImage == null
                        ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, color: AppTheme.primaryBlue, size: 30),
                        SizedBox(height: 8),
                        Text("Tap to upload or take photo", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    )
                        : Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_selectedImage!, width: double.infinity, fit: BoxFit.cover),
                        ),
                        // ❌ Remove Photo Button
                        Positioned(
                          top: 8, right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedImage = null);
                              setModalState(() {});
                            },
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.red.withOpacity(0.8),
                              child: const Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // --- Submit Button ---
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade800,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: _submitComplaint,
                    child: const Text("Submit Complaint",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {

    // 🔥 NAYA: Jab data aa raha ho, tab Gol-Gol ghoome (Spinner)
    if (isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: const Text("Loading Order...")),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    final List items = order["order_items"] ?? [];
    final String status = order["status"]?.toLowerCase() ?? "pending";
    final groupedItems = groupItemsByService(items);

    DateTime? dateTime = order["created_at"] != null ? DateTime.tryParse(order["created_at"])?.toLocal() : null;
    String formattedDate = dateTime != null ? DateFormat('dd MMM yyyy, hh:mm a').format(dateTime) : "N/A";

    double itemsTotalAmount = items.fold(0, (sum, i) =>
    sum + (double.tryParse(i["item_price"].toString()) ?? 0) * (int.tryParse(i["quantity"].toString()) ?? 0));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, true);
      },
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          title: Text("Order Details", style: TextStyle(color: isDark ? Colors.white : AppTheme.navyDark, fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: isDark ? scaffoldBg : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, size: 18, color: isDark ? Colors.white : AppTheme.navyDark),
            onPressed: () => Navigator.pop(context, true),
          ),
        ),
        body: RefreshIndicator(
          color: AppTheme.primaryBlue,
          onRefresh: _refreshOrder,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 1. STATUS CARD
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: _cardDecoration(isDark),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Order #${order["id"]}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : AppTheme.navyDark)),
                              const SizedBox(height: 4),
                              Text(formattedDate, style: const TextStyle(color: AppTheme.greyText, fontSize: 12)),
                            ],
                          ),
                          _buildStatusBadge(status),
                        ],
                      ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: AppTheme.borderGrey, thickness: 0.5)),
                      if (status == "cancelled") _buildCancelledMessage() else _buildTimeline(status, isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. ITEMS SUMMARY (SERVICE GROUPING + PRICE FORMAT)
                Container(
                  width: double.infinity,
                  decoration: _cardDecoration(isDark),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text("Items Summary", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.navyDark)),
                      ),
                      const Divider(height: 1, color: AppTheme.borderGrey),

                      ...groupedItems.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
                              child: Text(entry.key.toUpperCase(), style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.1)),
                            ),
                            ...entry.value.map((item) {
                              final price = double.tryParse(item["item_price"].toString()) ?? 0;
                              final qty = int.tryParse(item["quantity"].toString()) ?? 0;
                              final itemTotal = price * qty;
                              return ListTile(
                                dense: true,
                                // 🔥 FORMAT: Shirt (15x1)
                                title: Text("${item["item_name"] ?? ""} (${price.toStringAsFixed(0)}x$qty)",
                                    style: TextStyle(fontSize: 14, color: isDark ? Colors.white : AppTheme.navyDark, fontWeight: FontWeight.w500)),
                                // 🔥 FORMAT: ₹15 (Bada aur Bold)
                                trailing: Text("₹${itemTotal.toStringAsFixed(0)}",
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isDark ? Colors.white : AppTheme.navyDark)),
                              );
                            }),
                            const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Divider(color: AppTheme.borderGrey, thickness: 0.5)),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. BILL DETAILS
                Container(
                  decoration: _cardDecoration(isDark),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _billRow("Subtotal", "₹${itemsTotalAmount.toStringAsFixed(0)}", isDark),
                            const SizedBox(height: 10),
                            _billRow("Delivery Fee", "₹${order["delivery_charge"] ?? 0}", isDark),
                            const SizedBox(height: 10),
                            _billRow("Payment Mode", order["payment_mode"]?.toString().toUpperCase() ?? "COD", isDark),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.05), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Grand Total", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.navyDark)),
                            Text("₹${order["total_amount"]}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppTheme.primaryBlue)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // 4. ACTIONS (Cancel Logic: Sirf Accepted/Pending mein)
                if (status == "accepted" || status == "pending")
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _cancelOrder,
                      child: const Text("Cancel Order", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ),

                if (status == "delivered")
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.freshGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      onPressed: _showComplaintDialog, // Call ki jagah ab Complaint khulega
                      icon: const Icon(Icons.report_problem_rounded, size: 20),
                      label: const Text("Raise a Complaint", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI HELPERS ---
  BoxDecoration _cardDecoration(bool isDark) => BoxDecoration(
      color: isDark ? AppTheme.navyDark : Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: isDark ? Colors.white10 : AppTheme.borderGrey),
      boxShadow: [if (!isDark) BoxShadow(color: AppTheme.navyDark.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
  );

  Widget _buildStatusBadge(String status) {
    Color color = status == "delivered" ? AppTheme.freshGreen : (status == "cancelled" ? Colors.red : AppTheme.primaryBlue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }

  Widget _buildTimeline(String status, bool isDark) {
    final currentStep = _getCurrentStep(status);
    final steps = [
      {"icon": Icons.thumb_up_alt_outlined, "label": "Accepted"},
      {"icon": Icons.delivery_dining_outlined, "label": "Pickup"},
      {"icon": Icons.local_laundry_service_outlined, "label": "Process"},
      {"icon": Icons.local_shipping_outlined, "label": "Shipping"},
      {"icon": Icons.check_circle_outline, "label": "Done"},
    ];
    return Row(
      children: List.generate(steps.length, (index) {
        bool isCompleted = index <= currentStep;
        bool isLast = index == steps.length - 1;

        return Expanded(
          flex: isLast ? 0 : 1, // Last item ko line ki zaroorat nahi hai
          child: Row(
            children: [
              // 1. Icon aur Label ka Column
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    steps[index]["icon"] as IconData,
                    color: isCompleted
                        ? AppTheme.primaryBlue
                        : (isDark ? Colors.white24 : AppTheme.borderGrey),
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    steps[index]["label"] as String,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                      color: isCompleted
                          ? (isDark ? Colors.white : AppTheme.navyDark)
                          : AppTheme.greyText,
                    ),
                  ),
                ],
              ),

              // 2. Connecting Line (Sirf last wale ko chhod kar)
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 12), // Icon ke center mein align karne ke liye
                    color: isCompleted && (index < currentStep)
                        ? AppTheme.primaryBlue // Active Line
                        : (isDark ? Colors.white10 : AppTheme.borderGrey), // Inactive Line
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCancelledMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
      child: const Row(children: [Icon(Icons.error_outline, color: Colors.red, size: 20), SizedBox(width: 10), Text("This order was cancelled", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14))]),
    );
  }

  Widget _billRow(String label, String value, bool isDark) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: AppTheme.greyText, fontSize: 14)), Text(value, style: TextStyle(color: isDark ? Colors.white : AppTheme.navyDark, fontWeight: FontWeight.w600, fontSize: 14))]);
  }

  Future<void> _cancelOrder() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? AppTheme.navyDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Cancel Order?", style: TextStyle(color: isDark ? Colors.white : AppTheme.navyDark, fontWeight: FontWeight.bold)),
        content: Text("Are you sure? This action cannot be undone.", style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes, Cancel", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      final success = await ApiService.cancelOrder(order["id"]);
      if (success && mounted) setState(() { order["status"] = "cancelled"; order = Map<String, dynamic>.from(order); });
    }
  }

  Future<void> _callPartner() async {
    final String? partnerPhone = order["partner_phone"]?.toString();
    if (partnerPhone == null || partnerPhone.isEmpty || partnerPhone == "null") {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Contact unavailable."), backgroundColor: Colors.redAccent));
      return;
    }
    final Uri launchUri = Uri(scheme: 'tel', path: partnerPhone.replaceAll(RegExp(r'\s+'), ''));
    if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
  }
}