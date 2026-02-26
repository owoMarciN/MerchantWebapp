import 'package:flutter/material.dart';
import 'package:user_app/authentication/login.dart';
import 'package:user_app/authentication/register.dart';
import 'package:user_app/extensions/brand_color_ext.dart';
import 'package:go_router/go_router.dart';

class AuthScreen extends StatefulWidget {
  final bool initialShowLogin;
  const AuthScreen({super.key, this.initialShowLogin = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool get showLogin => widget.initialShowLogin;
  
  void toggleView() {
    final newPath = showLogin ? '/auth/register' : '/auth/login';
    Router.neglect(context, () => context.go(newPath));
  }

  @override
  Widget build(BuildContext context) {
    bool isLargeScreen = MediaQuery.of(context).size.width > 900;

    final brandColors = Theme.of(context).extension<BrandColors>()!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          if (isLargeScreen)
            Expanded(
              flex: 1,
              child: Container(
                color: brandColors.navyDark,
                padding: const EdgeInsets.all(60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const FlutterLogo(size: 40),
                    const SizedBox(height: 40),
                    const Text(
                      "Build the best search\nexperience for your users.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Join thousands of teams scaling their applications with our dashboard.",
                      style: TextStyle(color: Colors.blue[100], fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),

          Expanded(
            flex: 1,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        showLogin ? "Sign in to Dashboard" : "Create your account",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF21243D),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            showLogin ? "New to the platform?" : "Already have an account?",
                            style: TextStyle(color: Colors.black),
                          ),
                          const SizedBox(width: 5),
                          TextButton(
                            onPressed: toggleView,
                            child: Text(
                              showLogin ? "Sign up" : "Log in",
                              style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
    
                      showLogin ? const LoginScreen() : const RegisterScreen(),
                    
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text("OR", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: 10),

                      _SocialButton(
                        icon: Icons.g_mobiledata, 
                        label: "${showLogin ? 'Sign in' : 'Sign up'} with Google"
                      ),

                      const SizedBox(height: 25),

                      const Center(
                        child: Text(
                          "By continuing, you agree to the Terms of Service.",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SocialButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child:
      OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(240, 50),
          maximumSize: const Size(350, 50),
          side: const BorderSide(color: Colors.grey),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {},
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}