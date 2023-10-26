import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmitl_telemedicine_patient/pages/auth/email_verification_page.dart';
import 'package:kmitl_telemedicine_patient/pages/auth/registration_page.dart';

class SigninPage extends ConsumerWidget {
  const SigninPage({super.key});

  static const String route = "signin";
  static const String path = "/auth/signin";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey.shade900,
        elevation: 0,
      ),
      body: SignInScreen(
        showAuthActionSwitch: false,
        actions: [
          AuthStateChangeAction<SignedIn>((context, state) async {
            switch (state.user) {
              case firebase.User(emailVerified: false, email: String _):
                context.go(EmailVerificationPage.path, extra: true);
                break;
              case firebase.User():
                if (await RegistrationPage.needsToShow(ref)) {
                  if (context.mounted) {
                    context.go(RegistrationPage.path, extra: true);
                  }
                } else {
                  if (context.mounted) context.go("/");
                }
                break;
            }
          }),
        ],
      ),
    );
  }
}
