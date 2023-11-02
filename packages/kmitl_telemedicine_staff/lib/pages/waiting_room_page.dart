import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmitl_telemedicine/kmitl_telemedicine.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:kmitl_telemedicine/utils/date_time_extension.dart';
import 'package:kmitl_telemedicine_staff/pages/video_call_page.dart';
import 'package:kmitl_telemedicine_staff/providers.dart';
import 'package:kmitl_telemedicine_staff/views/user_mini_info.dart';

class WaitingRoomPage extends ConsumerStatefulWidget {
  const WaitingRoomPage({super.key, required this.roomRef});

  final DocumentReference<WaitingRoom> roomRef;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _WaitingRoomPageState();
}

class _WaitingRoomPageState extends ConsumerState<WaitingRoomPage> {
  late String _currentUserId;
  final _showFinishedUserProvider = StateProvider((ref) => false);
  late final FutureProvider<DocumentSnapshot<WaitingRoom>> _waitingRoomProvider;
  late final StreamProvider<QuerySnapshot<WaitingUser>> _waitingUsersProvider;

  @override
  void initState() {
    super.initState();
    _waitingRoomProvider = FutureProvider((ref) => widget.roomRef.get());
    _waitingUsersProvider = StreamProvider((ref) {
      final query = ref.watch(_showFinishedUserProvider)
          ? KmitlTelemedicineDb.getSortedWaitingUsers(widget.roomRef)
          : KmitlTelemedicineDb.getWaitingUsers(widget.roomRef)
              .where("status", isNotEqualTo: "finished");
      return query.snapshots();
    });
    _currentUserId = ref.read(firebaseUserProvider).requireValue!.uid;
  }

  @override
  Widget build(BuildContext context) {
    return _buildScaffold(
      ref
              .watch(_waitingRoomProvider)
              .mapOrNull(data: (data) => data.value.data()?.name) ??
          widget.roomRef.id,
      ref.watch(_waitingUsersProvider),
    );
  }

  Scaffold _buildScaffold(
    String title,
    AsyncValue<QuerySnapshot<WaitingUser>> waitingUserList,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: const [UserMiniInfo()],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildOptionBar(),
          Expanded(
            child: waitingUserList.when(
              data: (data) => _buildUserListView(data),
              error: (error, stackTrace) => Center(
                child: Text(error.toString()),
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserListView(
    QuerySnapshot<WaitingUser> data,
  ) {
    if (data.docs.isEmpty) {
      return Column(
        children: [
          _buildUserListTable(data),
          const Flexible(
            child: Center(
              child: Text("Waiting room is empty or doesn't exist"),
            ),
          ),
        ],
      );
    } else {
      return SingleChildScrollView(
        child: _buildUserListTable(data),
      );
    }
  }

  Widget _buildOptionBar() {
    return Material(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 2,
        ),
        child: Row(
          children: [
            CheckboxMenuButton(
              value: ref.watch(_showFinishedUserProvider),
              onChanged: (bool? value) {
                if (value != null) {
                  ref.read(_showFinishedUserProvider.notifier).state = value;
                }
              },
              child: const Text("Show Finished User"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserListTable(
    QuerySnapshot<WaitingUser>? data,
  ) {
    final headerStyle = Theme.of(context).textTheme.titleLarge;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Table(
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
              Text("Update", style: headerStyle),
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
          if (data != null && data.docs.isNotEmpty)
            ..._buildTableRows(data.docs),
        ],
        columnWidths: const {
          // Queue Number
          0: FixedColumnWidth(40),

          // Name
          1: FlexColumnWidth(),

          // Date
          2: FixedColumnWidth(120),

          // Status
          3: FixedColumnWidth(120),

          // Actions
          4: MaxColumnWidth(
            IntrinsicColumnWidth(),
            FixedColumnWidth(100),
          ),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        textBaseline: TextBaseline.ideographic,
      ),
    );
  }

  Iterable<TableRow> _buildTableRows(
    List<QueryDocumentSnapshot<WaitingUser>> source,
  ) sync* {
    final textStyle = Theme.of(context).textTheme.labelLarge;
    final usernameStyle = Theme.of(context).textTheme.titleMedium;

    final List<QueryDocumentSnapshot<WaitingUser>> sortedList = [...source];
    sortedList.sort((a, b) {
      final aTime =
          a.data().updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime =
          a.data().updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aTime.compareTo(bTime);
    });

    for (final (i, snapshot) in source.indexed) {
      final waitingUser = snapshot.data();
      final disableActions = waitingUser.status == WaitingUserStatus.finished;

      yield TableRow(children: [
        // Queue Number
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.baseline,
          child: Text(
            (i + 1).toString(),
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

        // Date
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.baseline,
          child: Text(
            waitingUser.updatedAt?.toLongTimestampString() ?? "unknown",
            style: textStyle,
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
            child: Row(
              children: [
                _buildCallButton(
                  disableActions
                      ? null
                      : () => context.push(
                            VideoCallPage.path,
                            extra: snapshot.reference,
                          ),
                ),
                const SizedBox(width: 4),
                _buildTransferButton(
                  disableActions
                      ? null
                      : (room) => KmitlTelemedicineDb.transferWaitingUser(
                            snapshot.reference,
                            room,
                          ),
                ),
              ],
            ),
          ),
        ),
      ]);
    }
  }

  static Widget _buildCallButton(void Function()? onPressed) => ElevatedButton(
        onPressed: onPressed,
        child: const Row(
          children: [
            Text("Call"),
            SizedBox(width: 4),
            Icon(Icons.call),
          ],
        ),
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
