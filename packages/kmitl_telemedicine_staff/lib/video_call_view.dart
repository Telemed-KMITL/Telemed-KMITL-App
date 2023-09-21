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
}

@JS("window.builldJitsiMeetOptions")
external _builldJitsiMeetOptions(_JitsiMeetOptions options);

class VideoCallView extends StatefulWidget {
  const VideoCallView({Key? key, required this.roomName}) : super(key: key);

  final String roomName;

  @override
  VideoCallViewState createState() => VideoCallViewState();
}

class VideoCallViewState extends State<VideoCallView> {
  static const String kViewId = "video-conference-view";
  static const String kHtmlDivId = "video-conference-view";

  bool get initialized => _api != null;

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

  Widget _buildHtmlView() => HtmlElementView(
        viewType: kViewId,
        onPlatformViewCreated: _onPlatformViewCreated,
      );

  void _onPlatformViewCreated(int id) {
    final div = ui.platformViewRegistry.getViewById(id) as html.DivElement;
    final config = _builldJitsiMeetOptions(_JitsiMeetOptions(
      roomName: widget.roomName,
      parentNode: div,
    ));
    const domain = "meet.jit.si";
    _api = _JitsiMeetExternalAPI(domain, config);
  }
}
