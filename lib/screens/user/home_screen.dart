import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // 👈 NAYA PACKAGE
import '../../core/navigation_service.dart'; // 👈 File ke top par import karein
import 'package:firebase_messaging/firebase_messaging.dart';
// Internal Project Imports
import '../../core/api_services.dart';
import '../../models/category_model.dart';
import '../../models/banner_model.dart';
import '../auth/login_screen.dart';
import '../category/steam_iron_screen.dart';
import '../orders/order_view_screen.dart';
import 'support_screen.dart';
import 'profile_screen.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import 'notifications_screen.dart';
import '../auth/custom_error_screen.dart'; // 👈 ISKO APNE FOLDER KE HISAB SE SET KAREIN

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final String baseUrl = "https://www.vastrafix.shreejifintech.com/";
  Timer? notificationTimer;
  Map<String, dynamic>? userProfile;
  int notificationCount = 0;
  int selectedIndex = 0;
  late Future<List<CategoryModel>> futureCategories;
  late Future<List<BannerModel>> futureBanners;
  String userName = "";

  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;
  bool _isAutoSlideStarted = false;

  final TextEditingController _searchController = TextEditingController();
  String selectedCategory = "All";
  String _searchQuery = "";

  // 👈 NAYA: Internet Connection Variables
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isShowingNoInternetScreen = false;
  bool _isShowingServerErrorScreen = false; // 👈 NAYA VARIABLE

  @override
  void initState() {
    super.initState();
    _initConnectivityListener();
    _fetchInitialData();

    _pageController = PageController(viewportFraction: 1.0);
    selectedCategory = "All";

    notificationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      loadNotificationCount();
    });

    // 🔥 NAYA: App start hote hi check karo kya jeb mein koi ID padi hai?
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingNavigation();
    });
  }

  // 🔥 NAYA FUNCTION
  void _checkPendingNavigation() {
    // Agar koi pending order ID hai jo main.dart ne save ki thi
    if (pendingOrderIdToNavigate != null) {
      String orderIdToOpen = pendingOrderIdToNavigate!;
      pendingOrderIdToNavigate = null; // Ek baar use karke delete kar do taaki baar-baar na khule

      print("🔥 HOME SCREEN: Pending ID mili -> $orderIdToOpen. Navigating...");

      // 500ms ka chhota wait taaki screen theek se load ho jaye
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pushNamed(context, '/order_detail', arguments: orderIdToOpen);
        }
      });
    }
  }

  void _fetchInitialData() async {
    try {
      setState(() {
        futureCategories = ApiService.getAllCategories();
        futureBanners = ApiService.getBanners();
      });

      // 👈 NAYA: Yahan hum API ka wait kar rahe hain error check karne ke liye
      await futureCategories;
      await futureBanners;

      loadUserName();
      loadProfile();
      loadNotificationCount();

    } catch (e) {
      print("Server is Down: $e");

      // Agar internet chalu hai, par data nahi aaya, matlab Server Down hai!
      if (!_isShowingNoInternetScreen && !_isShowingServerErrorScreen) {
        _isShowingServerErrorScreen = true;
        _showServerErrorScreen(); // Server wali screen dikhao
      }
    }
  }

  // 👈 NAYA: Internet Listener Logic
  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      bool hasInternet = !results.contains(ConnectivityResult.none);

      if (!hasInternet && !_isShowingNoInternetScreen) {
        _isShowingNoInternetScreen = true;
        _showNoInternetScreen();
      } else if (hasInternet && _isShowingNoInternetScreen) {
        _isShowingNoInternetScreen = false;
        Navigator.of(context, rootNavigator: true).pop(); // Error screen hatao
        _fetchInitialData(); // Data wapas load karo
      }
    });
  }

  void _showNoInternetScreen() {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => CustomErrorScreen(
          errorIcon: Icons.wifi_off_rounded, // 👈 Yahan Icon set kar diya
          title: 'OOPS!\nNO INTERNET',
          subtitle: "Clothes can't be washed without water, and Vastrafix can't work without internet! Please check your connection.",
          onTryAgain: () async {
            var results = await Connectivity().checkConnectivity();
            if (!results.contains(ConnectivityResult.none)) {
              _isShowingNoInternetScreen = false;
              if(context.mounted) Navigator.pop(context);
              _fetchInitialData();
            }
          },
        ),
      ),
    );
  }

  void _showServerErrorScreen() {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => CustomErrorScreen(
          errorIcon: Icons.dns_outlined, // 👈 Server ka Icon (Cloud ya DNS)
          title: 'OOPS!\nSERVER DOWN',
          subtitle: 'Our servers are currently overloaded with laundry or are in a bind. Please try again later.',
          onTryAgain: () {
            _isShowingServerErrorScreen = false;
            if (context.mounted) Navigator.pop(context); // Error screen band karo
            _fetchInitialData(); // Wapas API hit karke check karo
          },
        ),
      ),
    ).then((_) {
      // Agar user mobile ka back button dabata hai
      _isShowingServerErrorScreen = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    notificationTimer?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    _connectivitySubscription.cancel(); // 👈 NAYA: Memory leak se bachne ke liye
    super.dispose();
  }

  void loadUserName() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        String? name = prefs.getString("user_name");
        userName = (name != null && name.isNotEmpty) ? name : "Customer";
      });
    }
  }

  Future<void> loadNotificationCount() async {
    try {
      final count = await ApiService.getNotificationCount();
      if (mounted) setState(() => notificationCount = count);
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
    }
  }

  String city = "Select Location";

  Future<void> loadProfile() async {
    final data = await ApiService.getUserProfile();

    if (!mounted) return;

    // Handle expired token or missing data
    if (data == null) {
      print("🚨 Profile data is null. Token may have expired. Redirecting to Login...");

      await ApiService.logout();

      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginCustomerScreen()),
            (route) => false,
      );
      return;
    }

    // Update state with valid profile data
    setState(() {
      userProfile = data;
      if (data["addresses"] != null && data["addresses"].isNotEmpty) {
        city = data["addresses"][0]["city"];
      } else {
        city = "Select Location";
      }
    });
  }

  void startAutoSlide(int bannerLength) {
    if (_isAutoSlideStarted || bannerLength <= 1) return;
    _isAutoSlideStarted = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _currentPage++;
        if (_currentPage >= bannerLength) _currentPage = 0;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  IconData getIconData(String iconName) {
    switch (iconName.toLowerCase().trim()) {
      case 'iron': return Icons.iron;
      case 'local_laundry_service': return Icons.local_laundry_service;
      case 'dry_cleaning': return Icons.dry_cleaning;
      case 'checkroom': return Icons.checkroom;
      case 'roller_shades': return Icons.roller_shades;
      default: return Icons.category;
    }
  }

  void _changeCategory(String newCategory) {
    setState(() {
      selectedCategory = newCategory;
      _searchController.clear();
      _searchQuery = "";
    });
  }

  Future<bool> _showExitDialog() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Exit App?"),
        content: const Text("Do you want to opt out of Vastrafix?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("No", style: TextStyle(color: AppTheme.primaryBlue)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Yes", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
  }

  // ================= HOME CONTENT =================
  Widget homeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. SEARCH BAR
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
                if (value.isNotEmpty && selectedCategory == "All") {
                  selectedCategory = "Steam Iron"; // Aapki main search screen ka naam
                }

                // Agar user pura clear kar de, toh wapas "All" par aa jaye (Optional)
                else if (value.isEmpty && selectedCategory == "Steam Iron") {
                  selectedCategory = "All";
                }
              });
            },
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              hintText: 'Search "Shirt","T-shirt","Saree"...',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: AppTheme.primaryBlue),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black
                  : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),

        // 2. HORIZONTAL CATEGORIES
        FutureBuilder<List<CategoryModel>>(
          future: futureCategories,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
            final categories = snapshot.data!;
            return SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: categories.length + 1,
                itemBuilder: (context, index) {
                  bool isAll = index == 0;
                  String name = isAll ? "All" : categories[index - 1].name;
                  IconData icon = isAll ? Icons.apps : getIconData(categories[index - 1].icon);
                  return _buildTopTab(icon, name, selectedCategory == name, () => _changeCategory(name));
                },
              ),
            );
          },
        ),

        const Divider(color: AppTheme.borderGrey, height: 1),

        // 3. DYNAMIC CONTENT
        Expanded(
          child: selectedCategory == "All"
              ? RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _fetchInitialData();
              });
            },
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              child: Column(
                children: [
                  _buildAllMainContent(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          )
              : SteamIronScreen(
            serviceName: selectedCategory,
            searchQuery: _searchQuery,
            onBack: () => _changeCategory("All"),
          ),
        ),
      ],
    );
  }

  Widget _buildAllMainContent() {
    return Column(
      children: [
        // BANNER SLIDER
        FutureBuilder<List<BannerModel>>(
          future: futureBanners,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox(height: 10);
            final banners = snapshot.data!;
            startAutoSlide(banners.length);
            return Container(
              height: 160,
              margin: const EdgeInsets.symmetric(vertical: 16),
              child: PageView.builder(
                controller: _pageController,
                itemCount: banners.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                    child: Image.network(banners[index].image, fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Agar image load na ho toh (Server Down/Net Issue)
                        return Container(color: Colors.grey.shade300, child: const Icon(Icons.broken_image));
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // GRID SECTION
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildTallCard(() => _changeCategory("Dry Cleaning"))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    _buildSquareCard("Wash & Iron", "Daily Essentials", Icons.local_laundry_service, () => _changeCategory("Wash & Iron")),
                    const SizedBox(height: 12),
                    _buildSquareCard("Steam Press", "Crisp & Sharp", Icons.iron, () => _changeCategory("Steam Iron")),
                  ],
                ),
              )
            ],
          ),
        ),

        const SizedBox(height: 16),

        // PROMO STRIP
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.freshGreen,
              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
            ),
            child: const Row(
              children: [
                Icon(Icons.local_shipping, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "FREE Pickup & Drop on orders above ₹100",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 30),
        const Text("PREMIUM SERVICES", style: TextStyle(color: AppTheme.navyDark, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(child: _buildBottomServiceCard("Saree Rolling", Icons.dry_cleaning, () => _changeCategory("Saree Rolling"))),
              const SizedBox(width: 12),
              Expanded(child: _buildBottomServiceCard("Wash & Fold", Icons.checkroom, () => _changeCategory("Wash & Fold"))),
            ],
          ),
        ),
      ],
    );
  }

  // ================= THEMED WIDGETS =================

  Widget _buildTopTab(IconData icon, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryBlue : Colors.white,
                shape: BoxShape.circle,
                boxShadow: isSelected ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Icon(icon, color: isSelected ? Colors.white : AppTheme.primaryBlue, size: 24),
            ),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: isSelected ? AppTheme.primaryBlue : AppTheme.greyText, fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildTallCard(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 255,
        decoration: BoxDecoration(
          color: AppTheme.navyDark,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("SPECIAL OFFER", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
            const Text("DRY CLEAN", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            const Spacer(),
            Icon(Icons.checkroom, size: 70, color: Colors.white.withOpacity(0.2)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: AppTheme.freshGreen, borderRadius: BorderRadius.circular(8)),
              child: const Text("FROM ₹129", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSquareCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Container(
          height: 121,
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: AppTheme.primaryBlue),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(color: AppTheme.navyDark, fontSize: 13, fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(color: AppTheme.greyText, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomServiceCard(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(color: AppTheme.borderGrey),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.freshGreen, size: 28),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: AppTheme.navyDark, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      homeContent(),
      const OrdersViewScreen(),
      const SupportScreen(),
      const ProfileScreen()
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (selectedIndex != 0) {
          setState(() => selectedIndex = 0);
          return;
        }

        final shouldExit = await _showExitDialog();
        if (shouldExit && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: selectedIndex == 0 ? _buildAppBar() : null,
        body: pages[selectedIndex],
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      toolbarHeight: 80,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("VastraFix", style: TextStyle(color: AppTheme.primaryBlue, fontSize: 14, fontWeight: FontWeight.bold)),
          Text(
            city,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppTheme.navyDark,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),Text("Welcome, ${userName.isNotEmpty ? userName : 'Customer'}", style: const TextStyle(fontSize: 12, color: AppTheme.greyText)),
        ],
      ),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_outlined, size: 28),
              onPressed: () async {
                setState(() => notificationCount = 0);
                await ApiService.markNotificationsRead();
                if (mounted) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()));
                  loadNotificationCount();
                }
              },
            ),
            if (notificationCount > 0)
              Positioned(
                right: 8,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text('$notificationCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
          child: CircleAvatar(
            backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
            child: ClipOval(
              child: userProfile != null && userProfile!["profile_image"] != null
                  ? Image.network("$baseUrl${userProfile!["profile_image"]}", fit: BoxFit.cover, width: 40, height: 40)
                  : const Icon(Icons.person_outline, color: AppTheme.primaryBlue),
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      type: BottomNavigationBarType.fixed,
      onTap: (index) async {
        setState(() => selectedIndex = index);
        if (index == 0 || index == 3) await loadProfile();
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: "Orders"),
        BottomNavigationBarItem(icon: Icon(Icons.support_agent), label: "Support"),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
      ],
    );
  }

  void resetToAll() {
    if (mounted) {
      setState(() {
        selectedCategory = "All";
        _searchQuery = "";
        _searchController.clear();
        selectedIndex = 0;
      });
    }
  }
}