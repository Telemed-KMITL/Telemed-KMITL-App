import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kmitl_telemedicine/kmitl_telemedicine.dart';

final firebaseAuthStateProvider = StreamProvider(
  (ref) => firebase.FirebaseAuth.instance.authStateChanges(),
);

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
      KmitlTelemedicineDb.getWaitingUsers(roomRef).snapshots(),
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
