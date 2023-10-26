import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kmitl_telemedicine_patient/pages/auth/signin_page.dart';
import 'package:kmitl_telemedicine_patient/pages/auth/signup_page.dart';

class WelcomePage extends StatelessWidget {
  WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Image.asset("assets/KMCH-768x481.webp"),
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              width: 300,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () => context.go(SigninPage.path),
                    child: const Text("Sign in"),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => context.go(SignupPage.path),
                    child: const Text("Sign up"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
