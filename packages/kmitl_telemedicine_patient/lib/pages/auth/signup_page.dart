import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmitl_telemedicine_patient/pages/auth/email_verification_page.dart';
import 'package:kmitl_telemedicine_patient/pages/auth/registration_page.dart';

class SignupPage extends ConsumerWidget {
  const SignupPage({super.key});

  static const String route = "signup";
  static const String path = "/auth/signup";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey.shade900,
        elevation: 0,
      ),
      body: RegisterScreen(
        showAuthActionSwitch: false,
        actions: [
          AuthStateChangeAction<UserCreated>((context, state) {
            switch (state.credential.user) {
              case firebase.User(emailVerified: false, email: String _):
                context.go(EmailVerificationPage.path, extra: true);
                break;
              case firebase.User():
                context.go(RegistrationPage.path, extra: true);
                break;
            }
          }),
        ],
      ),
    );
  }
}
