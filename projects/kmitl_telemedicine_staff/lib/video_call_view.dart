import "package:flutter/material.dart";
import "dart:html" as html;
import "dart:ui_web" as ui;

void initializeVideoCallView() {
  ui.platformViewRegistry.registerViewFactory(
      "videoView",
      (int viewId) => html.IFrameElement()
        ..width = "100%"
        ..height = "100%"
        ..src = "https://example.com"
        ..style.border = "none");
}

class VideoCallView extends StatelessWidget {
  const VideoCallView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const HtmlElementView(
      viewType: "videoView",
    );
  }
}
