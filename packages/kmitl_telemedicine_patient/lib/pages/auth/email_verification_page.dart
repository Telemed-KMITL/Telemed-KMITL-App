import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmitl_telemedicine_patient/pages/auth/registration_page.dart';

class EmailVerificationPage extends ConsumerWidget {
  const EmailVerificationPage({
    super.key,
    this.hasPreviousPage = false,
  });

  final bool hasPreviousPage;

  static const String route = "verify-email";
  static const String path = "/auth/verify-email";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey.shade900,
        elevation: 0,
        leadingWidth: 120,
        leading: hasPreviousPage
            ? Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => context.go("/auth?signout=true"),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: "Sign out",
                ),
              )
            : TextButton.icon(
                onPressed: () => context.go("/auth?signout=true"),
                icon: const Icon(Icons.logout),
                label: const Text("Sign out"),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade900,
                ),
              ),
      ),
      body: EmailVerificationScreen(
        actions: [
          EmailVerifiedAction(() async {
            if (await RegistrationPage.needsToShow(ref)) {
              if (context.mounted) {
                context.go(RegistrationPage.path, extra: true);
              }
            } else {
              if (context.mounted) context.go("/");
            }
          }),
          AuthCancelledAction((context) => context.go("/auth?signout=true")),
        ],
      ),
    );
  }
}
