import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kmitl_telemedicine_staff/views/page_drawer.dart';
import 'package:kmitl_telemedicine_staff/views/user_list_view.dart';

class UserManagementPage extends ConsumerStatefulWidget {
  const UserManagementPage({super.key});

  static const String path = "/users";

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _UserManagementPageState();
}

class _UserManagementPageState extends ConsumerState<UserManagementPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: PageDrawer(),
      appBar: AppBar(
        title: const Text("Users"),
        centerTitle: true,
      ),
      body: const SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: EdgeInsets.all(10.0),
          child: Column(
            children: [
              UserListView(),
            ],
          ),
        ),
      ),
    );
  }
}
