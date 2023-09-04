import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kmitl_telemedicine_staff/providers.dart';

class AccessDeniedPage extends ConsumerStatefulWidget {
  const AccessDeniedPage({super.key});

  static const String path = "/access-denied";

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AccessDeniedPageState();
}

class _AccessDeniedPageState extends ConsumerState<AccessDeniedPage> {
  bool signingOut = false;

  @override
  Widget build(BuildContext context) {
    final firebaseUser = ref.watch(firebaseAuthStateProvider).valueOrNull;
    final userSnapshot = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: AlertDialog(
          title: const Text("Access Denied"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text("UID: ${firebaseUser!.uid}"),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: firebaseUser.uid));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied!')),
                      );
                    },
                  ),
                ],
              ),
              if (userSnapshot != null && userSnapshot.exists)
                Text("Role: ${userSnapshot.data()?.role.name}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: signingOut
                  ? null
                  : () async {
                      setState(() => signingOut = true);
                      await FirebaseAuth.instance.signOut();
                    },
              child: const Text("Sign Out"),
            ),
          ],
        ),
      ),
    );
  }
}
