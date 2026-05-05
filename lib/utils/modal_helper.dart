import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';

class ModalHelper {
  ModalHelper._();

  static void openLogin(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(24),
        child: LoginScreen(),
      ),
    );
  }

  static void openSignup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(24),
        child: SignUpScreen(),
      ),
    );
  }
}