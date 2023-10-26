import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kmitl_telemedicine_staff/pages/room_list_page.dart';
import 'package:kmitl_telemedicine_staff/pages/user_management_page.dart';

class PageDrawer extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromARGB(255, 218, 78, 55),
                  Color.fromARGB(255, 244, 129, 54),
                ],
              ),
            ),
            child: SizedBox(
              width: double.infinity,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Sign Out"),
            onTap: () {
              FirebaseAuth.instance.signOut();
            },
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
