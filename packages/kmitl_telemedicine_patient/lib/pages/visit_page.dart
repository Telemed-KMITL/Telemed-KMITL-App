import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:kmitl_telemedicine/visit.dart';
import 'package:kmitl_telemedicine_patient/providers.dart';

class VisitPage extends ConsumerStatefulWidget {
  const VisitPage(this.visitId, {super.key});

  static const String path = "/visit/:visitId";
  final String visitId;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _VisitPageState();
}

class _VisitPageState extends ConsumerState<VisitPage> {
  JitsiMeet? _jitsiMeet;
  bool _isCalling = false;

  JitsiMeetEventListener get _jitsiEventListeners => JitsiMeetEventListener(
        readyToClose: () => _exit,
      );

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid || Platform.isIOS) {
      _jitsiMeet = JitsiMeet();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(userVisitProvider(widget.visitId), (_, value) async {
      var visit =
          (value.valueOrNull?.exists ?? false) ? value.value!.data() : null;
      if (visit?.status == VisitStatus.finished) {
        await _exit();
      } else if (!_isCalling && visit?.jitsiRoomName != null) {
        await _joinMeeting(visit!.jitsiRoomName!);
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey[800],
      body: Container(),
    );
  }

  Future<void> _joinMeeting(String roomName) async {
    assert(_isCalling == false);
    final user = ref.read(currentUserProvider).requireValue!.data()!;
    final result = await _jitsiMeet?.join(
      JitsiMeetConferenceOptions(
        room: roomName,
        serverURL: "https://blockchain.telemed.kmitl.ac.th",
        userInfo: JitsiMeetUserInfo(
          displayName: "${user.firstName} ${user.lastName}",
        ),
      ),
      _jitsiEventListeners,
    );
    _isCalling = result?.isSuccess ?? false;
  }

  Future<void> _exit() async {
    if (_isCalling) {
      await _jitsiMeet?.hangUp();
    }
    if (context.mounted) {
      context.pop();
    }
  }
}
