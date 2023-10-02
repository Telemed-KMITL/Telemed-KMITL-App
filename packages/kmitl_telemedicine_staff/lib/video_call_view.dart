import "dart:html" as html;
import "dart:ui_web" as ui;

import "package:js/js.dart";
import 'package:flutter/material.dart';

@JS()
@anonymous
class _JitsiMeetUserInfo {
  external factory _JitsiMeetUserInfo({
    String? displayName,
    String? email,
    String? avatar,
  });
}

@JS()
@anonymous
class _JitsiMeetOptions {
  external factory _JitsiMeetOptions({
    // The name of the room to join.
    String roomName,

    // The HTML DOM Element where the IFrame is added as a child.
    html.Node parentNode,

    // The JWT token.
    String jwt,

    // The JS object that contains information about the participant starting or joining the meeting (e.g., email).
    _JitsiMeetUserInfo userInfo,
  });
}

@JS("window.JitsiMeetExternalAPI")
class _JitsiMeetExternalAPI {
  external _JitsiMeetExternalAPI(
    String? domain,
    dynamic options,
  );

  external void dispose();

  external dynamic executeCommand(String command);

  external void addListener(String event, Function listener);

  external void removeListener(String event, Function listener);
}

@JS("window.builldJitsiMeetOptions")
external _builldJitsiMeetOptions(_JitsiMeetOptions options);

class VideoCallView extends StatefulWidget {
  const VideoCallView(
    this.roomName, {
    Key? key,
    this.userName,
    this.onInitialized,
    this.readyToClose,
    this.videoConferenceJoined,
    this.videoConferenceLeft,
  }) : super(key: key);

  final String roomName;
  final String? userName;
  final VoidCallback? onInitialized;
  final VoidCallback? readyToClose;
  final VoidCallback? videoConferenceJoined;
  final VoidCallback? videoConferenceLeft;

  @override
  VideoCallViewState createState() => VideoCallViewState();
}

class VideoCallViewState extends State<VideoCallView> {
  static const String kViewId = "video-conference-view";
  static const String kHtmlDivId = "video-conference-view";

  bool get initialized => _api != null;
  final ValueNotifier<bool> callingState = ValueNotifier(false);

  _JitsiMeetExternalAPI? _api;

  @override
  void initState() {
    super.initState();
    ui.platformViewRegistry.registerViewFactory(
        kViewId,
        (int id) => html.DivElement()
          ..id = kHtmlDivId
          ..style.width = "100%"
          ..style.height = "100%");
  }

  @override
  Widget build(BuildContext context) {
    return _buildHtmlView();
  }

  @override
  void dispose() {
    _api?.dispose();
    _api = null;

    super.dispose();
  }

  void hangup() async {
    _api?.executeCommand("hangup");
  }

  Widget _buildHtmlView() => HtmlElementView(
        viewType: kViewId,
        onPlatformViewCreated: _onPlatformViewCreated,
      );

  void _readyToCloseCallback(_) {
    print("Event: readyToClose");
    widget.readyToClose?.call();
  }

  void _videoConferenceJoinedCallback(_) {
    print("Event: videoConferenceJoined");
    callingState.value = true;
    widget.videoConferenceJoined?.call();
  }

  void _videoConferenceLeftCallback(_) {
    print("Event: videoConferenceLeft");
    callingState.value = false;
    widget.videoConferenceLeft?.call();
  }

  void _onPlatformViewCreated(int id) {
    final div = ui.platformViewRegistry.getViewById(id) as html.DivElement;
    final config = _builldJitsiMeetOptions(_JitsiMeetOptions(
      roomName: widget.roomName,
      parentNode: div,
      userInfo: _JitsiMeetUserInfo(displayName: widget.userName),
    ));
    const domain = "blockchain.telemed.kmitl.ac.th";

    _api = _JitsiMeetExternalAPI(domain, config)
      ..addListener("readyToClose", allowInterop(_readyToCloseCallback))
      ..addListener(
          "videoConferenceJoined", allowInterop(_videoConferenceJoinedCallback))
      ..addListener(
          "videoConferenceLeft", allowInterop(_videoConferenceLeftCallback));

    widget.onInitialized?.call();
  }
}
