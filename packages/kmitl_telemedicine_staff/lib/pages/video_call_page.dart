import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:kmitl_telemedicine/kmitl_telemedicine.dart';
import 'package:kmitl_telemedicine_staff/providers.dart';
import 'package:kmitl_telemedicine_staff/views/transfer_waiting_user_dialog.dart';
import 'package:kmitl_telemedicine_staff/views/user_comment_view.dart';
import 'package:kmitl_telemedicine_staff/views/video_call_view.dart';

class VideoCallPage extends ConsumerStatefulWidget {
  const VideoCallPage(this.waitingUserRef, {Key? key}) : super(key: key);

  static const String path = "/calling";

  final DocumentReference<WaitingUser> waitingUserRef;

  @override
  VideoCallPageState createState() => VideoCallPageState();
}

enum _ExitReason {
  undefined,
  userTransfer,
  userHangup,
  visitFinished,
}

class VideoCallPageState extends ConsumerState<VideoCallPage> {
  final GlobalKey<VideoCallViewState> _videoCallKey = GlobalKey();

  VideoCallViewState get _videoCall => _videoCallKey.currentState!;
  WaitingUser? _waitingUser;
  _ExitReason _exitReason = _ExitReason.undefined;
  bool _finalized = false;

  @override
  void initState() {
    super.initState();
    KmitlTelemedicineDb.setWaitingUserStatus(
      widget.waitingUserRef,
      WaitingUserStatus.onCall,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: widget.waitingUserRef.get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            _showErrorMessage("Internal Error: ${snapshot.error}");
            return Container();
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          _waitingUser ??= snapshot.requireData.data();

          if (_waitingUser == null) {
            _showErrorMessage("Failed to load WaitingUser");
            return Container();
          }

          return _buildUi(_waitingUser!);
        },
      ),
    );
  }

  Widget _buildUi(WaitingUser waitingUser) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            color: Colors.grey.shade800,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: _buildVideoCallView(waitingUser.jitsiRoomName),
                  ),
                ),
                Container(
                  height: 70,
                  padding: const EdgeInsets.only(bottom: 14),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black45,
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHangupButton(),
                      const SizedBox(width: 8),
                      _buildTransferButton(),
                      const SizedBox(width: 8),
                      _buildEndVisitingButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        UserCommentView(
          KmitlTelemedicineDb.getUserRef(waitingUser.userId),
          visitId: waitingUser.visitId,
        ),
      ],
    );
  }

  Widget _buildVideoCallView(String roomName) {
    return FutureBuilder<VideoCallView>(
      future: () async {
        final currentUser =
            (await ref.read(currentUserProvider.future))!.data()!;
        final token =
            (await ref.read(firebaseTokenProvider(false).future))?.token!;
        return VideoCallView(
          roomName,
          key: _videoCallKey,
          userName: currentUser.getDisplayName(),
          jwt: token,
          readyToClose: _videoConferenceReadyToClose,
          videoConferenceJoined: _onVideoConferenceStarted,
          videoConferenceLeft: _onVideoConferenceEnded,
          backColor: Colors.black26,
        );
      }(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return snapshot.requireData;
        }

        return Container(
          decoration: const BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: snapshot.hasError
              ? Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.info_outline),
                          const SizedBox(height: 10),
                          Text(snapshot.error?.toString() ??
                              "Unknown Error Happend"),
                        ],
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildHangupButton() {
    return FilledButton(
      style: FilledButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(0),
        backgroundColor: Colors.red,
      ),
      onPressed: () => _exit(_ExitReason.userHangup),
      child: const Icon(
        Icons.call_end,
        size: 40,
      ),
    );
  }

  Widget _buildTransferButton() {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        textStyle: const TextStyle(fontSize: 18),
        backgroundColor: Colors.orange.shade800,
      ),
      onPressed: _transferUser,
      icon: const Icon(
        Icons.logout,
        size: 40,
      ),
      label: const Text("Transfer"),
    );
  }

  Widget _buildEndVisitingButton() {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        textStyle: const TextStyle(fontSize: 18),
        backgroundColor: Colors.orange.shade800,
      ),
      onPressed: _finishVisiting,
      icon: const Icon(
        Icons.close,
        size: 40,
      ),
      label: const Text("Finish Visiting"),
    );
  }

  Widget _buildLeavePageDialog(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        PointerInterceptor(child: SizedBox.expand(child: Container())),
        AlertDialog(
          title: const Text("Leave page?"),
          content: const Text("Patient will be \"Waiting Again\"."),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => context.pop(false),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.call_end),
              label: const Text("Leave Page"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => context.pop(true),
            ),
          ],
        ),
      ],
    );
  }

  void _showErrorMessage(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.deepOrange,
      ));
    }
  }

  Future<void> _onVideoConferenceStarted() async {
    await KmitlTelemedicineDb.setVisitStatus(
      KmitlTelemedicineDb.getVisitRefFromWaitingUser(_waitingUser!),
      VisitStatus.calling,
    );
  }

  Future<void> _onVideoConferenceEnded() async {
    await KmitlTelemedicineDb.setVisitStatus(
      KmitlTelemedicineDb.getVisitRefFromWaitingUser(_waitingUser!),
      VisitStatus.waiting,
    );
  }

  Future<void> _finishVisiting() async {
    try {
      await KmitlTelemedicineDb.finishVisit(
        KmitlTelemedicineDb.getVisitRefFromWaitingUser(_waitingUser!),
        widget.waitingUserRef,
      );
    } on Exception catch (e) {
      _showErrorMessage(e.toString());
      return;
    }
    _exit(_ExitReason.visitFinished);
  }

  Future<void> _transferUser() async {
    final destination = await showDialog<DocumentReference<WaitingRoom>>(
      context: context,
      builder: (context) => Stack(
        alignment: Alignment.center,
        children: [
          PointerInterceptor(
            child: SizedBox.expand(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          TransferWaitingUserDialog(
            waitingUser: widget.waitingUserRef,
          )
        ],
      ),
    );

    if (destination == null) {
      return;
    }

    await KmitlTelemedicineDb.transferWaitingUser(
        widget.waitingUserRef, destination);
    await _exit(_ExitReason.userTransfer);
  }

  Future<void> _exit(_ExitReason reason) async {
    _exitReason = reason;

    if (_videoCall.callingState.value) {
      _videoCall.hangup();
      return;
    }

    await _finalize();
    if (context.mounted) {
      context.pop();
    }
  }

  Future<void> _videoConferenceReadyToClose() async {
    await _finalize();
    if (context.mounted) {
      context.pop();
    }
  }

  Future<bool> onLeavingPage(BuildContext context) async {
    if (!_videoCall.callingState.value) {
      await _finalize();
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: _buildLeavePageDialog,
    );
    if (result ?? false) {
      await _exit(_ExitReason.userHangup);
    }
    return false;
  }

  Future<void> _finalize() async {
    if (_finalized) {
      return;
    }
    _finalized = true;

    if (_waitingUser != null) {
      final updatingStateRequired = switch (_exitReason) {
        _ExitReason.undefined => true,
        _ExitReason.userTransfer => false,
        _ExitReason.userHangup => true,
        _ExitReason.visitFinished => false,
      };
      if (updatingStateRequired) {
        await KmitlTelemedicineDb.setWaitingUserStatus(
          widget.waitingUserRef,
          WaitingUserStatus.waitingAgain,
        );
      }
    }
  }

  @override
  void dispose() {
    _finalize().ignore();
    super.dispose();
  }
}
