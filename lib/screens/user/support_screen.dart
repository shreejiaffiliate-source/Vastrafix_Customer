import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/api_services.dart';
import '../../core/theme.dart';
import 'help_center_screen.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  // Logic: Functional URL launching
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Error launching URL: $e");
    }
  }

  // Logic: WhatsApp redirect
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

  // UI + Logic: Complaint Bottom Sheet
  void _showComplaintSheet(BuildContext context) {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.navyDark : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24, right: 24, top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.borderGrey, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            Text("Raise a Complaint",
                style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.navyDark,
                    fontSize: 22,
                    fontWeight: FontWeight.w900
                )),
            const SizedBox(height: 8),
            const Text("Our team will solve your issue as soon as possible.",
                style: TextStyle(color: AppTheme.greyText, fontSize: 14)),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              maxLines: 4,
              style: TextStyle(color: isDark ? Colors.white : AppTheme.navyDark),
              decoration: InputDecoration(
                hintText: "Issue details yahan likhein...",
                hintStyle: const TextStyle(color: AppTheme.greyText),
                filled: true,
                fillColor: isDark ? Colors.white.withOpacity(0.05) : AppTheme.scaffoldBg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () async {
                  if (controller.text.trim().isEmpty) return;
                  bool success = await ApiService.raiseComplaint(controller.text.trim());
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? "Submitted Successfully!" : "Failed to submit."),
                        backgroundColor: success ? AppTheme.freshGreen : Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: const Text("Submit Ticket",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          /// 🟦 BRANDED SLIVER APPBAR (Black Screen Fix: Added canPop check)
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            stretch: true,
            backgroundColor: AppTheme.navyDark,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text("Support Center",
                  style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
              background: Container(
                decoration: const BoxDecoration(color: AppTheme.navyDark),
                child: Stack(
                  children: [
                    Positioned(
                      top: 40, right: -20,
                      child: CircleAvatar(radius: 80, backgroundColor: Colors.white.withOpacity(0.05)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          /// 📋 CONTENT SECTION (Fixed using SliverToBoxAdapter for stability)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Instant Help",
                      style: TextStyle(
                          color: isDark ? Colors.white : AppTheme.navyDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w900
                      )),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildQuickAction(
                        context,
                        title: "WhatsApp",
                        icon: FontAwesomeIcons.whatsapp,
                        color: AppTheme.freshGreen,
                        onTap: _openWhatsApp,
                      ),
                      const SizedBox(width: 15),
                      _buildQuickAction(
                        context,
                        title: "Call Us",
                        icon: Icons.phone_in_talk_rounded,
                        color: AppTheme.primaryBlue,
                        onTap: () => _launchURL("tel:+919054648658"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text("Self Service Options",
                      style: TextStyle(
                          color: isDark ? Colors.white : AppTheme.navyDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w900
                      )),
                  const SizedBox(height: 16),
                  _buildModernTile(
                    context,
                    title: "Help Center / FAQs",
                    desc: "Common queries ke turant jawab payein",
                    icon: Icons.auto_stories_outlined,
                    onTap: () {
                      // 🔹 Smooth Navigation
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
                      );
                    },
                  ),
                  _buildModernTile(
                    context,
                    title: "Raise a Complaint",
                    desc: "Humein batayein kya galat hua",
                    icon: Icons.assignment_late_outlined,
                    onTap: () => _showComplaintSheet(context),
                  ),
                  const SizedBox(height: 40),
                  const Center(
                    child: Text(
                      "App Version 1.0.0 • Made with ❤ for VastraFix",
                      style: TextStyle(color: AppTheme.greyText, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.navyDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white12 : AppTheme.borderGrey),
            boxShadow: [
              if (!isDark) BoxShadow(color: AppTheme.navyDark.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.navyDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTile(BuildContext context, {
    required String title,
    required String desc,
    required IconData icon,
    required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.navyDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : AppTheme.borderGrey),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : AppTheme.scaffoldBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue),
        ),
        title: Text(title,
            style: TextStyle(color: isDark ? Colors.white : AppTheme.navyDark, fontWeight: FontWeight.bold)),
        subtitle: Text(desc,
            style: const TextStyle(color: AppTheme.greyText, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.greyText),
      ),
    );
  }
}