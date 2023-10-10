import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
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
  Visit? _visit;
  bool _isCalling = false;
  bool _isClosing = false;

  JitsiMeetEventListener get _jitsiEventListeners => JitsiMeetEventListener(
        readyToClose: _readyToClose,
        conferenceJoined: (url) => setState(() => _isCalling = true),
        conferenceTerminated: (url, error) =>
            setState(() => _isCalling = false),
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
    ref.listen(userVisitProvider(widget.visitId), _onVisitStatusChaged);

    return Scaffold(
      backgroundColor: Colors.grey[800],
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Card(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_visit != null) ...[
                      Text("Status: ${_visit!.status.name}"),
                      Text("CreatedAt: ${_visit!.createdAt}"),
                      Text("IsFinished: ${_visit!.isFinished}"),
                      Text("Room: ${_visit!.jitsiRoomName}"),
                    ],
                    Text("isCalling: $_isCalling"),
                    Text("isClosing: $_isClosing"),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onVisitStatusChaged(
    AsyncValue<DocumentSnapshot<Visit>?>? prevValue,
    AsyncValue<DocumentSnapshot<Visit>?> newValue,
  ) async {
    var prevVisit = (prevValue?.valueOrNull?.exists ?? false)
        ? prevValue!.value!.data()
        : null;
    var visit =
        (newValue.valueOrNull?.exists ?? false) ? newValue.value!.data() : null;

    if (visit == null) {
      return;
    }

    if (visit.isFinished) {
      await _close();
    }

    if (prevVisit?.status != visit.status) {
      switch (visit.status) {
        case VisitStatus.waiting:
          if (_isCalling) {
            await _jitsiMeet?.hangUp();
          }
          break;
        case VisitStatus.calling:
          if (!_isCalling) {
            await _joinMeeting(visit.jitsiRoomName);
          }
          break;
      }
    }

    setState(() {
      _visit = visit;
    });
  }

  Future<void> _joinMeeting(String roomName) async {
    assert(_isCalling == false);
    final firebaseUser = ref.read(firebaseAuthStateProvider).requireValue!;
    final user = ref.read(currentUserProvider).requireValue!.data()!;
    await _jitsiMeet?.join(
      _buildJitsiOptions(
        roomName: roomName,
        token: await firebaseUser.getIdToken(),
        displayName: user.getDisplayName(),
      ),
      _jitsiEventListeners,
    );
  }

  Future<void> _close() async {
    if (_isClosing) {
      return;
    }

    // When jitsi still in call, close after called readyToClose
    if (_jitsiMeet != null && _isCalling) {
      await _jitsiMeet?.hangUp();
      _isClosing = true;
      return;
    }

    if (context.mounted) {
      context.pop();
    }
  }

  void _readyToClose() {
    if (_isClosing && context.mounted) {
      context.pop();
    }
  }

  static JitsiMeetConferenceOptions _buildJitsiOptions(
          {required String roomName, String? token, String? displayName}) =>
      JitsiMeetConferenceOptions(
          room: roomName,
          serverURL: "https://blockchain.telemed.kmitl.ac.th",
          token: token,
          userInfo: JitsiMeetUserInfo(
            displayName: displayName,
          ),
          featureFlags: {
            "add-people.enabled": false,
            "calendar.enabled": false,
            "car-mode.enabled": false,
            "close-captions.enabled": false,
            "help.enabled": false,
            "invite.enabled": false,
            "android.screensharing.enabled": false,
            "speakerstats.enabled": false,
            "kick-out.enabled": false,
            "overflow-menu.enabled": false,
            "pip.enabled": false,
            "prejoinpage.enabled": false,
            "raise-hand.enabled": false,
            "reactions.enabled": false,
            "security-options.enabled": false,
            "settings.enabled": false,
            "tile-view.enabled": false,
            "unsaferoomwarning.enabled": false,
            "video-share.enabled": false,
          });
}
