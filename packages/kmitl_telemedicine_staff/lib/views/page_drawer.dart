import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmitl_telemedicine/kmitl_telemedicine.dart';
import 'package:kmitl_telemedicine_staff/pages/room_list_page.dart';
import 'package:kmitl_telemedicine_staff/pages/user_management_page.dart';
import 'package:kmitl_telemedicine_staff/providers.dart';

class PageDrawer extends ConsumerWidget {
  final Map<String, String> pages = {
    "Waiting Rooms": RoomListPage.path,
    "Users": UserManagementPage.path,
  };
  final ValueChanged<String>? onPageChanged;

  PageDrawer({
    super.key,
    this.onPageChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseUser = ref.watch(firebaseUserProvider).valueOrNull;
    final user = ref.watch(currentUserProvider).valueOrNull?.data();

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(gradient: kAppGradient),
            accountName: Text(user == null
                ? ""
                : "${user.getDisplayName()} (${user.role.name})"),
            accountEmail: Text(firebaseUser?.email ?? ""),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Sign Out"),
            onTap: () => FirebaseAuth.instance.signOut(),
          ),
          const Divider(),
          ...pages.entries.map(
            (e) => ListTile(
              title: Text(e.key),
              onTap: () {
                onPageChanged?.call(e.value);
                context.go(e.value);
              },
            ),
          ),
        ],
      ),
    );
  }
}
