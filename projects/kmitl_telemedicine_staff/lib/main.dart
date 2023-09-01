import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kmitl_telemedicine_staff/room_list_page.dart';
import 'package:kmitl_telemedicine_staff/video_call_view.dart';
import 'firebase_options.dart';

Future<void> main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  initializeVideoCallView();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xfff0542c),
          primary: const Color(0xfff0542c),
        ),
      ),
      home: RoomListPage(),
    );
  }
}
