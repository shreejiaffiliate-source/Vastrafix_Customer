import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/api_services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Local storage ke liye

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '601085863126-vd5n9r4147620li5fk8p0e3vnho2qvm6.apps.googleusercontent.com',
  );

  Future<User?> signInWithGoogle() async {
    try {
      await _auth.signOut();

      // 🔥 FIX 2: Google Sign In ka session puri tarah kill karo
      try {
        if (await _googleSignIn.isSignedIn()) {
          await _googleSignIn.disconnect();
        }
      } catch (e) {
        print("Disconnecting old session... $e");
      }
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("User ne login cancel kar diya.");
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        String? idToken = googleAuth.idToken;

        if (idToken != null) {
          print("✅ Google ID Token mil gaya! Backend ko bhej rahe hain...");
          final response = await ApiService.loginWithGoogle(idToken);

          // AuthService.dart ke andar
          if (response.containsKey('access')) {
            // 1. Token save hone ka wait karein
            await ApiService.saveToken(response['access']);

            // 2. Naam save hone ka wait karein
            final prefs = await SharedPreferences.getInstance();
            bool saved = await prefs.setString('user_name', user.displayName ?? "Customer");

            print("Name saved status: $saved"); // Agar ye true hai, matlab save ho gaya

            // 3. FCM update
            try {
              String? fcmToken = await FirebaseMessaging.instance.getToken();
              if (fcmToken != null) await ApiService.updateFCMToken(fcmToken);
            } catch (e) { print("FCM Error: $e"); }

            // 🔥 Sabse Zaruri: Navigation se pehle 200ms ka gap dein
            // Taaki storage puri tarah ready ho jaye
            await Future.delayed(const Duration(milliseconds: 200));
            print("✅ Sab kuch save ho gaya: ${user.displayName}");
          } else {
            print("🚨 Backend verification failed ya access token nahi mila.");
          }
        }
      }
      return user;
    } catch (e) {
      print("🚨 Error: $e");
      return null;
    }
  }
}