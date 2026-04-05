import 'package:flutter/material.dart';
import '../../core/api_services.dart';
import '../../models/item_model.dart';
import '../../models/sub_category_model.dart';
import '../../models/cart_item_model.dart';
import 'pickup_details_screen.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';

class SteamIronScreen extends StatefulWidget {
  final String serviceName;
  final VoidCallback onBack;
  final String searchQuery;

  const SteamIronScreen({
    super.key,
    required this.serviceName,
    required this.onBack,
    required this.searchQuery,
  });

  @override
  State<SteamIronScreen> createState() => _SteamIronScreenState();
}

class _SteamIronScreenState extends State<SteamIronScreen> {
  late String selectedService;
  List<SubCategoryModel> allItems = [];
  bool isLoading = true;

  final List<CartItem> cartItems = [];
  final Map<String, Map<int, int>> serviceQuantities = {};
  final Map<String, bool> expandedSections = {};

  @override
  void initState() {
    super.initState();
    selectedService = widget.serviceName;
    fetchItems(selectedService);
  }

  @override
  void didUpdateWidget(covariant SteamIronScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.serviceName != widget.serviceName) {
      setState(() {
        selectedService = widget.serviceName;
      });
      fetchItems(selectedService);
    }

    if (oldWidget.searchQuery != widget.searchQuery) {
      setState(() {
        // 🔹 FIX: Search query hone par sections auto expand honge
        if (widget.searchQuery.isNotEmpty) {
          expandedSections.updateAll((key, value) => true);
        }
      });
    }
  }

  Map<int, int> get currentQuantities => serviceQuantities.putIfAbsent(selectedService, () => {});

  Future<void> fetchItems(String service) async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService.getItemsByService(service);
      if (!mounted) return;
      setState(() {
        allItems = response;
        expandedSections.clear();
        for (var sub in allItems) {
          expandedSections[sub.name] = false;
        }
        isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _addOrUpdateCart(Items item, int qty) {
    final index = cartItems.indexWhere((c) => c.id == item.id && c.service == selectedService);
    if (index != -1) {
      cartItems[index].quantity = qty;
    } else {
      cartItems.add(CartItem(
        id: item.id,
        name: item.name,
        service: selectedService,
        price: item.price,
        quantity: qty,
      ));
    }
  }

  void _removeFromCart(Items item) {
    cartItems.removeWhere((c) => c.id == item.id && c.service == selectedService);
  }

  double get totalAmount => cartItems.fold(0, (sum, i) => sum + i.total);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // 🔹 Theme integration
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : _content(),
      bottomNavigationBar: cartItems.isEmpty
          ? null
          : _buildCartBottomBar(isDark),
    );
  }

  Widget _buildCartBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.navyDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppConstants.radiusLarge)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10)],
      ),
      child: SafeArea(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.freshGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMedium)),
            // 🔹 FIX: Row ke andar infinite width crash se bachne ke liye
            minimumSize: const Size(0, 56),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PickupDetailsScreen(
                  selectedItems: cartItems,
                  itemTotal: totalAmount,
                ),
              ),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${cartItems.length} Items Selected",
                      style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  Text("₹${totalAmount.toStringAsFixed(0)}",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                ],
              ),
              const Row(
                children: [
                  Text("Checkout", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content() {
    if (allItems.isEmpty) {
      return const Center(
          child: Text("No items found", style: TextStyle(color: AppTheme.greyText)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: allItems.length,
      itemBuilder: (context, index) => _section(allItems[index]),
    );
  }

  Widget _section(SubCategoryModel sub) {
    final expanded = expandedSections[sub.name] ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final visibleItems = sub.items.where((item) =>
    widget.searchQuery.isEmpty ||
        item.name.toLowerCase().contains(widget.searchQuery.toLowerCase())
    ).toList();

    if (visibleItems.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color, // 🔹 Theme Card Color
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppTheme.borderGrey.withOpacity(isDark ? 0.1 : 0.5)),
        boxShadow: [
          if(!isDark) BoxShadow(
            color: AppTheme.navyDark.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            title: Text(sub.name,
                style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.navyDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 16
                )),
            trailing: Icon(
              expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: AppTheme.primaryBlue,
            ),
            onTap: () {
              setState(() {
                expandedSections[sub.name] = !expanded;
              });
            },
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  ...visibleItems.map(_itemRow),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _itemRow(Items item) {
    final qty = currentQuantities[item.id] ?? 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.navyDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 15
                    )),
                const SizedBox(height: 2),
                Text("₹${item.price}",
                    style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          qty == 0
              ? SizedBox(
            width: 90,
            height: 36,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppTheme.navyDark : Colors.white,
                foregroundColor: AppTheme.freshGreen,
                side: const BorderSide(color: AppTheme.freshGreen),
                elevation: 0,
                minimumSize: const Size(0, 36), // 🔹 Safe width
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                setState(() {
                  currentQuantities[item.id] = 1;
                  _addOrUpdateCart(item, 1);
                });
              },
              child: const Text("ADD", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
              : Container(
            width: 100,
            decoration: BoxDecoration(
              color: AppTheme.freshGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _qtyBtn(Icons.remove, () {
                  setState(() {
                    if (qty > 1) {
                      currentQuantities[item.id] = qty - 1;
                      _addOrUpdateCart(item, qty - 1);
                    } else {
                      currentQuantities.remove(item.id);
                      _removeFromCart(item);
                    }
                  });
                }),
                Text("$qty",
                    style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.navyDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 15
                    )),
                _qtyBtn(Icons.add, () {
                  setState(() {
                    currentQuantities[item.id] = qty + 1;
                    _addOrUpdateCart(item, qty + 1);
                  });
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, color: AppTheme.freshGreen, size: 18),
      ),
    );
  }
}