import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:user_app/global/global.dart';
import 'package:user_app/widgets/error_dialog.dart';
import 'package:user_app/widgets/loading_dialog.dart';
import 'package:user_app/widgets/custom_text_field.dart';
import 'package:user_app/extensions/context_translate_ext.dart';
import 'package:user_app/widgets/custom_password_field.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> formValidation() async {
    if (_formKey.currentState!.validate()) {
      await _loginNow();
    } else {
      showDialog(
        context: context,
        builder: (_) =>
            ErrorDialog(message: context.t.errorEnterEmailOrPassword),
      );
    }
  }

  Future<void> _loginNow() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => LoadingDialog(message: context.t.checkingCredentials),
    );

    try {
      final authResult = await firebaseAuth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final User? currentUser = authResult.user;
      if (currentUser != null) {
        await _loadAndSaveUserData(currentUser);
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (_) =>
            ErrorDialog(message: error.message ?? context.t.errorLoginFailed),
      );
    }
  }

  Future<void> _loadAndSaveUserData(User currentUser) async {
    try {
      // -- 1. Check user record exists and has restaurant role ---------------
      final userSnap = await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser.uid)
          .get();

      if (!userSnap.exists) {
        return _failWith("No user record found.");
      }

      final userData = userSnap.data()!;
      final String role = userData["role"]?.toString() ?? "";

      if (role == "admin") {
        // Admin goes straight to admin panel — no restaurant doc needed
        await sharedPreferences!.setString("uid", currentUser.uid);
        await saveUserPref<String>("accountName", userData["name"] ?? "");
        await saveUserPref<String>("accountEmail", userData["email"] ?? "");
        if (!mounted) return;
        Navigator.pop(context);
        context.go('/admin/overview');
        return;
      }

      if (role != "restaurant") {
        return _failWith("This app is for restaurant accounts only.");
      }

      // -- 2. Check restaurant record exists ---------------------------------
      final restaurantSnap = await FirebaseFirestore.instance
          .collection("restaurants")
          .doc(currentUser.uid)
          .get();

      if (!restaurantSnap.exists) {
        return _failWith("No restaurant record found. Please contact support.");
      }

      final restaurantData = restaurantSnap.data()!;

      // -- 3. Save prefs ------------------------------------------------------
      // Status is intentionally NOT checked here.
      // DashboardShell reads status from Firestore in real-time and shows
      // the appropriate gate screen (pending / rejected / suspended).
      // This way the user stays signed in and sees a proper explanation
      // instead of a generic error dialog.
      await sharedPreferences!.setString("uid", currentUser.uid);
      await saveUserPref<String>("accountName", userData["name"] ?? "");
      await saveUserPref<String>("accountEmail", userData["email"] ?? "");
      await saveUserPref<String>("phone", userData["phone"] ?? "");
      await saveUserPref<String>("photoUrl", userData["photoUrl"] ?? "");
      await saveUserPref<String>("businessName", restaurantData["name"] ?? "");
      await saveUserPref<String>(
          "businessMobile", restaurantData["businessMobile"] ?? "");
      await saveUserPref<String>("logoUrl", restaurantData["logoUrl"] ?? "");
      await saveUserPref<String>(
          "bannerUrl", restaurantData["bannerUrl"] ?? "");

      if (!mounted) return;
      Navigator.pop(context);
      context.go('/splash');
    } catch (e) {
      if (firebaseAuth.currentUser != null) await firebaseAuth.signOut();
      if (!mounted) return;
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (_) => ErrorDialog(message: e.toString()),
      );
    }
  }

  // Signs out and shows an error dialog.
  // Only used for hard failures: wrong role, missing records.
  // Status blocks (pending/rejected/suspended) are NOT handled here.
  Future<void> _failWith(String message) async {
    await firebaseAuth.signOut();
    if (!mounted) return;
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (_) => ErrorDialog(message: message),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isWeb = MediaQuery.of(context).size.width > 800;

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isWeb ? 40 : 20,
                vertical: 20,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomTextField(
                      data: Icons.email,
                      controller: _emailController,
                      hintText: context.t.hintEmail,
                      isObsecure: false,
                    ),
                    CustomPasswordField(
                      controller: _passwordController,
                      label: context.t.hintPassword,
                      isRequired: true,
                      isConfirmation: true,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 160,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: formValidation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Login",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
