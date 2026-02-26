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
      await loginNow();
    } else {
      showDialog(
        context: context,
        builder: (_) => ErrorDialog(message: context.t.errorEnterEmailOrPassword),
      );
    }
  }

  Future<void> loginNow() async {
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
      
      User? currentUser = authResult.user;

      if (currentUser != null) {
        await readUserAndRestaurantData(currentUser);
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (_) => ErrorDialog(message: error.message ?? context.t.errorLoginFailed),
      );
    }
  }

  Future<void> readUserAndRestaurantData(User currentUser) async {
    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser.uid)
          .get();

      if (!userSnapshot.exists) {
        await firebaseAuth.signOut();
        if (!mounted) return;
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (_) => const ErrorDialog(message: "No user record found."),
        );
        return;
      }

      final userData = userSnapshot.data()!;
      if (userData["role"] != "restaurant_admin") {
        await firebaseAuth.signOut();
        if (!mounted) return;
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (_) => const ErrorDialog(message: "This account is not a restaurant."),
        );
        return;
      }

      // Check if restaurant document exists
      final restaurantSnapshot = await FirebaseFirestore.instance
          .collection("restaurants")
          .doc(currentUser.uid)
          .get();

      if (!restaurantSnapshot.exists) {
        await firebaseAuth.signOut();
        if (!mounted) return;
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (_) => const ErrorDialog(message: "No restaurant record found."),
        );
        return;
      }

      final restaurantData = restaurantSnapshot.data()!;
      if (restaurantData["status"] != "Approved" && restaurantData["status"] != "Active") {
        await firebaseAuth.signOut();
        if (!mounted) return;
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (_) => const ErrorDialog(
            message: "Your restaurant account is pending approval. You will be able to login once verified.",
          ),
        );
        return;
      }

      // Save info locally
      await sharedPreferences!.setString("uid", currentUser.uid);
      await saveUserPref<String>("accountName", userData["name"] ?? "");
      await saveUserPref<String>("phone", userData["phone"] ?? "");
      await saveUserPref<String>("photoUrl", userData["photoUrl"] ?? "");

      print('Account Name: ${userData["name"]}');
      print('Phone: ${userData["phone"]}');
      print('Photo URL: ${userData["photoUrl"]}');

      await saveUserPref<String>("businessName", restaurantData["name"] ?? "");
      await saveUserPref<String>("businessMobile", restaurantData["businessMobile"] ?? "");
      await saveUserPref<String>("logoUrl", restaurantData["logoUrl"] ?? "");
      await saveUserPref<String>("bannerUrl", restaurantData["bannerUrl"] ?? "");

      print('--- Business Data Saved ---');
      print('Business Name: ${restaurantData["name"]}');
      print('Business Mobile: ${restaurantData["businessMobile"]}');
      print('Logo URL: ${restaurantData["logoUrl"]}');
      print('Banner URL: ${restaurantData["bannerUrl"]}');
      print('---------------------------');

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
                            borderRadius: BorderRadius.circular(8)
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