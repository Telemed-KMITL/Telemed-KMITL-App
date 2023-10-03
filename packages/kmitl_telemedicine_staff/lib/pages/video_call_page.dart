import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:kmitl_telemedicine/kmitl_telemedicine.dart';
import 'package:kmitl_telemedicine_staff/providers.dart';
import 'package:kmitl_telemedicine_staff/transfer_waiting_user_dialog.dart';
import 'package:kmitl_telemedicine_staff/user_comment_view.dart';
import 'package:kmitl_telemedicine_staff/video_call_view.dart';

class VideoCallPage extends ConsumerStatefulWidget {
  const VideoCallPage(this.waitingUserRef, {Key? key}) : super(key: key);

  static const String path = "/calling";

  final DocumentReference<WaitingUser> waitingUserRef;

  @override
  VideoCallPageState createState() => VideoCallPageState();
}

enum _ExitReason {
  Undefined,
  UserTransfer,
  UserHangup,
}

class VideoCallPageState extends ConsumerState<VideoCallPage> {
  final GlobalKey<VideoCallViewState> _videoCallKey = GlobalKey();

  VideoCallViewState get _videoCall => _videoCallKey.currentState!;

  _ExitReason _exitReason = _ExitReason.Undefined;

  @override
  void initState() {
    super.initState();
    KmitlTelemedicineDb.setWaitingUserStatus(
      widget.waitingUserRef,
      WaitingUserStatus.onCall,
    );
  }

  @override
  void dispose() {
    if (_exitReason != _ExitReason.UserTransfer) {
      KmitlTelemedicineDb.setWaitingUserStatus(
        widget.waitingUserRef,
        WaitingUserStatus.waitingAgain,
      );
    }
    super.dispose();
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
          return snapshot.hasData
              ? _buildUi(snapshot.requireData.data()!)
              : const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildUi(WaitingUser waitingUser) {
    final visitRef =
        KmitlTelemedicineDb.getVisitRefFromWaitingUser(waitingUser);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
                color: Colors.grey.shade800,
                padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  child: VideoCallView(
                    waitingUser.jitsiRoomName,
                    key: _videoCallKey,
                    userName: ref
                        .read(currentUserProvider)
                        .value!
                        .data()!
                        .getDisplayName(),
                    readyToClose: _exit,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 60,
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
                )
              ],
            ),
          ),
        ),
        UserCommentView(visitRef),
      ],
    );
  }

  Widget _buildHangupButton() {
    return FilledButton(
      style: FilledButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(0),
        backgroundColor: Colors.red,
      ),
      onPressed: () {
        _videoCall.hangup();
        _exitReason = _ExitReason.UserHangup;
      },
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
      onPressed: () {}, // TODO: EndVisiting
      icon: const Icon(
        Icons.close,
        size: 40,
      ),
      label: const Text("End Visiting"),
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
    _videoCall.hangup();
    _exitReason = _ExitReason.UserTransfer;
  }

  void _exit() {
    if (context.mounted) {
      context.pop();
    }
  }

  Future<bool> onExit(BuildContext context) async {
    if (!_videoCall.callingState.value) {
      return true;
    }
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Stack(
          alignment: Alignment.center,
          children: [
            PointerInterceptor(child: SizedBox.expand(child: Container())),
            AlertDialog(
              title: const Text("Are you leaving this page?"),
              actions: [
                TextButton(
                  child: const Text("No"),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: const Text("Yes"),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ],
        );
      },
    );
    return result!;
  }
}
