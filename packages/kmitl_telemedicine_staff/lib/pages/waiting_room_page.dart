import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmitl_telemedicine/kmitl_telemedicine.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:kmitl_telemedicine_staff/pages/video_call_page.dart';
import 'package:kmitl_telemedicine_staff/providers.dart';

class WaitingRoomPage extends ConsumerStatefulWidget {
  const WaitingRoomPage({super.key, required this.roomRef});

  final DocumentReference<WaitingRoom> roomRef;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _WaitingRoomPageState();
}

class _WaitingRoomPageState extends ConsumerState<WaitingRoomPage> {
  @override
  Widget build(BuildContext context) {
    final waitingRoom = ref.watch(waitingRoomProvider(widget.roomRef));

    return waitingRoom.when(
      data: (snapshot) {
        return _buildScaffold(
          snapshot.exists ? snapshot.data()!.name : snapshot.id,
          snapshot.exists
              ? ref.watch(waitingUserListProvider(snapshot.reference))
              : const AsyncData(null),
        );
      },
      loading: () => _buildScaffold(
        widget.roomRef.id,
        const AsyncLoading(),
      ),
      error: (error, stackTrace) => Center(
        child: Text(error.toString()),
      ),
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
    );
  }

  Scaffold _buildScaffold(
    String title,
    AsyncValue<QuerySnapshot<WaitingUser>?> waitingUserList,
  ) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: waitingUserList.when(
        data: (data) => _buildUserListView(data),
        error: (error, stackTrace) => Center(
          child: Text(error.toString()),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildUserListView(
    QuerySnapshot<WaitingUser>? data,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          _buildUserListTable(data),
          if (data == null || data.docs.isEmpty)
            const Expanded(
              child: Center(
                child: Text("Waiting room is empty or doesn't exist"),
              ),
            )
        ],
      ),
    );
  }

  Table _buildUserListTable(
    QuerySnapshot<WaitingUser>? data,
  ) {
    final headerStyle = Theme.of(context).textTheme.titleLarge;

    return Table(
      children: [
        // Header
        TableRow(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          children: [
            const Icon(Icons.numbers),
            Text("Name", style: headerStyle),
            Text("Status", style: headerStyle),
            Text("Actions", style: headerStyle),
          ]
              .map((w) => TableCell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: w,
                    ),
                  ))
              .toList(),
        ),

        // Contents
        if (data != null && data.docs.isNotEmpty) ..._buildTableRows(data.docs),
      ],
      columnWidths: const {
        // Queue Number
        0: FixedColumnWidth(40),

        // Name
        1: FlexColumnWidth(),

        // Status
        2: FixedColumnWidth(120),

        // Actions
        3: MaxColumnWidth(
          IntrinsicColumnWidth(),
          FixedColumnWidth(100),
        ),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      textBaseline: TextBaseline.ideographic,
    );
  }

  Iterable<TableRow> _buildTableRows(
    List<QueryDocumentSnapshot<WaitingUser>> source,
  ) {
    final textStyle = Theme.of(context).textTheme.labelLarge;
    final usernameStyle = Theme.of(context).textTheme.titleMedium;

    int i = 0;
    return source.map((document) {
      i++;

      final waitingUser = document.data();
      return TableRow(children: [
        // Queue Number
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.baseline,
          child: Text(
            i.toString(),
            textAlign: TextAlign.center,
            style: textStyle,
          ),
        ),

        // Name
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.baseline,
          child: Text(
            waitingUser.user.getDisplayName(),
            style: usernameStyle,
          ),
        ),

        // Status
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.baseline,
          child: Text(
            waitingUser.status.name,
            style: textStyle,
          ),
        ),

        // Actions
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.baseline,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(children: [
              _buildCallButton(
                () =>
                    context.push(VideoCallPage.path, extra: document.reference),
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
    void Function(DocumentReference<WaitingRoom>)? onSelected,
  ) {
    final waitingRoomList = ref.watch(waitingRoomListProvider).valueOrNull;

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
        items: waitingRoomList?.docs.map(
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
