import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kmitl_telemedicine/kmitl_telemedicine.dart';
import 'package:kmitl_telemedicine_staff/providers.dart';
import 'package:kmitl_telemedicine_staff/video_call_view.dart';

class VideoCallPage extends ConsumerStatefulWidget {
  const VideoCallPage(this.waitingUserRef, {Key? key}) : super(key: key);

  static const String path = "/calling";

  final DocumentReference<WaitingUser> waitingUserRef;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends ConsumerState<VideoCallPage> {
  final GlobalKey<VideoCallViewState> _videoCallKey = GlobalKey();

  VideoCallViewState get _videoCall => _videoCallKey.currentState!;

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
    KmitlTelemedicineDb.setWaitingUserStatus(
      widget.waitingUserRef,
      WaitingUserStatus.waitingAgain,
    );
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
    return Row(
      children: [
        Expanded(
          child: VideoCallView(
            roomName: waitingUser.jitsiRoomName,
            userName: _getUserDisplayName(
                ref.read(currentUserProvider).value!.data()!),
          ),
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

  static String _getUserDisplayName(User user) =>
      "${user.firstName} ${user.lastName}";
}
