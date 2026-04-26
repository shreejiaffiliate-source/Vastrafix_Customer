import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_model.dart';
import '../models/sub_category_model.dart';
import '../models/cart_item_model.dart';
import '../models/banner_model.dart';
import 'package:http_parser/http_parser.dart'; // Mime type ke liye

class ApiService {
  static const String baseUrl = "https://www.vastrafix.shreejifintech.com/api/";
  //static const String baseUrl = "http://192.168.1.12:8000/api/";

  // ================= CUSTOMER LOGIN =================
  static Future<Map<String, dynamic>> login(String input, String password) async {
    try {
      final response = await http.post(
        Uri.parse("${baseUrl}accounts/login/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email_or_phone": input,
          "password": password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data.containsKey("access")) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", data["access"]);
        await prefs.setString("role", data["role"] ?? "");

        if (data.containsKey("username")) {
          await prefs.setString("user_name", data["username"]);
        }
      }
      return data;
    } catch (e) {
      return {"error": "Connection failed: $e"};
    }
  }

  // ApiService.dart ke andar ye add karein
  static Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("user_name", name); // Yahan key "user_name" honi chahiye
  }

  // google login

  static Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    try {

      final response = await http.post(
        Uri.parse('${baseUrl}accounts/google-login/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'idToken': idToken,
          'app_type': 'customer',
        }),
      );

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      return json.decode(response.body);
    } catch (e) {
      return {"error": "Backend connection failed: $e"};
    }
  }

  // ================= REGISTER =================
  static Future<Map<String, dynamic>> signup({
    required String username,
    required String email,
    required String phone,
    required String password,
    required String role,
    String? address,
    String? city,
    String? state,
    String? pincode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("${baseUrl}accounts/register/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "email": email,
          "phone": phone,
          "password": password,
          "role": role,
          "address": address ?? "",
          "city": city ?? "",
          "state": state ?? "",
          "pincode": pincode ?? "",
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {"error": "Connection failed: $e"};
    }
  }

  // ================= LOGOUT =================
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  //=======Save Token=====
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    bool success = await prefs.setString('auth_token', token);
    print("Token saved status: $success");// 👈 Ise print karke dekhein
    print("🔑 Fcm Token is :  $token");
  }

  // ================= TOKEN =================
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  // ================= CATEGORIES =================
  static Future<List<CategoryModel>> getAllCategories() async {
    try {
      final response = await http.get(
        Uri.parse("${baseUrl}services/category/"),
      );

      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((e) => CategoryModel.fromJson(e)).toList();
      } else {
        throw Exception("Failed to load categories");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  static Future<List<SubCategoryModel>> getItemsByService(String service) async {
    final uri = Uri.parse("${baseUrl}services/subcategories/")
        .replace(queryParameters: {"type": service});

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => SubCategoryModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load subcategories");
    }
  }

  // ================= ADDRESS =================
  static Future<Map<String, dynamic>?> getUserAddress() async {
    final String? token = await getToken();

    try {
      final response = await http.get(
        Uri.parse('${baseUrl}accounts/address/'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return data;// first element Map
        }
      }
      return null;
    } catch (e) {
      print("Error fetching address: $e");
      return null;
    }
  }

  // Create new address
  static Future<int?> createAddress(Map<String, dynamic> data) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse("${baseUrl}accounts/address/create/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(data),
    );

    print("LOG: Status Code = ${response.statusCode}");
    print("LOG: Response Body = ${response.body}");

    if (response.statusCode == 201) {
      final res = jsonDecode(response.body);
      return res["id"]; // 🔥 Ensure backend actually 'id' return kar raha hai
    }
    return null;
  }

  // GET ALL USER ADDRESSES  ✅
  static Future<List<dynamic>?> getUserAddresses() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse("${baseUrl}accounts/address/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        // 🔥 THE MASTER FIX: Dhoondo 12 addresses kahan hain!
        if (decoded is List) {
          return decoded;
        } else if (decoded is Map<String, dynamic>) {
          // Agar backend list ko 'results', 'data', ya 'addresses' ke andar bhej raha hai
          if (decoded.containsKey('results') && decoded['results'] is List) {
            return decoded['results'];
          } else if (decoded.containsKey('data') && decoded['data'] is List) {
            return decoded['data'];
          } else if (decoded.containsKey('addresses') && decoded['addresses'] is List) {
            return decoded['addresses'];
          }
          return [decoded]; // Backup ke liye
        }
      }
    } catch (e) {
      print("Error fetching addresses: $e");
    }
    return null;
  }

  // ================= ORDER =================
  static Future<Map<String, dynamic>?> placeOrder(
      List<CartItem> items,
      int addressId,
      String pickupDateTime,
      String? phone,
      String deliveryMode,   // 👈 Naya parameter add kiya hai
      double deliveryCharge, // 👈 Naya parameter add kiya hai
      String paymentMode,
      {String? paymentId}
      ) async {
    print("🔥 INSIDE placeOrder FUNCTION"); // 👈 NEW PRINT
    final token = await getToken();
    print("🔥 TOKEN: $token"); // 👈 NEW PRIN
    if (token == null){
      print("❌ TOKEN IS NULL! Yahi problem hai."); // 👈 NEW PRINT
      return null;}


    final body = {
      "address_id": addressId,
      "pickup_datetime": pickupDateTime,
      "phone": phone, // 👈 Serializer ab ise accept karega
      "delivery_mode": deliveryMode,      // 👈 Backend ko bhejne ke liye
      "delivery_charge": deliveryCharge,  // 👈 Backend ko bhejne ke liye
      "payment_mode": paymentMode,
      "paymentId": paymentId,
      "order_items": items
          .map((e) => {
        "item": e.id,
        "quantity": e.quantity,
      })
          .toList()
    };


    print("🔥 BODY TO SEND: $body"); // 👈 NEW PRINT

    try {
      final response = await http.post(
        Uri.parse("${baseUrl}orders/create/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      print("Status Code: ${response.statusCode}");
      print("Response: ${response.body}");

      print("--- PLACING ORDER ---");
      print("Payment ID being sent: $paymentId"); // 👈 Ye print check karo console mein

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      print("Error placing order: $e");
      return null;
    }
  }

  // ================= USER PROFILE =================
  static Future<Map<String, dynamic>?> getUserProfile() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse("${baseUrl}accounts/profile/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      if (response.statusCode == 401) {
        // token expired / invalid
        await logout();
        return null;
      }

      print("Profile API error: ${response.statusCode}");
    } catch (e) {
      print("Profile fetch error: $e");
    }
    return null;
  }

  // edit profile

  static Future<bool> updateProfile({
    required String username,
    required String email,
    required String phone,
    File? image,
  }) async {
    final token = await getToken();

    final request = http.MultipartRequest('PUT',
      Uri.parse("${baseUrl}accounts/profile/edit/"),
    );

    request.headers['Authorization'] = 'Bearer $token';

    // ApiService.dart mein updateProfile ke andar:
    if (username != null && username.isNotEmpty) request.fields['username'] = username;
    if (email != null && email.isNotEmpty) request.fields['email'] = email;
    if (phone != null && phone.isNotEmpty) request.fields['phone'] = phone;

    if (image != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_image',
          image.path,
        ),
      );
    }

    final response = await request.send();
    return response.statusCode == 200;
  }

  // Raise Of complain aur support

  static Future<bool> raiseComplaint(String issue) async {
    final token = await getToken();
    try {
      final response = await http.post(
        Uri.parse("${baseUrl}services/complaint/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "issue": "General Support", // Serializer ko 'issue' field chahiye
          "message": issue,           // 🔥 FIX: Jo user ne likha hai wo yahan jayega
          "order_id": null            // General support ke liye null
        }),
      ).timeout(const Duration(seconds: 5));

      print("Complaint Status: ${response.statusCode}");
      print("Complaint Body: ${response.body}");

      return response.statusCode == 201;
    } catch (e) {
      print("Complaint Error: $e");
      return false;
    }
  }

  // ================= ORDER HISTORY =================
  static Future<List<dynamic>> getOrderHistory() async {
    final token = await getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse("${baseUrl}orders/my-orders/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data;
      } else {
        print("Order History Error: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("VastraFix Connection Error: $e");
      return [];
    }
  }

  // Cancle Order

  static Future<bool> cancelOrder(int orderId) async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse("${baseUrl}orders/cancel/$orderId/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("Cancel Order Error: $e");
      return false;
    }
  }

  // banner Model

  static Future<List<BannerModel>> getBanners() async {
    final response = await http.get(
      Uri.parse("${baseUrl}services/banners/"),
    );

    print("STATUS CODE: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => BannerModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load banners");
    }
  }

  // Order Detail

  static Future<Map<String, dynamic>?> getOrderDetail(int orderId) async {
    final token = await getToken();

    // URL check karne ke liye

    final response = await http.get(
      Uri.parse('${baseUrl}orders/$orderId/'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    print("📡 Fetching Order ID: $orderId");
    print("📡 Status Code: ${response.statusCode}");
    print("📡 Response Body: ${response.body}"); // 🔥 Ye check karo debug console mein

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }

  // ================= DELIVERY CONFIGS (NEW) =================
  static Future<List<dynamic>?> getDeliveryConfigs() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse("${baseUrl}orders/delivery-configs/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Error fetching configs: $e");
    }
    return null;
  }

  // ================= UPDATE ORDER ADDRESS =================
  static Future<bool> updateOrderAddress(int orderId, int addressId) async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse("${baseUrl}orders/$orderId/update-address/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"address_id": addressId}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Update Address Error: $e");
      return false;
    }
  }

  // delete address

  static Future<bool> deleteAddress(int addressId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Try different common keys if 'auth_token' is null
    String? token = prefs.getString('auth_token') ??
        prefs.getString('token') ??
        prefs.getString('access');

    if (token == null) {
      print("❌ Error: Token abhi bhi null hai! Login function check karein.");
      return false;
    }

    final String url = "${baseUrl}accounts/addresses/$addressId/";

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ================= UPDATE ADDRESS (NEW) ✅ =================
  static Future<bool> updateAddress(dynamic addressId, Map<String, dynamic> data) async {
    final token = await getToken();
    if (token == null) return false;

    // 🔥 Note: Backend URL check kar lena (Django me trailing slash / zaruri hota hai)
    final String url = "${baseUrl}accounts/address/$addressId/update/";

    try {
      final response = await http.patch( // PATCH use kar rahe hain taaki partial update ho sake
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(data),
      );

      print("LOG Update: Status = ${response.statusCode}");

      // Django standard: 200 OK update ke liye
      return response.statusCode == 200;
    } catch (e) {
      print("Update Address Error: $e");
      return false;
    }
  }

  // ================= RAZORPAY PAYMENT (NEW) =================

  // 1. Order Create karne ke liye
  static Future<Map<String, dynamic>?> createRazorpayOrder(double amount) async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await http.post(
        Uri.parse("${baseUrl}orders/payment/create-order/"), // Django ka create url
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "amount": amount,
        }),
      );

      print("Create Razorpay Order Status: ${response.statusCode}");
      print("Create Razorpay Order Body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Ye hume 'order_id' dega
      }
      return null;
    } catch (e) {
      print("Razorpay Create Order Error: $e");
      return null;
    }
  }

  // 2. Payment Verify karne ke liye
  static Future<bool> verifyRazorpayPayment(
      String orderId, String paymentId, String signature, int amount) async {

    final token = await getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse("${baseUrl}orders/payment/verify/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "razorpay_order_id": orderId,
          "razorpay_payment_id": paymentId,
          "razorpay_signature": signature,
          "amount": amount.toString(),
        }),
      );

      print("Verify Payment Status: ${response.statusCode}");
      print("Verify Payment Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return data["verified"] == true || data["status"] == "success";
      }

      return false;

    } catch (e) {
      print("Razorpay Verify Error: $e");
      return false;
    }
  }

  //======NOTIFICATION========//

  static Future<List<dynamic>?> getNotifications() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      String? token = prefs.getString('token');
      print("My Token is: $token");

      final response = await http.get(
        Uri.parse("${baseUrl}notification/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("API Failed with Status Code: ${response.statusCode}");
        print("Error Detail: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Catch Error: $e");
      return null;
    }
  }

  // Notification count

  static Future<int> getNotificationCount() async {
    final token = await getToken(); // Aapka auth token
    final response = await http.get(
      Uri.parse("${baseUrl}notification/count/"),
      headers: {
        'Authorization': 'Bearer $token', // Agar JWT use kar rahe hain
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['unread_count']; // Backend se aaya hua key
    }
    return 0;
  }

  // 2. Count reset karne ke liye
  static Future<void> markNotificationsRead() async {
    // 1. Hamara common getToken function use karein (taki key mismatch na ho)
    final String? token = await getToken();

    if (token == null) {
      print("Error: Token null mila. User login nahi hai.");
      return;
    }

    print("Sending Token for Mark Read: $token");

    try {
      final response = await http.post(
        Uri.parse("${baseUrl}notification/read-all/"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("Mark Read Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        print("All notifications marked as read successfully");
      } else {
        print("Failed to mark read: ${response.body}");
      }
    } catch (e) {
      print("Catch Error in Mark Read: $e");
    }
  }

  // ================= FCM TOKEN AUTO-SAVE =================
    static Future<void> updateFCMToken(String fcmToken) async {
      final token = await getToken();
      print("🔥 Attempting to save token for user. Auth Token exists: ${token != null}");

      if (token == null) return; // User login nahi hai toh ruk jao

      try {
        final response = await http.post(
          Uri.parse("${baseUrl}accounts/update-fcm-token/"), // 👈 Check karein backend URL yahi hai na?
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          body: jsonEncode({"token": fcmToken}),
        );

        print("🔥 Token Update Status: ${response.statusCode}");
        print("🔥 Token Update Response: ${response.body}");
      } catch (e) {
        print("🔥 Token Update Error: $e");
      }
    }

  //== clear notification ==

  static Future<bool> clearAllNotifications() async {
    final token = await getToken();
    try {
      final response = await http.delete(
        Uri.parse("${baseUrl}notification/clear-all/"), // Check karein backend URL sahi hai
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  //==== Order Ki Complaint (Final Version) ====//
  static Future<bool> submitOrderComplaint({
    required int orderId,
    required String complaintText,
    required String nameOfUser,
    File? imageFile, // 🔥 Image file handle karne ke liye
  }) async {
    final token = await getToken();
    try {
      // 1. JSON ki jagah MultipartRequest banayein
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${baseUrl}services/complaint/"),
      );

      // 2. Headers add karein
      request.headers['Authorization'] = "Bearer $token";

      // 3. Text fields add karein (Dhyan rahe yahan sab String hona chahiye)
      request.fields['order'] = orderId.toString();
      request.fields['issue'] = "Order Service Issue";
      request.fields['message'] = complaintText;
      request.fields['user_name'] = nameOfUser;
      request.fields['subject'] = "Order Issue #$orderId";

      // 4. 🔥 Image file add karein (Agar user ne select ki hai)
      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image', // 👈 Ye wahi naam hona chahiye jo Django model mein hai
            imageFile.path,
            contentType: MediaType('image', 'jpeg'), // Ya 'image/png'
          ),
        );
      }

      // 5. Request send karein
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("LOG: Status ${response.statusCode}");
      print("LOG: Body ${response.body}");

      return response.statusCode == 201;
    } catch (e) {
      print("LOG: Error $e");
      return false;
    }
  }

  // services availablity

  static Future<Map<String, dynamic>> checkAreaAvailability(double lat, double lng) async {
    final token = await getToken();
    try {
      final response = await http.post(
        Uri.parse("${baseUrl}orders/check-area/"), // Aapke Django ka naya URL
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "latitude": lat,
          "longitude": lng,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"available": false, "message": "Service check failed."};
      }
    } catch (e) {
      return {"available": false, "message": "Connection error."};
    }
  }

  // ================= EMAIL OTP VERIFICATION (NEW) =================

  // 1. OTP Verify karne ke liye
  static Future<Map<String, dynamic>> verifyEmailOTP(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse("${baseUrl}accounts/verify-otp/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "otp": otp,
        }),
      );

      final data = jsonDecode(response.body);

      // ✅ FIX: 200 aur 201 dono ko success mano
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          "success": true,
          "message": data["message"] ?? "Success"
        };
      } else {
        // Agar status 400 ya kuch aur hai
        return {
          "success": false,
          "error": data["error"] ?? "Invalid OTP"
        };
      }
    } catch (e) {
      return {"success": false, "error": "Connection failed"};
    }
  }

// 2. OTP Resend karne ke liye (Optional: Agar aapne backend par resend view banaya hai)
  static Future<Map<String, dynamic>> resendOTP(String email) async {
    try {
      final response = await http.post(
        Uri.parse("${baseUrl}accounts/send-otp/"), // Jo humne views.py mein banaya tha
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      if (response.statusCode == 200) {
        return {"success": true};
      } else {
        return {"success": false, "error": "Failed to send OTP"};
      }
    } catch (e) {
      return {"success": false, "error": "Server error"};
    }
  }

}
