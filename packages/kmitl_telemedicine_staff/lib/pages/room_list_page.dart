import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmitl_telemedicine/kmitl_telemedicine.dart';
import 'package:kmitl_telemedicine/utils/custom_filters.dart';
import 'package:kmitl_telemedicine_staff/providers.dart';
import 'package:kmitl_telemedicine_staff/views/create_waiting_room_dialog.dart';
import 'package:kmitl_telemedicine_staff/views/page_drawer.dart';
import 'package:kmitl_telemedicine_staff/views/user_mini_info.dart';

class RoomListPage extends ConsumerStatefulWidget {
  const RoomListPage({super.key});

  static const String path = "/waitingRooms";

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _RoomListPageState();
}

class _RoomListPageState extends ConsumerState<RoomListPage> {
  final _isAdminProvider = Provider(
    (ref) =>
        ref.watch(firebaseTokenProvider(false)).valueOrNull?.claims?["role"] ==
        "admin",
  );
  final _assignStaffTargetProvider =
      StateProvider<DocumentReference<WaitingRoom>?>((ref) => null);

  @override
  Widget build(BuildContext context) {
    ref.listen(_isAdminProvider, (prev, next) {
      if (prev != next && next == false) {
        ref.read(_assignStaffTargetProvider.notifier).state = null;
      }
    });

    final waitingRoomList = ref.watch(waitingRoomListProvider);

    return Scaffold(
      drawer: PageDrawer(),
      appBar: AppBar(
        title: const Text("Waiting Rooms"),
        centerTitle: true,
        actions: const [UserMiniInfo()],
      ),
      body: waitingRoomList.when(
        data: (data) => _buildList(data),
        error: (error, stackTrace) => Center(
          child: Text(error.toString()),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      floatingActionButton:
          ref.watch(_isAdminProvider) && waitingRoomList.hasValue
              ? FloatingActionButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => const CreateWaitingRoomDialog(),
                  ),
                  tooltip: "Add WaitingRoom",
                  child: const Icon(Icons.add),
                )
              : null,
    );
  }

  Widget _buildList(QuerySnapshot<WaitingRoom> snapshot) {
    final docs = snapshot.docs;
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: docs.length,
      itemBuilder: (context, index) => _buildRoomTile(docs.elementAt(index)),
      separatorBuilder: (context, index) => const SizedBox(height: 10),
    );
  }

  Widget _buildRoomTile(QueryDocumentSnapshot<WaitingRoom> snapshot) {
    final theme = Theme.of(context);
    final room = snapshot.data();
    final uid = ref.watch(firebaseUserProvider).valueOrNull?.uid;
    bool assignedToMe =
        room.assignedStaffList.any((staff) => staff.userId == uid);

    final title = Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(room.name),
          if (assignedToMe)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                "(Assigned To You)",
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: Colors.deepOrange),
              ),
            ),
        ]);
    final actions = ref.watch(_isAdminProvider)
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _editRoom(context, snapshot),
                icon: const Icon(Icons.edit),
                tooltip: "Edit",
              ),
              if (!room.disableDeleting)
                IconButton(
                  onPressed: () => _deleteRoom(context, snapshot),
                  icon: const Icon(Icons.delete),
                  tooltip: "Delete",
                ),
            ],
          )
        : null;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(RoomListPage.path, extra: snapshot.reference),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    title: title,
                    titleTextStyle: theme.textTheme.titleLarge,
                    trailing: actions,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: 14,
                    ),
                    child: _buildAssignedStaffList(snapshot),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(10.0),
              child: Icon(Icons.arrow_forward_ios),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignedStaffList(QueryDocumentSnapshot<WaitingRoom> snapshot) {
    final room = snapshot.data();
    final wrap = Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...room.assignedStaffList
            .map((staff) => _buildAssignedStaffChip(snapshot.reference, staff))
            .toList(),
        if (ref.watch(_assignStaffTargetProvider) == snapshot.reference)
          _buildEditableAssignedStaffChip(snapshot.reference)
        else if (ref.watch(_isAdminProvider))
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 14,
            onPressed: () {
              ref.read(_assignStaffTargetProvider.notifier).state =
                  snapshot.reference;
            },
            icon: const Icon(Icons.add),
            tooltip: "Add Staff",
          )
        else if (room.assignedStaffList.isEmpty)
          const Text("None", style: TextStyle(color: Colors.grey)),
      ],
    );
    return Row(
      children: [
        const Text("Assigned Staff:"),
        const SizedBox(width: 10),
        Flexible(
          fit: FlexFit.tight,
          child: ref.watch(_isAdminProvider)
              ? Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: wrap,
                )
              : wrap,
        ),
      ],
    );
  }

  Widget _buildRoomDeleteDialog(BuildContext context, WaitingRoom room) {
    return AlertDialog(
      title: const Text("Delete this room?"),
      content: Card(
        child: ListTile(
          title: Text(room.name),
          subtitle: room.description.isNotEmpty ? Text(room.description) : null,
        ),
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

  Widget _buildAssignedStaffChip(
      DocumentReference<WaitingRoom> roomRef, AssignedStaff assignedStaff) {
    return Chip(
      label: Text(assignedStaff.displayName),
      onDeleted: ref.watch(_isAdminProvider)
          ? () {
              KmitlTelemedicineDb.unassignStaffFromWaitingRoom(
                      roomRef, assignedStaff)
                  .ignore();
            }
          : null,
    );
  }

  Widget _buildEditableAssignedStaffChip(
      DocumentReference<WaitingRoom> roomRef) {
    return Autocomplete<DocumentSnapshot<User>>(
      onSelected: (staff) {
        KmitlTelemedicineDb.assignStaffToWaitingRoom(roomRef, staff).ignore();
        ref.read(_assignStaffTargetProvider.notifier).update(
              (state) => state == roomRef ? null : state,
            );
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
        focusNode.addListener(() {
          if (focusNode.hasFocus) {
            ref.read(_assignStaffTargetProvider.notifier).state = roomRef;
          } else {
            ref.read(_assignStaffTargetProvider.notifier).update(
                  (state) => state == roomRef ? null : state,
                );
          }
        });
        return Chip(
          label: IntrinsicWidth(
            child: TextFormField(
              autofocus: true,
              controller: textEditingController,
              focusNode: focusNode,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: "Name or UserID",
              ),
              onFieldSubmitted: (String value) {
                onFieldSubmitted();
              },
            ),
          ),
        );
      },
      optionsBuilder: (value) async => await _searchStaffs(value.text),
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 200,
              maxWidth: 400,
            ),
            child: Material(
              elevation: 4,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final snapshot = options.elementAt(index);
                  final user = snapshot.data()!;
                  return ListTile(
                    title: Text(user.getDisplayName()),
                    subtitle: Text("${snapshot.id} (${user.role.name})"),
                    onTap: () => onSelected(snapshot),
                  );
                },
              ),
            ),
          ),
        );
      },
      displayStringForOption: (staff) => staff.data()!.getDisplayName(),
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

  Future<List<DocumentSnapshot<User>>> _searchStaffs(String input) async {
    final roleFilter = Filter.or(
      Filter("role", isEqualTo: UserRole.nurse.name),
      Filter("role", isEqualTo: UserRole.doctor.name),
      Filter("role", isEqualTo: UserRole.admin.name),
    );

    if (input.isEmpty) {
      return (await KmitlTelemedicineDb.users.where(roleFilter).limit(20).get())
          .docs;
    }
    var values = input.split(' ').where((s) => s.isNotEmpty);
    if (values.isEmpty || values.length > 2) {
      return [];
    }

    if (values.length == 1 &&
        RegExp(r"[a-zA-Z0-9]{28}$").hasMatch(values.first)) {
      final idSearchResult =
          await KmitlTelemedicineDb.getUserRef(values.first).get();
      return idSearchResult.exists ? [idSearchResult] : [];
    }

    final nameFilter = values.length == 1
        ? CustomFilters.startsWith("firstName", values.first)
        : Filter.and(
            Filter("firstName", isEqualTo: values.first),
            CustomFilters.startsWith("lastName", values.last),
          );

    final query =
        KmitlTelemedicineDb.users.where(roleFilter).where(nameFilter).limit(20);

    return (await query.get()).docs;
  }
}
