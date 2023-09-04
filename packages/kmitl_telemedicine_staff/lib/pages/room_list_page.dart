import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kmitl_telemedicine/kmitl_telemedicine.dart';
import 'package:kmitl_telemedicine_staff/waiting_room_page.dart';

class RoomListPage extends StatefulWidget {
  const RoomListPage({Key? key}) : super(key: key);

  @override
  State<RoomListPage> createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("TeleMed"),
        centerTitle: true,
      ),
      body: StreamBuilder(
          stream: KmitlTelemedicineDb.waitingRooms.snapshots(),
          builder: _buildList),
    );
  }

  Widget _buildList(_, AsyncSnapshot<QuerySnapshot<WaitingRoom>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    }

    final docs = snapshot.data!.docs;
    return ListView(
      children: docs.map((e) {
        final data = e.data();
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _roomSelected(e.reference),
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

  void _roomSelected(DocumentReference<WaitingRoom> roomRef) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (c) => WaitingRoomPage(roomRef: roomRef),
      ),
    );
  }
}
