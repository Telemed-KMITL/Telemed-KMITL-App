import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kmitl_telemedicine/kmitl_telemedicine.dart';
import 'package:kmitl_telemedicine_server/kmitl_telemedicine_server.dart';

final firebaseUserProvider = StreamProvider(
  (ref) => firebase.FirebaseAuth.instance.authStateChanges(),
);

final firebaseTokenProvider = FutureProvider((ref) async {
  final firebaseUser = ref.watch(firebaseUserProvider).valueOrNull;
  if (firebaseUser == null) {
    return null;
  } else {
    return await firebaseUser.getIdTokenResult(true);
  }
});

final userProvider = StreamProvider.autoDispose.family(
  (ref, String userId) => KmitlTelemedicineDb.getUserRef(userId).snapshots(),
);

final userVisitProvider = StreamProvider.autoDispose.family(
  (ref, DocumentReference<Visit> visitRef) => visitRef.snapshots(),
);

final userCommentProvider =
    StreamProvider.autoDispose.family((ref, DocumentReference<Visit> visitRef) {
  return KmitlTelemedicineDb.getSortedComments(visitRef).snapshots();
});

final waitingRoomListProvider = StreamProvider.autoDispose(
  (ref) => KmitlTelemedicineDb.waitingRooms.snapshots(),
);

final waitingRoomProvider = StreamProvider.autoDispose.family(
  (ref, DocumentReference<WaitingRoom> roomRef) => roomRef.snapshots(),
);

final waitingUserListProvider = StreamProvider.autoDispose.family(
  (ref, DocumentReference<WaitingRoom> roomRef) =>
      KmitlTelemedicineDb.getSortedWaitingUsers(roomRef).snapshots(),
);

final currentUserProvider = StreamProvider((ref) {
  final firebaseUser = ref.watch(firebaseUserProvider);
  final firebaseUid = firebaseUser.valueOrNull?.uid;
  if (firebaseUid == null) {
    return Stream.value(null);
  } else {
    return KmitlTelemedicineDb.getUserRef(firebaseUid).snapshots();
  }
});

final kmitlTelemedServerProvider = Provider((ref) async {
  final token = ref.watch(firebaseTokenProvider).valueOrNull?.token;
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
