import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmitl_telemedicine/kmitl_telemedicine.dart';
import 'package:kmitl_telemedicine_staff/providers.dart';

class TransferWaitingUserDialog extends ConsumerWidget {
  TransferWaitingUserDialog({
    super.key,
    this.waitingUser,
    this.currentRoom,
    this.onSelected,
  }) {
    assert(waitingUser == null || currentRoom == null);
    _currentRoomRef = waitingUser == null
        ? currentRoom
        : KmitlTelemedicineDb.getWaitingRoomRefFromWaitingUser(waitingUser!);
  }

  final DocumentReference<WaitingUser>? waitingUser;
  final DocumentReference<WaitingRoom>? currentRoom;
  final void Function(DocumentReference<WaitingRoom>)? onSelected;

  late final DocumentReference<WaitingRoom>? _currentRoomRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SimpleDialog(
      title: const Text("Transfer"),
      children: [
        if (_currentRoomRef != null)
          FutureBuilder(
            future: _currentRoomRef!.get(),
            builder: (_, snapshot) => Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.meeting_room),
                  Text(snapshot.hasData
                      ? snapshot.requireData.data()!.name
                      : _currentRoomRef!.id),
                  const Icon(Icons.keyboard_double_arrow_right),
                ],
              ),
            ),
          ),
        ..._buildChoices(context, ref),
      ].toList(),
    );
  }

  Iterable<Widget> _buildChoices(BuildContext context, WidgetRef ref) sync* {
    final roomList = ref.watch(waitingRoomListProvider);

    if (!roomList.hasValue) {
      yield const Center(child: CircularProgressIndicator());
    }

    for (var snapshot in roomList.requireValue.docs) {
      if (snapshot.reference.path == _currentRoomRef?.path) {
        continue;
      }

      final room = snapshot.data();
      yield SimpleDialogOption(
        onPressed: () => _onPressed(context, snapshot.reference),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        child: ListTile(
          title: Text(room.name),
          subtitle: room.description.isEmpty ? null : Text(room.description),
        ),
      );
    }
  }

  void _onPressed(BuildContext context, DocumentReference<WaitingRoom> room) {
    onSelected?.call(room);
    context.pop(room);
  }
}
