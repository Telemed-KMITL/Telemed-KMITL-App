import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kmitl_telemedicine/kmitl_telemedicine.dart';
import 'package:kmitl_telemedicine_server/kmitl_telemedicine_server.dart';

final firebaseAuthStateProvider = StreamProvider(
  (ref) => firebase.FirebaseAuth.instance.authStateChanges(),
);

final currentUserProvider = StreamProvider((ref) {
  final firebaseUser = ref.watch(firebaseAuthStateProvider);
  final firebaseUid = firebaseUser.valueOrNull?.uid;
  if (firebaseUid == null) {
    return Stream.value(null);
  } else {
    return KmitlTelemedicineDb.getUserRef(firebaseUid).snapshots();
  }
});

final kmitlTelemedServerProvider = Provider((ref) => KmitlTelemedicineServer(
      dio: Dio(
        BaseOptions(
          baseUrl: "https://blockchain.telemed.kmitl.ac.th/api",
          connectTimeout: const Duration(milliseconds: 5000),
          receiveTimeout: const Duration(milliseconds: 3000),
          followRedirects: true,
        ),
      ),
    ));
