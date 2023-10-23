import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmitl_telemedicine/kmitl_telemedicine.dart';
import 'package:kmitl_telemedicine_staff/providers.dart';
import 'package:kmitl_telemedicine_staff/views/create_waiting_room_dialog.dart';

class RoomListPage extends ConsumerWidget {
  const RoomListPage({super.key});

  static const String path = "/waitingRooms";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waitingRoomList = ref.watch(waitingRoomListProvider);
    final firebaseToken = ref.watch(firebaseTokenProvider(false)).valueOrNull;
    final isAdmin = firebaseToken?.claims?["role"] == "admin";

    return Scaffold(
      appBar: AppBar(
        title: const Text("TeleMed"),
        centerTitle: true,
      ),
      body: waitingRoomList.when(
        data: (data) => _buildList(context, data, isAdmin),
        error: (error, stackTrace) => Center(
          child: Text(error.toString()),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      floatingActionButton: isAdmin && waitingRoomList.hasValue
          ? FloatingActionButton(
              onPressed: () => showDialog(
                context: context,
                builder: (context) => const CreateWaitingRoomDialog(),
              ),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildList(
      BuildContext context, QuerySnapshot<WaitingRoom> snapshot, bool isAdmin) {
    final docs = snapshot.docs;
    return ListView(
      children: docs.map((e) {
        return _buildRoomTile(context, e, isAdmin);
      }).toList(),
    );
  }

  Widget _buildRoomTile(BuildContext context,
      QueryDocumentSnapshot<WaitingRoom> snapshot, bool isAdmin) {
    final room = snapshot.data();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(RoomListPage.path, extra: snapshot.reference),
        child: ListTile(
          title: Text(room.name),
          subtitle: room.description.isNotEmpty ? Text(room.description) : null,
          trailing: isAdmin
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _editRoom(context, snapshot),
                      icon: const Icon(Icons.edit),
                    ),
                    IconButton(
                      onPressed: () => _deleteRoom(context, snapshot),
                      icon: const Icon(Icons.delete),
                    ),
                    const VerticalDivider(
                      width: 20,
                      thickness: 1,
                    ),
                    const Icon(Icons.arrow_forward_ios),
                  ],
                )
              : const Icon(Icons.arrow_forward_ios),
        ),
      ),
    );
  }

  Widget _buildRoomDeleteDialog(BuildContext context, WaitingRoom room) {
    return AlertDialog(
      title: const Text("Delete this room?"),
      content: ListTile(
        title: Text(room.name),
        subtitle: room.description.isNotEmpty ? Text(room.description) : null,
      ),
      actions: [
        TextButton(
          child: const Text("Cancel"),
          onPressed: () => context.pop(false),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.delete),
          label: const Text("Delete"),
          onPressed: () => context.pop(true),
        ),
      ],
    );
  }

  Future<void> _editRoom(
      BuildContext context, QueryDocumentSnapshot<WaitingRoom> snapshot) async {
    await showDialog(
      context: context,
      builder: (context) => CreateWaitingRoomDialog(
        existingRoom: snapshot,
      ),
    );
  }

  Future<void> _deleteRoom(
      BuildContext context, QueryDocumentSnapshot<WaitingRoom> snapshot) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _buildRoomDeleteDialog(context, snapshot.data()),
    );
    if (result == true) {
      await snapshot.reference.delete();
    }
  }
}
