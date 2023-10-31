import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kmitl_telemedicine/kmitl_telemedicine.dart';
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
                  Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: kAppGradient,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: FilledButton(
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.transparent),
                      ),
                      onPressed: () => context.go(SigninPage.path),
                      child: const Text("Sign In"),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => context.go(SignupPage.path),
                      child: const Text("Create Account"),
                    ),
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
