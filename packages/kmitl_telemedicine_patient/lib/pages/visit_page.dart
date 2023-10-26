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
  static final JitsiMeet _jitsiMeet = JitsiMeet();
  static final ValueNotifier<bool> _isCalling = ValueNotifier(false);
  static final ValueNotifier<bool> _isJoined = ValueNotifier(false);

  JitsiMeetEventListener get _jitsiEventListeners => JitsiMeetEventListener(
        conferenceWillJoin: (url) {
          _isCalling.value = true;
        },
        conferenceJoined: (url) {
          _isJoined.value = true;
        },
        conferenceTerminated: (url, error) {
          _isJoined.value = false;
        },
        readyToClose: () {
          _isCalling.value = false;
          _readyToClose();
        },
      );

  Visit? _visit;
  bool _isClosing = false;
  late ProviderSubscription<AsyncValue<DocumentSnapshot<Visit>?>>
      _visitSubscription;

  @override
  void initState() {
    super.initState();
    _visitSubscription = ref.listenManual(
      userVisitProvider(widget.visitId),
      _onVisitStatusChaged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.center,
          child: _buildStatusDisplay(),
        ),
      ),
    );
  }

  Widget _buildStatusDisplay() {
    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.headlineLarge;
    final bodyStyle = theme.textTheme.titleMedium;

    (Image?, String, String) status = switch (_visit) {
      Visit(isFinished: true) => (
          null,
          "Finished",
          "Your visit is finished",
        ),
      Visit(status: VisitStatus.waiting) => (
          Image.asset("assets/waiting-room.png"),
          "Waiting",
          "Please wait until our staff calls you",
        ),
      Visit(status: VisitStatus.calling) => (
          Image.asset("assets/phone-call.png"),
          "Ready to Call",
          "Please press the button below to start the call",
        ),
      _ => (null, "", ""),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (status.$1 != null)
          SizedBox(
            width: 200,
            child: status.$1,
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Text(status.$2, style: headerStyle),
              const SizedBox(height: 10),
              Text(status.$3, style: bodyStyle),
            ],
          ),
        ),
        if (_visit?.status == VisitStatus.calling)
          ValueListenableBuilder(
            valueListenable: _isCalling,
            builder: (context, isCalling, _) => ElevatedButton(
              onPressed:
                  isCalling ? null : () => _joinMeeting(_visit!.jitsiRoomName),
              style: const ButtonStyle(
                padding: MaterialStatePropertyAll(
                  EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                ),
              ),
              child: const Text(
                "Start Call",
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
      ],
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
      await _requestClose();
    }

    if (prevVisit?.status != visit.status) {
      switch (visit.status) {
        case VisitStatus.waiting:
          if (_isCalling.value) {
            await _jitsiMeet.hangUp();
          }
          break;
        case VisitStatus.calling:
          if (!_isCalling.value) {
            await _joinMeeting(visit.jitsiRoomName);
          }
          break;
      }
    }

    setState(() => _visit = visit);
  }

  Future<void> _requestClose() async {
    if (_isClosing) {
      return;
    }
    _isClosing = true;

    // When jitsi still in call, close after called readyToClose
    if (_isCalling.value) {
      await _jitsiMeet.hangUp();
      return;
    }

    if (context.mounted) {
      _close();
    }
  }

  void _readyToClose() {
    if (_isClosing && context.mounted) {
      _close();
    }
  }

  void _close() {
    if (context.mounted) {
      context.pop();
    }
    _visitSubscription.close();
  }

  //--- Jitsi ---//

  Future<void> _joinMeeting(String roomName) async {
    assert(_isCalling.value == false);

    final firebaseUser = ref.read(firebaseUserProvider).requireValue!;
    final user = ref.read(currentUserProvider).requireValue!.data()!;

    await _jitsiMeet.join(
      _buildJitsiOptions(
        roomName: roomName,
        token: await firebaseUser.getIdToken(),
        displayName: user.getDisplayName(),
      ),
      _jitsiEventListeners,
    );
  }

  static JitsiMeetConferenceOptions _buildJitsiOptions({
    required String roomName,
    String? token,
    String? displayName,
  }) =>
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
        },
      );
}
