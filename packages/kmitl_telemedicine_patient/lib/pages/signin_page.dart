import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kmitl_telemedicine_patient/pages/email_verification_page.dart';

class SigninPage extends StatelessWidget {
  const SigninPage({Key? key}) : super(key: key);

  static const String path = "/auth/signin";

  @override
  Widget build(BuildContext context) {
    return SignInScreen(
      actions: [
        AuthStateChangeAction((context, state) {
          final user = switch (state) {
            SignedIn(user: final user) => user,
            CredentialLinked(user: final user) => user,
            UserCreated(credential: final cred) => cred.user,
            _ => null,
          };

          switch (user) {
            case firebase.User(emailVerified: true):
              context.go("/");
              break;
            case firebase.User(emailVerified: false, email: final String _):
              context.push(EmailVerificationPage.path);
              break;
          }
        }),
      ],
    );
  }
}
