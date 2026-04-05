import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../core/api_services.dart';
import '../../models/cart_item_model.dart';
import '../../models/address_model.dart';
import 'order_success_screen.dart';
import '../../core/theme.dart';

class OrderScreen extends StatefulWidget {
  final List<CartItem> selectedItems;
  final String pickupDateTimeString;
  final double finalAmount;
  final String deliveryModeTitle;
  final double deliveryCharge;
  final AddressModel selectedAddress;

  const OrderScreen({
    super.key,
    required this.selectedItems,
    required this.pickupDateTimeString,
    required this.finalAmount,
    required this.deliveryModeTitle,
    required this.deliveryCharge,
    required this.selectedAddress,
  });

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  bool isLoading = false;
  String _selectedPaymentMethod = "COD";
  late Razorpay _razorpay;

  Map<String, List<CartItem>> get itemsByService {
    final map = <String, List<CartItem>>{};
    for (final item in widget.selectedItems) {
      map.putIfAbsent(item.service, () => []);
      map[item.service]!.add(item);
    }
    return map;
  }

  @override
  void initState() {
    super.initState();
    // 🔥 Razorpay Initialization
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // 🔥 Razorpay Success Handler
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    bool isVerified = await ApiService.verifyRazorpayPayment(
      response.orderId ?? "",
      response.paymentId ?? "",
      response.signature ?? "",
      (widget.finalAmount * 100).toInt(), // ✅ Amount paise mein bhejein
    );

    if (isVerified) {
      await _placeOrderAPI("ONLINE", paymentId: response.paymentId);
    } else {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment Verification Failed!"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment failed: ${response.message}"), backgroundColor: AppTheme.navyDark),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() => isLoading = false);
  }

  // 🔹 API Calling Method
  Future<void> _placeOrderAPI(String paymentMode, {String? paymentId}) async {
    final createdOrder = await ApiService.placeOrder(
      widget.selectedItems,
      widget.selectedAddress.id ?? 0,
      widget.pickupDateTimeString,
      widget.deliveryModeTitle,
      widget.deliveryCharge,
      paymentMode,
      paymentId: paymentId,
    );

    if (createdOrder != null && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OrderSuccessScreen(order: createdOrder)));
    } else if (mounted) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order failed."), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    String displayTime = "Not Scheduled";
    try {
      DateTime formattedDate = DateTime.parse(widget.pickupDateTimeString);
      displayTime = DateFormat('dd MMM yyyy, hh:mm a').format(formattedDate);
    } catch (_) {}

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text("Order Summary", style: TextStyle(color: isDark ? Colors.white : AppTheme.navyDark, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: isDark ? scaffoldBg : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: isDark ? Colors.white : AppTheme.navyDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Pickup Details", isDark),
            _buildTimeCard(displayTime, isDark),
            const SizedBox(height: 24),

            _buildSectionHeader("Delivery Address", isDark),
            _buildAddressCard(isDark),
            const SizedBox(height: 24),

            _buildSectionHeader("Payment Method", isDark),
            _buildPaymentOptions(isDark),
            const SizedBox(height: 24),

            _buildSectionHeader("Bill Details", isDark),
            _buildBillDetailsCard(isDark),
            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title,
          style: TextStyle(color: isDark ? Colors.white : AppTheme.navyDark, fontWeight: FontWeight.bold, fontSize: 16)
      ),
    );
  }

  Widget _buildTimeCard(String displayTime, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(isDark),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined, color: AppTheme.primaryBlue),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Pickup Slot", style: TextStyle(color: AppTheme.greyText, fontSize: 12)),
              Text(displayTime, style: TextStyle(color: isDark ? Colors.white : AppTheme.navyDark, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(bool isDark) {
    final address = widget.selectedAddress;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(isDark),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_outlined, color: AppTheme.freshGreen),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${address.houseNo}, ${address.street}",
                    style: TextStyle(color: isDark ? Colors.white : AppTheme.navyDark, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 4),
                Text("${address.area}, ${address.city}\n${address.pincode}",
                    style: TextStyle(color: isDark ? Colors.white70 : AppTheme.greyText,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptions(bool isDark) {
    return Column(
      children: [
        _paymentTile("ONLINE", "Pay Online", "UPI, Cards, Wallets", Icons.account_balance_wallet_outlined, isDark),
        const SizedBox(height: 12),
        _paymentTile("COD", "Cash on Delivery", "Pay after service", Icons.payments_outlined, isDark),
      ],
    );
  }

  Widget _paymentTile(String value, String title, String sub, IconData icon, bool isDark) {
    bool isSel = _selectedPaymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.navyDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSel ? AppTheme.primaryBlue : (isDark ? Colors.white10 : AppTheme.borderGrey), width: isSel ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSel ? AppTheme.primaryBlue : AppTheme.greyText),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(color: isDark ? Colors.white : AppTheme.navyDark, fontWeight: FontWeight.bold)),
                Text(sub, style: const TextStyle(color: AppTheme.greyText, fontSize: 12)),
              ]),
            ),
            Icon(isSel ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSel ? AppTheme.primaryBlue : (isDark ? Colors.white12 : AppTheme.borderGrey)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillDetailsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(isDark),
      child: Column(
        children: [
          ...itemsByService.entries.map((entry) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.key.toUpperCase(),
                  style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)
              ),
              const SizedBox(height: 8),
              ...entry.value.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 🔥 FIX: Maanga hua Format (15x1)
                    Expanded(
                      child: Text("${item.name} (${item.price.toStringAsFixed(0)}x${item.quantity})",
                          style: TextStyle(color: isDark ? Colors.white70 : AppTheme.navyDark, fontSize: 14)
                      ),
                    ),
                    // 🔥 Total bold
                    Text("₹${item.total.toStringAsFixed(0)}",
                        style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.navyDark)
                    ),
                  ],
                ),
              )),
              const Divider(height: 24, color: AppTheme.borderGrey),
            ],
          )),
          _billRow("Delivery (${widget.deliveryModeTitle})", "₹${widget.deliveryCharge.toStringAsFixed(0)}", isDark),
          const Divider(height: 24, color: AppTheme.borderGrey),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("To Pay",
                  style: TextStyle(color: isDark ? Colors.white : AppTheme.navyDark, fontWeight: FontWeight.bold, fontSize: 16)
              ),
              Text("₹${widget.finalAmount.toStringAsFixed(0)}",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primaryBlue)
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _billRow(String label, String val, bool isDark) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: AppTheme.greyText, fontSize: 14)),
      Text(val, style: TextStyle(color: isDark ? Colors.white : AppTheme.navyDark, fontWeight: FontWeight.bold)),
    ]);
  }

  BoxDecoration _cardDecoration(bool isDark) => BoxDecoration(
    color: isDark ? AppTheme.navyDark : Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: isDark ? Colors.white10 : AppTheme.borderGrey),
  );

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
          color: AppTheme.navyDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Grand Total", style: TextStyle(color: Colors.white60, fontSize: 11)),
              Text("₹${widget.finalAmount.toStringAsFixed(0)}",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)
              ),
            ]),
            ElevatedButton(
              onPressed: isLoading ? null : _handlePlaceOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.freshGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                minimumSize: const Size(0, 56),
              ),
              child: isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Place Order", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePlaceOrder() async {
    HapticFeedback.heavyImpact();
    setState(() => isLoading = true);

    if (_selectedPaymentMethod == "COD") {
      await _placeOrderAPI("COD");
    } else {
      final orderData = await ApiService.createRazorpayOrder(widget.finalAmount);
      if (orderData != null && orderData.containsKey('order_id')) {
        var options = {
          'key': 'rzp_test_SOCWZ8L1q01O7W',
          'amount': orderData['amount'],
          'name': 'VastraFix',
          'order_id': orderData['order_id'],
          'description': 'Laundry Service Order',
          'prefill': {
            'contact': orderData['customer_phone'] ?? '',
            'email': orderData['customer_email'] ?? 'support@vastrafix.com'
          },
          'theme': {'color': '#1B85C4'}
        };
        try {
          _razorpay.open(options);
        } catch (e) {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Payment Initialization Failed!"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}