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
  UserTransferred,
  Hangupped,
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
    if (_exitReason != _ExitReason.UserTransferred) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                ),
              ),
              Row(
                children: [
                  _buildHangupButton(),
                  _buildTransferButton(),
                ],
              )
            ],
          ),
        ),
        UserCommentView(visitRef),
      ],
    );
  }

  Widget _buildHangupButton() {
    return FilledButton(
      onPressed: () {
        _videoCall.hangup();
        _exit(_ExitReason.Hangupped);
      },
      child: const Icon(
        Icons.call_end,
        size: 40,
      ),
    );
  }

  Widget _buildTransferButton() {
    return FilledButton.icon(
      onPressed: _transferUser,
      icon: const Icon(
        Icons.logout,
        size: 40,
      ),
      label: const Text("Transfer"),
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
          PointerInterceptor(child: SizedBox.expand(child: Container())),
          TransferWaitingUserDialog(
            waitingUser: widget.waitingUserRef,
          )
        ],
      ),
    );

    if (destination == null) {
      return;
    }

    _videoCall.hangup();
    await KmitlTelemedicineDb.transferWaitingUser(
        widget.waitingUserRef, destination);

    _exit(_ExitReason.UserTransferred);
  }

  void _exit(_ExitReason reason) {
    if (context.mounted) {
      context.pop();
    }
    _exitReason = reason;
  }

  Future<bool> onExit(BuildContext context) async {
    if (_exitReason != _ExitReason.Undefined) {
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
              actions: <Widget>[
                TextButton(
                  style: TextButton.styleFrom(
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  child: const Text("No"),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  child: const Text("Yes"),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
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
