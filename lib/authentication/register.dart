import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:phone_form_field/phone_form_field.dart';

import 'package:user_app/global/global.dart';
import 'package:user_app/widgets/custom_text_field.dart';
import 'package:user_app/widgets/custom_phone_field.dart';
import 'package:user_app/widgets/custom_password_field.dart';
import 'package:user_app/widgets/error_dialog.dart';
import 'package:user_app/widgets/loading_dialog.dart';
import 'package:user_app/extensions/context_translate_ext.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _currentStep = 0;

  // Step 1 — Business
  final GlobalKey<FormState> _businessFormKey = GlobalKey<FormState>();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _nipController = TextEditingController();
  final TextEditingController _regonController = TextEditingController();
  late final PhoneController _businessMobileController;

  // Step 2 — Admin
  final GlobalKey<FormState> _adminFormKey = GlobalKey<FormState>();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  late final PhoneController _ownerPhoneController;

  @override
  void initState() {
    super.initState();
    _businessMobileController = PhoneController(
      initialValue: const PhoneNumber(isoCode: IsoCode.PL, nsn: ''),
    );
    _ownerPhoneController = PhoneController(
      initialValue: const PhoneNumber(isoCode: IsoCode.PL, nsn: ''),
    );
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _nipController.dispose();
    _regonController.dispose();
    _businessMobileController.dispose();
    _ownerNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ownerPhoneController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_businessFormKey.currentState!.validate()) {
      setState(() => _currentStep = 1);
    }
  }

  void _prevStep() {
    setState(() => _currentStep = 0);
  }

  Future<void> _submit() async {
    if (!_adminFormKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      showDialog(
        context: context,
        builder: (_) => ErrorDialog(message: context.t.errorNoMatchPasswords),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LoadingDialog(message: "Creating Partner Account..."),
    );

    try {
      final UserCredential auth = await firebaseAuth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final User? currentUser = auth.user;

      if (currentUser != null) {
        await _saveRestaurantToFirestore(currentUser);
        await _saveUserToFirestore(currentUser);
        await firebaseAuth.signOut();

        if (!mounted) return;
        Navigator.pop(context);
        context.go('/');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Your account is pending approval. Please sign in once verified."),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (_) => ErrorDialog(message: error.toString()),
      );
    }
  }

  Future<void> _saveRestaurantToFirestore(User currentUser) async {
    await FirebaseFirestore.instance.collection('restaurants').doc(currentUser.uid).set({
      "restaurantID": currentUser.uid,
      "name": _businessNameController.text.trim(),
      "nip": _nipController.text.trim(),
      "regon": _regonController.text.trim(),
      "businessMobile": _businessMobileController.value.international,
      "status": "Not Approved",
      "logoUrl": "",
      "bannerUrl": "",
      "createdAt": DateTime.now(),
    });
  }

  Future<void> _saveUserToFirestore(User currentUser) async {
    await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set({
      "userID": currentUser.uid,
      "name": _ownerNameController.text.trim(),
      "email": currentUser.email,
      "phone": _ownerPhoneController.value.international,
      "photoUrl": "",
      "createdAt": DateTime.now(),
      "role": "restaurant_admin",
      "status": "Not Approved",
    });
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
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isWeb ? 40 : 20, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStepIndicator(),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      final offset = _currentStep == 0
                          ? const Offset(-1, 0)
                          : const Offset(1, 0);
                      return SlideTransition(
                        position: Tween<Offset>(begin: offset, end: Offset.zero)
                            .animate(animation),
                        child: child,
                      );
                    },
                    child: _currentStep == 0
                        ? KeyedSubtree(key: const ValueKey(0), child: _buildBusinessStep())
                        : KeyedSubtree(key: const ValueKey(1), child: _buildAdminStep()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _StepDot(number: 1, label: 'Business', active: _currentStep == 0, done: _currentStep > 0),
        Expanded(child: Divider(color: _currentStep > 0 ? Colors.blueAccent : Colors.grey[300])),
        _StepDot(number: 2, label: 'Admin Profile', active: _currentStep == 1, done: false),
      ],
    );
  }

  Widget _buildBusinessStep() {
    return Form(
      key: _businessFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomTextField(
            data: Icons.business_rounded,
            controller: _businessNameController,
            hintText: 'Business Name',
          ),
          CustomTextField(
            data: Icons.numbers_rounded,
            controller: _nipController,
            hintText: 'NIP',
            validator: FieldValidator.nip,

          ),
          CustomTextField(
            data: Icons.tag_rounded,
            controller: _regonController,
            hintText: 'REGON',
            validator: FieldValidator.regon,
          ),
          CustomPhoneField(
            controller: _businessMobileController,
            label: 'Business Phone',
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminStep() {
    return Form(
      key: _adminFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomTextField(
            data: Icons.person_rounded,
            controller: _ownerNameController,
            hintText: "Owner's Full Name",
            isObsecure: false,
          ),
          CustomPhoneField(
            controller: _ownerPhoneController,
            label: "Owner's Phone",
          ),
          CustomTextField(
            data: Icons.email_rounded,
            controller: _emailController,
            hintText: context.t.hintEmail,
            isObsecure: false,
          ),
          CustomPasswordField(
            controller: _passwordController,
            label: context.t.hintPassword,
            isRequired: true,
            isConfirmation: false,
          ),
          CustomPasswordField(
            controller: _confirmPasswordController,
            label: context.t.hintConfPassword,
            isRequired: true,
            isConfirmation: true,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _prevStep,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_back_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Back', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Sign Up', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int number;
  final String label;
  final bool active;
  final bool done;
  const _StepDot({required this.number, required this.label, required this.active, required this.done});

  @override
  Widget build(BuildContext context) {
    final Color color = active || done ? Colors.blueAccent : Colors.grey[400]!;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: active || done ? Colors.blueAccent : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : Text(
                    '$number',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : color,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}