import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:kmitl_telemedicine/visit.dart';
import 'package:kmitl_telemedicine_patient/providers.dart';

enum VisitPageStatus {
  preparing,
  waiting,
  calling,
  finished,
  unknown,
}

class VisitPage extends ConsumerStatefulWidget {
  const VisitPage(
    this.visitId, {
    super.key,
    this.statusOverride,
  });

  static const String path = "/visit/:visitId";
  final String visitId;
  final VisitPageStatus? statusOverride;

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

  VisitPageStatus get status =>
      widget.statusOverride ??
      switch (_visit) {
        Visit(isFinished: true) => VisitPageStatus.finished,
        Visit(callerIds: final list) =>
          list.isEmpty ? VisitPageStatus.waiting : VisitPageStatus.calling,
        _ => VisitPageStatus.unknown,
      };

  @override
  void initState() {
    super.initState();
    _visitSubscription = ref.listenManual(
      userVisitProvider(widget.visitId),
      _onVisitStatusChaged,
    );
  }

  //--- UI ---//

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

    final display = _getVisitStatusDisplay(status);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (display.image != null)
          SizedBox(
            width: 200,
            child: Image.asset(display.image!),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Text(display.title, style: headerStyle),
              const SizedBox(height: 10),
              Text(display.description, style: bodyStyle),
            ],
          ),
        ),
        if (status == VisitPageStatus.calling)
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
        if (status == VisitPageStatus.finished)
          ElevatedButton(
            onPressed: _requestClose,
            style: const ButtonStyle(
              padding: MaterialStatePropertyAll(
                EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
              ),
            ),
            child: const Text(
              "Close",
              style: TextStyle(fontSize: 20),
            ),
          ),
      ],
    );
  }

  static ({
    String? image,
    String title,
    String description,
  }) _getVisitStatusDisplay(
    VisitPageStatus status,
  ) =>
      switch (status) {
        VisitPageStatus.preparing => (
            image: null,
            title: "Preparing",
            description: "",
          ),
        VisitPageStatus.waiting => (
            image: "assets/waiting-room.png",
            title: "Waiting",
            description: "Please wait until our staff calls you",
          ),
        VisitPageStatus.calling => (
            image: "assets/phone-call.png",
            title: "Ready to Call",
            description: "Please press the button below to start the call",
          ),
        VisitPageStatus.finished => (
            image: null,
            title: "Finished",
            description: "Your visit is finished",
          ),
        _ => (image: null, title: "", description: ""),
      };

  //--- Utils ---//

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

    switch ((prevVisit?.callerIds.isEmpty ?? true, visit.callerIds.isEmpty)) {
      case (false, true):
        if (_isCalling.value) {
          await _jitsiMeet.hangUp();
        }
        break;
      case (true, false):
        if (!_isCalling.value) {
          await _joinMeeting(visit.jitsiRoomName);
        }
        break;
      default:
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
