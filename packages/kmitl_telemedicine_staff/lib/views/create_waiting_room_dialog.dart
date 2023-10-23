import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_validator/form_validator.dart';
import 'package:kmitl_telemedicine/kmitl_telemedicine.dart';
import 'package:kmitl_telemedicine_staff/views/form_dialog.dart';

class CreateWaitingRoomDialog extends ConsumerStatefulWidget {
  const CreateWaitingRoomDialog({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CreateWaitingRoomDialogState();
}

class _CreateWaitingRoomDialogState
    extends ConsumerState<CreateWaitingRoomDialog> {
  String _roomName = "";
  String _roomDescription = "";

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: const Text("Create Waiting Room"),
      content: _buildContent(),
      onSubmit: _submit,
      submitButtonText: "Create",
    );
  }

  Widget _buildContent() {
    return SizedBox(
      width: 400,
      child: Column(
        children: [
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
            onSaved: (value) => _roomDescription = value ?? "",
          ),
        ],
      ),
    );
  }

  Future<String?> _submit() async {
    await KmitlTelemedicineDb.createWaitingRoom(WaitingRoom(
      name: _roomName,
      description: _roomDescription,
      updatedAt: DateTime.now(),
    ));
    return null;
  }
}
