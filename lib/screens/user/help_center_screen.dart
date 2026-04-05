import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  int _selectedCategoryIndex = 0;

  final List<String> _categories = ['All', 'Orders', 'Payments', 'Delivery', 'Account'];

  final List<Map<String, String>> _allFaqs = [
    {'category': 'Orders', 'q': 'How do I place an order?', 'a': 'Go to Home → Select service → Add to cart → Confirm address → Place order.'},
    {'category': 'Orders', 'q': 'How can I track my order?', 'a': 'Open Order History → Tap on your order → View current status.'},
    {'category': 'Payments', 'q': 'What payment methods are available?', 'a': 'You can pay using UPI, Credit/Debit Card, or Cash on Delivery.'},
    {'category': 'Payments', 'q': 'Is my payment secure?', 'a': 'Yes, we use encrypted payment gateways to ensure your safety.'},
    {'category': 'Delivery', 'q': 'What are pickup timings?', 'a': 'Pickup is available between 9 AM to 7 PM.'},
    {'category': 'Delivery', 'q': 'When will I receive my clothes?', 'a': 'Usually within 24–48 hours depending on the service type.'},
    {'category': 'Account', 'q': 'How to update profile?', 'a': 'Go to Profile → Edit Profile → Save changes.'},
  ];

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _openWhatsApp() async {
    String phoneNumber = "919601591839";
    String message = "Hello VastraFix Support, I need help with my order.";
    final Uri whatsappAppUrl = Uri.parse("whatsapp://send?phone=$phoneNumber&text=${Uri.encodeComponent(message)}");
    final Uri whatsappWebUrl = Uri.parse("https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");

    try {
      if (await canLaunchUrl(whatsappAppUrl)) {
        await launchUrl(whatsappAppUrl);
      } else {
        await launchUrl(whatsappWebUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("WhatsApp error: $e");
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 Theme logic
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardTheme.color;

    List<Map<String, String>> displayedFaqs = _allFaqs.where((faq) {
      bool matchesCategory = _selectedCategoryIndex == 0 || faq['category'] == _categories[_selectedCategoryIndex];
      bool matchesSearch = faq['q']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          faq['a']!.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🟦 HERO SECTION
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  height: 220,
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 50),
                  decoration: const BoxDecoration(
                    color: AppTheme.navyDark,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(AppConstants.radiusLarge),
                      bottomRight: Radius.circular(AppConstants.radiusLarge),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Help Center",
                        style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                      ),
                      const Text(
                        "How can we help you today?",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),

                // 🔍 SEARCH BAR
                Positioned(
                  bottom: -25,
                  left: 20,
                  right: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 8)
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      // 🔹 FIX: Yahan direct Theme se color uthayein taaki koi mistake na ho
                      style: TextStyle(
                        color: isDark ? Colors.black : AppTheme.navyDark,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                      cursorColor: AppTheme.primaryBlue, // Cursor color bhi set kar dein
                      decoration: InputDecoration(
                        hintText: "Search issues...",
                        // 🔹 Hint color ko thoda light rakhein
                        hintStyle: TextStyle(color: isDark ? Colors.white54 : AppTheme.greyText),
                        prefixIcon: const Icon(Icons.search, color: AppTheme.primaryBlue),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                          icon: Icon(Icons.clear, color: isDark ? Colors.white70 : AppTheme.greyText),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = "");
                          },
                        )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 55),

            /// 🏷️ CATEGORY CHIPS
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  bool isSelected = _selectedCategoryIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategoryIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryBlue : cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? AppTheme.primaryBlue : (isDark ? Colors.white10 : AppTheme.borderGrey)),
                      ),
                      child: Center(
                        child: Text(
                          _categories[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppTheme.greyText),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            /// ❓ FAQ LIST
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedCategoryIndex == 0 ? "Popular Questions" : "${_categories[_selectedCategoryIndex]} FAQs",
                    style: TextStyle(color: isDark ? Colors.white : AppTheme.navyDark, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  if (displayedFaqs.isEmpty)
                    const Center(
                        child: Padding(
                            padding: EdgeInsets.all(40),
                            child: Text("No FAQs found", style: TextStyle(color: AppTheme.greyText))
                        )
                    )
                  else
                    ...displayedFaqs.map((faq) => _buildModernFaqTile(faq['q']!, faq['a']!, isDark)),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// 🎧 CONTACT SUPPORT CARD
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white10 : AppTheme.borderGrey),
                ),
                child: Column(
                  children: [
                    Text("Still need help?",
                        style: TextStyle(color: isDark ? Colors.white : AppTheme.navyDark, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text("Our support team is available for you",
                        style: TextStyle(color: AppTheme.greyText, fontSize: 14)),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _contactButton(
                            iconWidget: const Icon(FontAwesomeIcons.whatsapp, size: 18),
                            label: "WhatsApp",
                            color: AppTheme.freshGreen,
                            onTap: () => _openWhatsApp(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _contactButton(
                            iconWidget: const Icon(Icons.phone_in_talk_rounded, size: 18),
                            label: "Call Us",
                            color: AppTheme.primaryBlue,
                            onTap: () => _launchURL("tel:+919054648658"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildModernFaqTile(String question, String answer, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : AppTheme.borderGrey),
      ),
      child: Theme(
        data: ThemeData().copyWith(
          dividerColor: Colors.transparent,
          // 🔹 FIX: ExpansionTile theme inside dark mode
          unselectedWidgetColor: AppTheme.greyText,
        ),
        child: ExpansionTile(
          iconColor: AppTheme.primaryBlue,
          collapsedIconColor: AppTheme.greyText,
          title: Text(question,
              style: TextStyle(color: isDark ? Colors.white : AppTheme.navyDark, fontWeight: FontWeight.w600, fontSize: 15)),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Text(answer, style: const TextStyle(color: AppTheme.greyText, fontSize: 14, height: 1.4)),
            )
          ],
        ),
      ),
    );
  }

  Widget _contactButton({
    required Widget iconWidget, // 🔹 IconData ki jagah Widget use kiya
    required String label,
    required Color color,
    required VoidCallback onTap
  }) {
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onTap,
        // 🔹 Icon widget yahan set hoga
        icon: SizedBox(width: 18, height: 18, child: iconWidget),
        label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}