import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_validator/form_validator.dart';
import 'package:kmitl_telemedicine/kmitl_telemedicine.dart';
import 'package:kmitl_telemedicine_staff/views/form_dialog.dart';

class CreateWaitingRoomDialog extends ConsumerStatefulWidget {
  const CreateWaitingRoomDialog({this.existingRoom, super.key});

  final DocumentSnapshot<WaitingRoom>? existingRoom;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CreateWaitingRoomDialogState();
}

class _CreateWaitingRoomDialogState
    extends ConsumerState<CreateWaitingRoomDialog> {
  bool get isEditing => widget.existingRoom != null;
  WaitingRoom? get existingRoom => widget.existingRoom?.data();
  DocumentReference<WaitingRoom>? get existingRoomRef =>
      widget.existingRoom?.reference;

  String _roomName = "";
  String _roomDescription = "";

  @override
  void initState() {
    _roomName = existingRoom?.name ?? "";
    _roomDescription = existingRoom?.description ?? "";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: isEditing
          ? const Text("Edit Waiting Room")
          : const Text("Create Waiting Room"),
      content: _buildContent(),
      onSubmit: _submit,
      submitButtonText: isEditing ? "Update" : "Create",
    );
  }

  Widget _buildContent() {
    return SizedBox(
      width: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isEditing)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                "Room ID: ${existingRoomRef?.id}",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          TextFormField(
            initialValue: _roomName,
            decoration: const InputDecoration(
              labelText: "Room Name",
            ),
            validator: ValidationBuilder().required().build(),
            onSaved: (value) => _roomName = value!,
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _roomDescription,
            decoration: const InputDecoration(
              labelText: "Room Description (Optional)",
            ),
            maxLines: 3,
            onSaved: (value) => _roomDescription = value ?? "",
          ),
        ],
      ),
    );
  }

  Future<String?> _submit() async {
    final room = WaitingRoom(
      name: _roomName,
      description: _roomDescription,
      updatedAt: DateTime.now(),
    );
    if (isEditing) {
      await KmitlTelemedicineDb.updateWaitingRoom(existingRoomRef!, room);
    } else {
      await KmitlTelemedicineDb.createWaitingRoom(room);
    }
    return null;
  }
}
