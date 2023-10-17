import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kmitl_telemedicine/kmitl_telemedicine.dart';
import 'package:kmitl_telemedicine_server/kmitl_telemedicine_server.dart';

final firebaseUserProvider = StreamProvider(
  (ref) => firebase.FirebaseAuth.instance.authStateChanges(),
);

final currentUserRefProvider = Provider((ref) {
  final firebaseUser = ref.watch(firebaseUserProvider);
  final firebaseUid = firebaseUser.valueOrNull?.uid;
  if (firebaseUid == null) {
    return null;
  } else {
    return KmitlTelemedicineDb.getUserRef(firebaseUid);
  }
});

final currentUserProvider = StreamProvider((ref) {
  final userRef = ref.watch(currentUserRefProvider);
  if (userRef == null) {
    return Stream.value(null);
  } else {
    return userRef.snapshots();
  }
});

final userVisitProvider =
    StreamProvider.family.autoDispose((ref, String visitId) {
  final userRef = ref.watch(currentUserRefProvider);
  if (userRef == null) {
    return Stream.value(null);
  } else {
    return KmitlTelemedicineDb.getVisitRef(userRef, visitId).snapshots();
  }
});

final kmitlTelemedServerProvider = FutureProvider((ref) async {
  final token = await ref.watch(firebaseUserProvider).valueOrNull?.getIdToken();
  final server = KmitlTelemedicineServer(
    dio: Dio(
      BaseOptions(
        baseUrl: "https://blockchain.telemed.kmitl.ac.th/api",
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 3),
        followRedirects: true,
      ),
    ),
  );
  if (token != null) {
    server.setBearerAuth("FirebaseJwtBarer", token);
  }
  return server;
});
