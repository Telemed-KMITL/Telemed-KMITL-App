import "dart:async";

import "package:firebase_ui_auth/firebase_ui_auth.dart";
import "package:flutter/material.dart";
import "package:firebase_core/firebase_core.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:kmitl_telemedicine_patient/router.dart";
import "firebase_options.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseUIAuth.configureProviders([
    EmailAuthProvider(),
  ]);
  runApp(const ProviderScope(
    child: MainApp(),
  ));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xfff0542c),
          primary: const Color(0xfff0542c),
        ),
      ),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
