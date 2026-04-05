import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

import '../auth/login_screen.dart';
import '../orders/order_history_screen.dart';
import '../user/support_screen.dart';
import '../../core/api_services.dart';
import 'edit_profile_screen.dart';
import '../../core/theme.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String baseUrl = "https://www.vastrafix.shreejifintech.com/";
  Map<String, dynamic>? userProfile;
  bool isLoading = true;

  // 🔥 Address Form Controllers
  final _houseNoController = TextEditingController();
  final _streetController = TextEditingController();
  final _areaController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadProfile();
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

  void _clearControllers() {
    _houseNoController.clear();
    _streetController.clear();
    _areaController.clear();
    _cityController.clear();
    _stateController.clear();
    _pincodeController.clear();
  }

  Future<void> loadProfile() async {
    final data = await ApiService.getUserProfile();
    if (!mounted) return;
    setState(() {
      userProfile = data;
      isLoading = false;
    });
  }

  // 🔥 Geocoding Logic from File 1
  Future<Map<String, double?>> _getLatLong() async {
    double? lat; double? lng;
    String fullAddress = "${_houseNoController.text}, ${_streetController.text}, ${_areaController.text}, ${_cityController.text}, ${_pincodeController.text}";
    try {
      List<Location> locations = await locationFromAddress(fullAddress);
      if (locations.isNotEmpty) {
        lat = locations.first.latitude;
        lng = locations.first.longitude;
      }
    } catch (_) {
      try {
        String shortAddress = "${_areaController.text}, ${_cityController.text}";
        List<Location> fallback = await locationFromAddress(shortAddress);
        if (fallback.isNotEmpty) {
          lat = fallback.first.latitude; lng = fallback.first.longitude;
        }
      } catch (e) { debugPrint("Geocoding failed: $e"); }
    }
    return {'lat': lat, 'lng': lng};
  }

  // 🔥 Master Submit Handler (Add/Update)
  Future<void> _handleAddressSubmit({required bool isEditing, int? addressId}) async {
    if (_houseNoController.text.trim().isEmpty || _pincodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Required fields missing")));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saving location details...")));
    final coords = await _getLatLong();

    final data = {
      "house_no": _houseNoController.text.trim(),
      "street": _streetController.text.trim(),
      "area": _areaController.text.trim(),
      "city": _cityController.text.trim(),
      "state": _stateController.text.trim(),
      "pincode": _pincodeController.text.trim(),
      "latitude": coords['lat'],
      "longitude": coords['lng'],
    };

    try {
      bool success = false;
      if (isEditing && addressId != null) {
        success = await ApiService.updateAddress(addressId, data);
      } else {
        final id = await ApiService.createAddress(data);
        success = id != null;
      }

      if (success) {
        if (mounted) Navigator.pop(context);
        loadProfile();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEditing ? "Updated" : "Saved"), backgroundColor: AppTheme.freshGreen));
      }
    } catch (e) { debugPrint("Error: $e"); }
  }

  Future<void> _deleteAddress(int addressId) async {
    final confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Address?"),
        content: const Text("Remove this from your saved locations?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Deleting...")));
      final success = await ApiService.deleteAddress(addressId);
      if (success) {
        Navigator.of(context).pop();
        loadProfile();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Address removed")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text("My Account", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.navyDark)),
        centerTitle: false,
        backgroundColor: isDark ? scaffoldBg : Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : userProfile == null
          ? const Center(child: Text("Unable to load profile"))
          : SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildUserCard(isDark),
            const SizedBox(height: 30),
            _buildSectionLabel("Activity"),
            _buildActionRow(isDark),
            const SizedBox(height: 30),
            _buildSectionLabel("General Preferences"),
            _buildSettingsList(isDark),
            const SizedBox(height: 40),
            _buildSignOutButton(),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.navyDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : AppTheme.borderGrey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          _buildProfileImage(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userProfile!["username"] ?? "User",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: isDark ? Colors.white : AppTheme.navyDark)),
                Text(userProfile!["email"] ?? "",
                    style: TextStyle(color: isDark ? Colors.white70 : AppTheme.greyText, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return Container(
      width: 75, height: 75,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2), width: 3),
      ),
      child: ClipOval(
        child: userProfile!["profile_image"] != null
            ? Image.network("$baseUrl${userProfile!["profile_image"]}", fit: BoxFit.cover)
            : const Icon(Icons.person, color: AppTheme.primaryBlue, size: 40),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(text.toUpperCase(),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.primaryBlue, letterSpacing: 1.5)),
    );
  }

  Widget _buildActionRow(bool isDark) {
    return Row(
      children: [
        _actionCard(Icons.shopping_bag_outlined, "Orders", isDark, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen()));
        }),
        const SizedBox(width: 12),
        _actionCard(Icons.badge_outlined, "Edit Info", isDark, () async {
          final updated = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(profile: userProfile!)));
          if (updated == true) loadProfile();
        }),
      ],
    );
  }

  Widget _actionCard(IconData icon, String label, bool isDark, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
              color: isDark ? AppTheme.navyDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : AppTheme.borderGrey.withOpacity(0.5))
          ),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primaryBlue, size: 28),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : AppTheme.navyDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsList(bool isDark) {
    return Column(
      children: [
        _settingsTile(
          icon: isDark ? Icons.dark_mode : Icons.light_mode,
          title: "Dark Appearance",
          isDark: isDark,
          trailing: Switch.adaptive(
            value: isDark,
            activeColor: AppTheme.freshGreen,
            onChanged: (val) {
              AppTheme.themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
              setState(() {});
            },
          ),
        ),
        _settingsTile(
            icon: Icons.location_on_outlined,
            title: "Manage Addresses",
            isDark: isDark,
            onTap: () => _showAddressesBottomSheet(isDark)
        ),
        _settingsTile(
            icon: Icons.notifications_none_outlined,
            title: "Notifications",
            isDark: isDark,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
            }),
        _settingsTile(
            icon: Icons.help_outline_rounded,
            title: "Help & Support",
            isDark: isDark,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()));
            }),
      ],
    );
  }

  Widget _settingsTile({required IconData icon, required String title, required bool isDark, Widget? trailing, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        tileColor: isDark ? AppTheme.navyDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(icon, color: AppTheme.primaryBlue, size: 22),
        title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: isDark ? Colors.white : AppTheme.navyDark)),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.greyText),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return Center(
      child: TextButton(
        onPressed: () => _showLogoutConfirmation(), // Alag function call kiya
        child: const Text(
            "Logout",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
        ),
      ),
    );
  }

  // 🔥 Logout Confirmation Dialog Function
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) { // 🔹 Dialog ka apna context
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? AppTheme.navyDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Logout",
              style: TextStyle(color: isDark ? Colors.white : AppTheme.navyDark, fontWeight: FontWeight.bold)),
          content: Text("Are you sure you want to logout from VastraFix?",
              style: TextStyle(color: isDark ? Colors.white70 : AppTheme.greyText)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("No", style: TextStyle(color: AppTheme.greyText, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                // 1. Pehle Navigator ka reference save kar lo (Context Error se bachne ke liye)
                final navigator = Navigator.of(context);

                // 2. Dialog band karo
                navigator.pop();

                try {
                  // 3. Logout API calls
                  await ApiService.updateFCMToken("");
                  await FirebaseMessaging.instance.deleteToken();
                  await ApiService.logout();
                  debugPrint("✅ Data Cleared Successfully");
                } catch (e) {
                  debugPrint("❌ Logout Error: $e");
                  await ApiService.logout(); // Error mein bhi local clear karo
                }

                // 4. ✅ SAFE NAVIGATION (MaterialPageRoute use karo named ki jagah agar error aa rahi hai)
                if (mounted) {
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginCustomerScreen()),
                        (route) => false,
                  );
                }
              },
              child: const Text("Yes, Logout"),
            ),
          ],
        );
      },
    );
  }

  // 🔥 Address Bottom Sheets Fixed
  void _showAddressesBottomSheet(bool isDark) {
    final List addresses = userProfile!["addresses"] ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.navyDark : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("My Locations", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.navyDark)),
            const SizedBox(height: 20),
            if (addresses.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No saved addresses")))
            else
              ...addresses.map((addr) => _buildAddressTile(addr, isDark)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () { Navigator.pop(context); _showAddressFormSheet(isEditing: false, isDark: isDark); },
                icon: const Icon(Icons.add),
                label: const Text("Add New Address"),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressTile(Map<String, dynamic> addr, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : AppTheme.scaffoldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : AppTheme.borderGrey.withOpacity(0.1)),
      ),
      child: ListTile(
        title: Text("${addr['house_no']}, ${addr['city']}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : AppTheme.navyDark)),
        subtitle: Text("${addr['area']}, ${addr['pincode']}", style: const TextStyle(fontSize: 12, color: AppTheme.greyText)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryBlue),
                onPressed: () { Navigator.pop(context); _showAddressFormSheet(isEditing: true, addressId: addr['id'], existingData: addr, isDark: isDark); }),
            IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: () => _deleteAddress(addr['id'])),
          ],
        ),
      ),
    );
  }

  void _showAddressFormSheet({required bool isEditing, int? addressId, Map<String, dynamic>? existingData, required bool isDark}) {
    if (isEditing && existingData != null) {
      _houseNoController.text = existingData['house_no'] ?? '';
      _streetController.text = existingData['street'] ?? '';
      _areaController.text = existingData['area'] ?? '';
      _cityController.text = existingData['city'] ?? '';
      _stateController.text = existingData['state'] ?? '';
      _pincodeController.text = existingData['pincode']?.toString() ?? '';
    } else { _clearControllers(); }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.navyDark : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isEditing ? "Edit Address" : "New Address", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : AppTheme.navyDark)),
              const SizedBox(height: 20),
              // 🔥 Sahi Sequence: House -> Street -> Area
              _buildFormTextField(_houseNoController, "House/Flat No", isDark),
              _buildFormTextField(_streetController, "Street Name", isDark),
              _buildFormTextField(_areaController, "Area/Locality", isDark),

              // 🔥 City & State ek line mein
              Row(children: [
                Expanded(child: _buildFormTextField(_cityController, "City", isDark)),
                const SizedBox(width: 10),
                Expanded(child: _buildFormTextField(_stateController, "State", isDark)),
              ]),
              // 🔥 Pincode full width
              _buildFormTextField(_pincodeController, "Pincode", isDark, isNumber: true),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => _handleAddressSubmit(isEditing: isEditing, addressId: addressId),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: Text(isEditing ? "Update" : "Save Address"),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormTextField(TextEditingController controller, String label, bool isDark, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: TextStyle(color: isDark ? Colors.white : AppTheme.navyDark),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppTheme.greyText),
          filled: true,
          fillColor: isDark ? Colors.white.withOpacity(0.05) : AppTheme.scaffoldBg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

}