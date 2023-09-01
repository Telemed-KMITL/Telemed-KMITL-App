import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kmitl_telemedicine/kmitl_telemedicine.dart';
import 'package:kmitl_telemedicine/waiting_room.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:kmitl_telemedicine_staff/video_call_page.dart';

class WaitingRoomPage extends StatefulWidget {
  const WaitingRoomPage({
    Key? key,
    required this.roomRef,
  }) : super(key: key);

  final DocumentReference<WaitingRoom> roomRef;

  @override
  State<WaitingRoomPage> createState() => _WaitingRoomPageState();
}

class _WaitingRoomPageState extends State<WaitingRoomPage> {
  QuerySnapshot<WaitingRoom>? _waitingRoomList;

  @override
  void initState() {
    super.initState();

    KmitlTelemedicineDb.waitingRooms
        .get()
        .then((value) => setState(() => _waitingRoomList = value));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomRef.id),
      ),
      body: StreamBuilder(
        stream: KmitlTelemedicineDb.getWaitingUsers(widget.roomRef).snapshots(),
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!.docs;
          final headerStyle = Theme.of(context).textTheme.titleLarge;
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Table(
                  children: [
                    TableRow(
                      children: [
                        const TableCell(child: Icon(Icons.numbers)),
                        TableCell(child: Text("Name", style: headerStyle)),
                        TableCell(child: Text("Status", style: headerStyle)),
                        TableCell(child: Text("Action", style: headerStyle)),
                      ]
                          .map((w) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: w))
                          .toList(),
                    ),
                    ..._buildDataRows(data),
                  ],
                  columnWidths: const {
                    0: FixedColumnWidth(40),
                    1: FlexColumnWidth(),
                    2: FixedColumnWidth(120),
                    3: MaxColumnWidth(
                      IntrinsicColumnWidth(),
                      FixedColumnWidth(100),
                    ),
                  },
                  border: const TableBorder(horizontalInside: BorderSide()),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  textBaseline: TextBaseline.ideographic,
                ),
                if (data.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text("Waiting Room is empty"),
                    ),
                  )
              ],
            ),
          );
        },
      ),
    );
  }

  Iterable<TableRow> _buildDataRows(
    List<QueryDocumentSnapshot<WaitingUser>> source,
  ) {
    int i = 0;
    final textStyle = Theme.of(context).textTheme.labelLarge;
    final usernameStyle = Theme.of(context).textTheme.titleMedium;
    return source.map((document) {
      i++;

      final waitingUser = document.data();
      return TableRow(children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.baseline,
          child: Text(
            i.toString(),
            textAlign: TextAlign.center,
            style: textStyle,
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.baseline,
          child: Text(
            waitingUser.userName,
            style: usernameStyle,
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.baseline,
          child: Text(
            waitingUser.status.name,
            style: textStyle,
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.baseline,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(children: [
              _buildCallButton(
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (c) => VideoCallPage(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
              _buildTransferButton(
                (room) {},
              ),
            ]),
          ),
        ),
      ]);
    });
  }

  static Widget _buildCallButton(void Function()? onPressed) => ElevatedButton(
        onPressed: onPressed,
        child: const Row(children: [
          Text("Call"),
          SizedBox(width: 4),
          Icon(Icons.call),
        ]),
      );

  Widget _buildTransferButton(
      void Function(DocumentReference<WaitingRoom>)? onSelected) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<DocumentReference<WaitingRoom>>(
        customButton: const Padding(
          padding: EdgeInsets.symmetric(
            vertical: 2,
            horizontal: 10,
          ),
          child: Row(children: [
            Text("Transfer"),
            SizedBox(width: 4),
            Icon(Icons.logout),
          ]),
        ),
        items: _waitingRoomList?.docs.map(
          (r) {
            bool isCurrentRoom = widget.roomRef.path == r.reference.path;
            return DropdownMenuItem(
              value: r.reference,
              enabled: !isCurrentRoom,
              child: isCurrentRoom
                  ? Text(
                      "${r.data().name} (Current)",
                      style: const TextStyle(color: Colors.grey),
                    )
                  : Text(r.data().name),
            );
          },
        ).toList(),
        onChanged: onSelected == null
            ? null
            : (value) {
                if (value != null) {
                  onSelected(value);
                }
              },
        dropdownStyleData: const DropdownStyleData(
          width: 400,
        ),
      ),
    );
  }
}
