import 'package:flutter/material.dart';
import 'package:user_app/auth/login.dart';
import 'package:user_app/auth/register.dart';
import 'package:user_app/extensions/extensions_import.dart';
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
    bool isLargeScreen = context.isUltraWide;

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
                    Text(
                      context.l10n.build_user_experience,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      context.l10n.join_thousands,
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
                        showLogin
                            ? context.l10n.sign_in_to_dashboard
                            : context.l10n.create_your_account,
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
                            showLogin
                                ? context.l10n.new_to_the_platform
                                : context.l10n.already_have_an_account,
                            style: TextStyle(color: Colors.black),
                          ),
                          const SizedBox(width: 5),
                          TextButton(
                            onPressed: toggleView,
                            child: Text(
                              showLogin
                                  ? context.l10n.sign_up
                                  : context.l10n.log_in,
                              style: const TextStyle(
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      showLogin ? const LoginScreen() : const RegisterScreen(),
                      Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text(context.l10n.or,
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _SocialButton(
                          icon: Icons.g_mobiledata,
                          label:
                            "${showLogin ? context.l10n.sign_in : context.l10n.sign_up} ${context.l10n.with_google}"),
                      const SizedBox(height: 25),
                      Center(
                        child: Text(
                          context.l10n.terms_of_service,
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
      child: OutlinedButton(
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
            Text(label,
                style: const TextStyle(
                    color: Colors.black87, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
