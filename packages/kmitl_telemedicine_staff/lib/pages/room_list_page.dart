import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmitl_telemedicine/kmitl_telemedicine.dart';
import 'package:kmitl_telemedicine_staff/providers.dart';

class RoomListPage extends ConsumerWidget {
  const RoomListPage({super.key});

  static const String path = "/waitingRooms";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waitingRoomList = ref.watch(waitingRoomListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text("TeleMed"),
        centerTitle: true,
      ),
      body: waitingRoomList.when(
        data: (data) => _buildList(context, data),
        error: (error, stackTrace) => Center(
          child: Text(error.toString()),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, QuerySnapshot<WaitingRoom> snapshot) {
    final docs = snapshot.docs;
    return ListView(
      children: docs.map((e) {
        final data = e.data();
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.go(RoomListPage.path, extra: e.reference),
            child: ListTile(
              title: Text(data.name),
              subtitle: Text("ID: ${e.id}"),
              trailing: const Icon(Icons.arrow_forward_ios),
            ),
          ),
        );
      }).toList(),
    );
  }
}
