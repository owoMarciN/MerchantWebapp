import 'dart:async';
import 'package:flutter/material.dart';
import 'package:user_app/global/global.dart';
import 'package:go_router/go_router.dart';

class MySplashScreen extends StatefulWidget {
  const MySplashScreen({super.key});

  @override
  State<MySplashScreen> createState() => _MySplashScreenState();
}

class _MySplashScreenState extends State<MySplashScreen> {
  
  void startTimer() {
    Timer(const Duration(seconds: 2), () async {
      if (firebaseAuth.currentUser != null && currentUid != null) {
        // Safe to go to Dashboard
        Router.neglect(context, () => context.go('/dashboard'));
      } else {
        if (firebaseAuth.currentUser != null && currentUid == null) {
          await firebaseAuth.signOut();
        }

        if (!mounted) return;
        Router.neglect(context, () => context.go('/auth/login'));
      }
    });
  }

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                'assets/images/1000021479.jpg', 
                width: 300, 
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Daol pocha',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontFamily: "Train",
                letterSpacing: 3,
              ),
            ),
            const Text(
              "Wroclaw Number #1 Delivery App",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontFamily: "Signatra",
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              color: Colors.blueAccent, 
            ),
          ],
        ),
      ),
    );
  }
}