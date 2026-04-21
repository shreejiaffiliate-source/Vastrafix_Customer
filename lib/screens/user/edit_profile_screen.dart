import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/api_services.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController nameCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController phoneCtrl;

  File? image;
  String? networkImage;

  bool isSaving = false;

  // Base URL for profile images
  final String baseUrl = "https://www.vastrafix.shreejifintech.com/";

  @override
  void initState() {
    super.initState();
    // 🔥 Functionality from File 1: Controller Initialization
    nameCtrl = TextEditingController(text: widget.profile["username"] ?? "");
    emailCtrl = TextEditingController(text: widget.profile["email"] ?? "");
    phoneCtrl = TextEditingController(text: widget.profile["phone"] ?? "");

    String? img = widget.profile["profile_image"];
    if (img != null && img.isNotEmpty) {
      networkImage = img.startsWith("http") ? img : "$baseUrl$img";
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }

  // 🔥 Functionality from File 1: Image Picking Logic
  Future<void> pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked != null) {
      setState(() {
        image = File(picked.path);
      });
    }
  }

  void showImagePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.navyDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _pickerOption(Icons.camera_alt_rounded, "Camera", ImageSource.camera, isDark),
              _pickerOption(Icons.photo_library_rounded, "Gallery", ImageSource.gallery, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _pickerOption(IconData icon, String text, ImageSource source, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Future.delayed(const Duration(milliseconds: 300), () => pickImage(source));
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
            child: Icon(icon, color: AppTheme.primaryBlue, size: 30),
          ),
          const SizedBox(height: 10),
          Text(text,
              style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.navyDark,
                  fontWeight: FontWeight.bold
              )
          ),
        ],
      ),
    );
  }

  Future<void> save() async {
    FocusScope.of(context).unfocus();

    String nameText = nameCtrl.text.trim();
    String emailText = emailCtrl.text.trim().toLowerCase(); // Email hamesha lowercase mein
    String phoneText = phoneCtrl.text.trim();

    // ================== VALIDATION LOGIC ==================
    if (nameText.isEmpty) {
      _showError("Please enter your name");
      return;
    }

    // 🔥 NEW EMAIL VALIDATION
    if (emailText.isEmpty) {
      _showError("Please enter email");
      return;
    }

    // Aapka Regex Pattern
    String emailPattern = r"^[a-zA-Z0-9.]+@(gmail|yahoo|outlook|vastrafix|hotmail)\.(com|in|net|org|co\.in)$";
    RegExp regExp = RegExp(emailPattern);

    if (!regExp.hasMatch(emailText)) {
      _showError("Please enter a valid email (e.g. name@gmail.com)");
      return;
    }

    if (phoneText.isEmpty) {
      _showError("Please enter your phone number");
      return;
    }
    if (phoneText.length != 10) {
      _showError("Phone number must be exactly 10 digits");
      return;
    }
    // ======================================================

    String cleanUsername = nameText.replaceAll(" ", "_");
    setState(() => isSaving = true);

    try {
      final success = await ApiService.updateProfile(
        username: cleanUsername,
        email: emailText,
        phone: phoneText,
        image: image,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully! ✅"), backgroundColor: AppTheme.freshGreen),
        );
        Navigator.pop(context, true);
      } else {
        _showError("Update failed: Username might be taken or invalid");
      }
    } catch (e) {
      if (mounted) _showError("Error: Use letters, numbers or underscore only");
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  // Error dikhane ke liye ek chhota sa helper function
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating, // Thoda design achha karne ke liye
      ),
    );
  }

  // 🔹 UI from File 2: Branded Profile Image Stack
  Widget _buildProfileImage(bool isDark) {
    return GestureDetector(
      onTap: showImagePicker,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 140,
            width: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2), width: 4),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10)
                )
              ],
            ),
            child: ClipOval(
              child: image != null
                  ? Image.file(image!, fit: BoxFit.cover)
                  : (networkImage != null && networkImage!.isNotEmpty)
                  ? Image.network(
                networkImage!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _defaultAvatar(),
              )
                  : _defaultAvatar(),
            ),
          ),
          Positioned(
            bottom: 5,
            right: 5,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: AppTheme.borderGrey.withOpacity(0.2),
      child: const Icon(Icons.person, size: 70, color: AppTheme.borderGrey),
    );
  }

  // 🔹 UI from File 2: Branded Input Fields
  Widget _buildTextField(String label, IconData icon, TextEditingController controller, bool isDark,{TextInputType type = TextInputType.text, int? maxLength}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.greyText, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: type, // <--- NAYA: Number ya Text keyboard ke liye
          maxLength: maxLength, // <--- NAYA: 10 digit limit ke liye
          style: TextStyle(
              color: isDark ? Colors.white : AppTheme.navyDark,
              fontWeight: FontWeight.bold
          ),
          decoration: InputDecoration(
            counterText: "", // <--- NAYA: Niche 0/10 likha na aaye uske liye
            prefixIcon: Icon(icon, color: AppTheme.primaryBlue, size: 22),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : AppTheme.scaffoldBg,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.white10 : AppTheme.borderGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text("Edit Profile",
            style: TextStyle(color: isDark ? Colors.white : AppTheme.navyDark, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: isDark ? scaffoldBg : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: isDark ? Colors.white : AppTheme.navyDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 30),
            _buildProfileImage(isDark),
            const SizedBox(height: 16),
            const Text("Change Profile Picture",
                style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 40),

            _buildTextField("Full Name", Icons.person_outline_rounded, nameCtrl, isDark),
            const SizedBox(height: 20),
            _buildTextField("Email Address", Icons.email_outlined, emailCtrl, isDark, type: TextInputType.emailAddress),
            const SizedBox(height: 20),
            _buildTextField("Phone Number", Icons.phone_android_rounded, phoneCtrl, isDark, maxLength: 10),

            const SizedBox(height: 50),

            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.freshGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMedium)),
                  elevation: 0,
                ),
                child: const Text("Save Changes",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}