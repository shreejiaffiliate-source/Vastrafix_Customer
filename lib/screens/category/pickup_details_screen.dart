import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';

import '../../models/cart_item_model.dart';
import '../../models/address_model.dart';
import '../../core/api_services.dart';
import '../orders/order_screen.dart';
import '../../core/theme.dart';

class PickupDetailsScreen extends StatefulWidget {
  final List<CartItem> selectedItems;
  final double itemTotal;

  const PickupDetailsScreen({
    super.key,
    required this.selectedItems,
    required this.itemTotal,
  });

  @override
  State<PickupDetailsScreen> createState() => _PickupDetailsScreenState();
}

class _PickupDetailsScreenState extends State<PickupDetailsScreen> {
  DateTime selectedDate = DateTime.now();
  String? selectedSlot;
  double minimumOrderAmount = 100.0; // 🔥 Fix: 100 set kiya

  String selectedDeliveryMode = "";
  List<dynamic> deliveryOptions = [];
  bool isLoadingConfigs = true;

  final Map<String, IconData> defaultIcons = {
    "normal": Icons.local_shipping_outlined,
    "one_day": Icons.timer_outlined,
    "1_day": Icons.timer_outlined,
    "premium": Icons.bolt_rounded,
  };

  AddressModel? savedAddress;
  AddressModel? selectedAddress;
  List<AddressModel> addressList = [];
  bool isLoadingAddress = true;

  final _houseNoController = TextEditingController();
  final _streetController = TextEditingController();
  final _areaController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  final List<Map<String, dynamic>> pickupSlots = [
    {"time": "07:00 AM - 09:00 AM", "label": "Morning", "icon": Icons.wb_twilight_rounded},
    {"time": "06:00 PM - 08:00 PM", "label": "Evening", "icon": Icons.nights_stay_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await Future.wait([
      _initAddressData(),
      _fetchDeliveryConfigs(),
    ]);
    _handleAutomaticDateSelection();
  }

  void _handleAutomaticDateSelection() {
    if (pickupSlots.isEmpty) return;
    DateTime now = DateTime.now();
    final lastSlotTime = DateFormat("hh:mm a").parse(pickupSlots.last["time"].split(" - ")[0]);
    DateTime lastSlotToday = DateTime(now.year, now.month, now.day, lastSlotTime.hour, lastSlotTime.minute);

    if (now.isAfter(lastSlotToday)) {
      setState(() {
        selectedDate = DateTime.now().add(const Duration(days: 1));
      });
    }
  }

  Future<void> _fetchDeliveryConfigs() async {
    try {
      final configs = await ApiService.getDeliveryConfigs();
      if (configs != null && configs.isNotEmpty) {
        if (mounted) {
          setState(() {
            deliveryOptions = configs;
            selectedDeliveryMode = deliveryOptions.firstWhere(
                    (e) => e["mode_id"] == "normal",
                orElse: () => deliveryOptions[0])["mode_id"];
            isLoadingConfigs = false;
          });
        }
      } else {
        setState(() => isLoadingConfigs = false);
      }
    } catch (e) {
      setState(() => isLoadingConfigs = false);
    }
  }

  @override
  void dispose() {
    _houseNoController.dispose();
    _streetController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _initAddressData() async {
    await _fetchAddresses();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastUsedId = prefs.getString('saved_address_id');
    if (mounted) {
      setState(() {
        if (addressList.isNotEmpty) {
          if (lastUsedId != null) {
            try {
              savedAddress = addressList.firstWhere(
                    (a) => a.id.toString() == lastUsedId,
                orElse: () => addressList.first,
              );
            } catch (e) {
              savedAddress = addressList.first;
            }
          } else {
            savedAddress = addressList.first;
          }
          selectedAddress = savedAddress;
        }
      });
    }
  }

  Future<void> _fetchAddresses() async {
    setState(() => isLoadingAddress = true);
    try {
      final profileData = await ApiService.getUserProfile();
      if (profileData != null && profileData["addresses"] != null) {
        final List dynamicAddresses = profileData["addresses"];
        addressList = dynamicAddresses.map((e) => AddressModel.fromJson(e)).toList();
        addressList.sort((a, b) => (int.tryParse(b.id.toString()) ?? 0).compareTo(int.tryParse(a.id.toString()) ?? 0));
      }
    } catch (e) { addressList = []; }
    setState(() => isLoadingAddress = false);
  }

  Future<void> _saveOrUpdateAddress(bool isBottomSheet, {AddressModel? addressToEdit}) async {
    // 🔥 FIX 1: State ka validation bhi add kiya
    if (_houseNoController.text.trim().isEmpty || _pincodeController.text.trim().isEmpty || _stateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Required fields missing (Check State/Pincode)")));
      return;
    }

    double? lat; double? lng;
    String fullAddress = "${_houseNoController.text}, ${_streetController.text}, ${_areaController.text}, ${_cityController.text}, ${_stateController.text}, ${_pincodeController.text}";

    try {
      List<Location> locations = await locationFromAddress(fullAddress);
      if (locations.isNotEmpty) {
        // 🔥 FIX 2: Decimal places ko 6 tak limit kiya (toStringAsFixed(6) use karke)
        lat = double.parse(locations.first.latitude.toStringAsFixed(6));
        lng = double.parse(locations.first.longitude.toStringAsFixed(6));
      }
    } catch (_) {}

    final data = {
      "house_no": _houseNoController.text.trim(),
      "street": _streetController.text.trim(),
      "area": _areaController.text.trim(),
      "city": _cityController.text.trim(),
      "state": _stateController.text.trim(), // Ye ab UI se aayega
      "pincode": _pincodeController.text.trim(),
      "latitude": lat,
      "longitude": lng,
    };

    try {
      if (addressToEdit == null) {
        final addressId = await ApiService.createAddress(data);
        if (addressId != null) {
          await _fetchAddresses();
          savedAddress = addressList.first;
          selectedAddress = savedAddress;
        }
      } else {
        await ApiService.updateAddress(addressToEdit.id, data);
        await _fetchAddresses();
        setState(() {
          savedAddress = addressList.firstWhere((a) => a.id == addressToEdit.id);
          selectedAddress = savedAddress;
        });
      }
      _clearControllers();
      if (mounted && isBottomSheet) Navigator.pop(context);
    } catch (e) { debugPrint("Error: $e"); }
  }

  void _clearControllers() {
    _houseNoController.clear(); _streetController.clear(); _areaController.clear();
    _cityController.clear(); _stateController.clear(); _pincodeController.clear();
  }

  double _getDeliveryCharge() {
    if (widget.itemTotal < 100) return 40.0;
    if (deliveryOptions.isEmpty) return 0.0;
    try {
      final selectedOpt = deliveryOptions.firstWhere((e) => e["mode_id"] == selectedDeliveryMode);
      return double.tryParse(selectedOpt["charge_percent"].toString()) ?? 0.0;
    } catch (e) { return 0.0; }
  }

  DateTime _getCombinedDateTime() {
    if (selectedSlot == null) return selectedDate;
    final startTime = selectedSlot!.split(" - ")[0];
    final parsedTime = DateFormat("hh:mm a").parse(startTime);
    return DateTime(selectedDate.year, selectedDate.month, selectedDate.day, parsedTime.hour, parsedTime.minute);
  }

  @override
  Widget build(BuildContext context) {
    double deliveryFee = _getDeliveryCharge();
    double finalPayAmount = widget.itemTotal + deliveryFee;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text("Schedule Pickup",
            style: TextStyle(color: isDark ? Colors.white : AppTheme.navyDark, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: isDark ? scaffoldBg : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: isDark ? Colors.white : AppTheme.navyDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("Pickup Location", onAction: _showAddressSelection, actionLabel: "Change", isDark: isDark),
              _buildLocationCard(isDark),
              const SizedBox(height: 30),

              _buildSectionHeader("Delivery Speed", isDark: isDark),
              _buildSpeedOptions(isDark),
              const SizedBox(height: 30),

              _buildSectionHeader("Select Date",
                  onAction: _pickCustomDate,
                  actionLabel: DateFormat('MMMM yyyy').format(selectedDate),
                  isDark: isDark),
              _buildDateSlider(isDark),
              const SizedBox(height: 30),

              if (selectedDeliveryMode == "premium")
                _buildPremiumNotice()
              else ...[
                _buildSectionHeader("Pickup Time", isDark: isDark),
                _buildTimeGrid(isDark),
              ],
              const SizedBox(height: 140),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(finalPayAmount),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onAction, String? actionLabel, required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(color: isDark ? Colors.white : AppTheme.navyDark, fontWeight: FontWeight.bold, fontSize: 16)),
          if (onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!, style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(bool isDark) {
    if (isLoadingAddress) return const Center(child: CircularProgressIndicator());
    if (savedAddress == null) {
      return GestureDetector(
        onTap: () => _showAddressFormBottomSheet(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.navyDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.5)),
          ),
          child: const Column(
            children: [
              Icon(Icons.add_location_alt_outlined, color: AppTheme.primaryBlue, size: 30),
              SizedBox(height: 8),
              Text("Add Address", style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.navyDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : AppTheme.borderGrey),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppTheme.primaryBlue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${savedAddress!.houseNo}, ${savedAddress!.street}",
                    style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.navyDark)),
                Text("${savedAddress!.area}, ${savedAddress!.city} - ${savedAddress!.pincode}",
                    style: TextStyle(color: isDark ? Colors.white70 : AppTheme.greyText,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedOptions(bool isDark) {
    if (isLoadingConfigs) return const LinearProgressIndicator();
    return Row(
      children: deliveryOptions.map((opt) {
        bool isSel = selectedDeliveryMode == opt["mode_id"];
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => selectedDeliveryMode = opt["mode_id"]);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
              decoration: BoxDecoration(
                color: isSel ? AppTheme.primaryBlue : (isDark ? AppTheme.navyDark : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSel ? AppTheme.primaryBlue : (isDark ? Colors.white10 : AppTheme.borderGrey)),
              ),
              child: Column(
                children: [
                  Icon(defaultIcons[opt["mode_id"]] ?? Icons.speed, color: isSel ? Colors.white : AppTheme.primaryBlue),
                  const SizedBox(height: 8),
                  Text(opt["title"],
                      style: TextStyle(color: isSel ? Colors.white : (isDark ? Colors.white : AppTheme.navyDark), fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(opt["subtitle"] ?? "",
                      style: TextStyle(color: isSel ? Colors.white70 : AppTheme.greyText, fontSize: 10), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateSlider(bool isDark) {
    return SizedBox(
      height: 85,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14,
        itemBuilder: (context, index) {
          DateTime date = DateTime.now().add(Duration(days: index));
          bool isSel = DateUtils.isSameDay(date, selectedDate);
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() { selectedDate = date; selectedSlot = null; });
            },
            child: Container(
              width: 65,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSel ? AppTheme.primaryBlue : (isDark ? AppTheme.navyDark : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSel ? AppTheme.primaryBlue : (isDark ? Colors.white10 : AppTheme.borderGrey)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat('EEE').format(date),
                      style: TextStyle(color: isSel ? Colors.white70 : AppTheme.greyText, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(DateFormat('dd').format(date),
                      style: TextStyle(color: isSel ? Colors.white : (isDark ? Colors.white : AppTheme.navyDark), fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeGrid(bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12
      ),
      itemCount: pickupSlots.length,
      itemBuilder: (context, index) {
        String time = pickupSlots[index]["time"];
        String label = pickupSlots[index]["label"];
        bool isSel = selectedSlot == time;

        // 🔥 FIX: Morning slot dikhega par click nahi hoga agar time nikal gaya toh
        final startTimeStr = time.split(" - ")[0];
        final parsedTime = DateFormat("hh:mm a").parse(startTimeStr);
        DateTime slotTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, parsedTime.hour, parsedTime.minute);
        bool isPast = DateUtils.isSameDay(selectedDate, DateTime.now()) && slotTime.isBefore(DateTime.now());

        return GestureDetector(
          onTap: isPast ? null : () => setState(() => selectedSlot = time),
          child: Opacity(
            opacity: isPast ? 0.3 : 1.0, // 🔥 Gray dikhane ke liye
            child: Container(
              decoration: BoxDecoration(
                color: isSel ? AppTheme.primaryBlue : (isDark ? AppTheme.navyDark : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSel ? AppTheme.primaryBlue : (isDark ? Colors.white10 : AppTheme.borderGrey)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: TextStyle(color: isSel ? Colors.white70 : AppTheme.greyText, fontSize: 10)),
                  Text(time,
                      style: TextStyle(color: isSel ? Colors.white : (isDark ? Colors.white : AppTheme.navyDark), fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(double total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.navyDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔥 FIX: 100 calculation
                if (widget.itemTotal < 100)
                  Text("Add ₹${(100 - widget.itemTotal).toInt()} for FREE Delivery", style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                Text("₹${total.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
                const Text("Total Pay", style: TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.freshGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                minimumSize: const Size(0, 54),
              ),
              onPressed: _handleConfirm,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Confirm Order", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleConfirm() async {
    if (savedAddress == null) {
      _showSnackBar("Please select address", Colors.red);
      return;
    }

    if (selectedDeliveryMode != "premium" && selectedSlot == null) {
      _showSnackBar("Please select a time slot", Colors.red);
      return;
    }

    // 🔥 STEP 1: Loader dikhayein
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
    );

    try {
      // 🔥 STEP 2: Location Availability Check (5KM Logic)
      // Aapke savedAddress se Lat/Lng nikal kar backend bhejenge
      final double lat = savedAddress!.latitude ?? 0.0;
      final double lng = savedAddress!.longitude ?? 0.0;

      final availability = await ApiService.checkAreaAvailability(lat, lng);

      if (mounted) Navigator.pop(context); // Loader band karein

      if (availability['available'] == true) {
        // ✅ STEP 3: Agar area service mein hai, tabhi next screen par jayein
        DateTime pickupTime = (selectedDeliveryMode == "premium") ? DateTime.now() : _getCombinedDateTime();
        final selectedOpt = deliveryOptions.firstWhere((e) => e["mode_id"] == selectedDeliveryMode);

        Navigator.push(context, MaterialPageRoute(builder: (_) => OrderScreen(
          selectedItems: widget.selectedItems,
          pickupDateTimeString: pickupTime.toIso8601String(),
          finalAmount: widget.itemTotal + _getDeliveryCharge(),
          deliveryModeTitle: selectedOpt["title"],
          deliveryCharge: _getDeliveryCharge(),
          selectedAddress: savedAddress!,
        )));
      } else {
        // ❌ STEP 4: Agar area service mein nahi hai, toh Error dikhayein
        _showNotAvailableDialog(availability['message'] ?? "Currently not available in this area.");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnackBar("Error checking location. Please try again.", Colors.red);
    }
  }

// Helper for Snackbar
  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // Helper for Not Available Dialog
  void _showNotAvailableDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? AppTheme.navyDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          // 🔹 Title mein icon add kiya
          title: Row(
            children: [
              Text(
                  "Sorry! ",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.navyDark
                  )
              ),
              const Icon(Icons.sentiment_dissatisfied_outlined, color: Colors.orange, size: 28),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(color: isDark ? Colors.white70 : AppTheme.greyText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                  "Change Location",
                  style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddressSelection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.navyDark : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Select Delivery Address", style: TextStyle(color: isDark ? Colors.white : AppTheme.navyDark, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: addressList.length,
                itemBuilder: (context, index) {
                  final addr = addressList[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.location_on_outlined, color: AppTheme.primaryBlue),
                    title: Text("${addr.houseNo}, ${addr.street}", style: TextStyle(color: isDark ? Colors.white : AppTheme.navyDark)),
                    subtitle: Text("${addr.area}, ${addr.city}", style: const TextStyle(color: AppTheme.greyText)),
                    trailing: IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () {
                      Navigator.pop(context);
                      _showAddressFormBottomSheet(addressToEdit: addr);
                    }),
                    onTap: () async {
                      // 🔥 Master Fix: Instant Selection
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      await prefs.setString('saved_address_id', addr.id.toString());
                      setState(() {
                        savedAddress = addr;
                        selectedAddress = addr;
                      });
                      if (mounted) Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () { Navigator.pop(context); _showAddressFormBottomSheet(); }, icon: const Icon(Icons.add), label: const Text("Add New Address"))),
          ],
        ),
      ),
    );
  }

  void _showAddressFormBottomSheet({AddressModel? addressToEdit}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (addressToEdit != null) {
      _houseNoController.text = addressToEdit.houseNo ?? '';
      _streetController.text = addressToEdit.street ?? '';
      _areaController.text = addressToEdit.area ?? '';
      _cityController.text = addressToEdit.city ?? '';
      _stateController.text = addressToEdit.state ?? '';
      _pincodeController.text = addressToEdit.pincode ?? '';
    } else {
      _clearControllers();
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.navyDark : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(addressToEdit == null ? "Address Details" : "Edit Address", style: TextStyle(color: isDark ? Colors.white : AppTheme.navyDark, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              _buildTextField(_houseNoController, "House No", isDark),
              _buildTextField(_streetController, "Street", isDark),
              _buildTextField(_areaController, "Area", isDark),
              Row(
                children: [
                  Expanded(child: _buildTextField(_cityController, "City", isDark)),
                  const SizedBox(width: 10),
                  // 🔥 NAYA: State ka field add kar diya
                  Expanded(child: _buildTextField(_stateController, "State", isDark)),
                ],
              ),
              // Pincode ko ab alag line mein rakh diya
              _buildTextField(_pincodeController, "Pincode", isDark, isNumber: true),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () => _saveOrUpdateAddress(true, addressToEdit: addressToEdit),
                    child: const Text("Save Address", style: TextStyle(fontWeight: FontWeight.bold))
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: const Row(children: [
        Icon(Icons.bolt, color: Colors.green),
        SizedBox(width: 10),
        Expanded(child: Text("Premium delivery: Arrives within 6 hours after pickup.", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13))),
      ]),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, bool isDark, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller, keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: TextStyle(color: isDark ? Colors.white : AppTheme.navyDark),
        decoration: InputDecoration(
          labelText: label, labelStyle: const TextStyle(color: AppTheme.greyText), filled: true,
          fillColor: isDark ? Colors.white.withOpacity(0.05) : AppTheme.scaffoldBg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  void _pickCustomDate() async {
    DateTime? picked = await showDatePicker(
      context: context, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }
}