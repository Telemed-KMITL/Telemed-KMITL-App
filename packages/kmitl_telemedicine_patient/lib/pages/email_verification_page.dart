import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kmitl_telemedicine_patient/pages/signin_page.dart';

class EmailVerificationPage extends StatelessWidget {
  const EmailVerificationPage({Key? key}) : super(key: key);

  static const String path = "/auth/verify-email";

  @override
  Widget build(BuildContext context) {
    return EmailVerificationScreen(
      actions: [
        EmailVerifiedAction(() {
          context.go("/");
        }),
        AuthCancelledAction((context) {
          FirebaseUIAuth.signOut(context: context);
          context.go(SigninPage.path);
        }),
      ],
    );
  }
}
