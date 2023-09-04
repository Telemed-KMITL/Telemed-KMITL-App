import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kmitl_telemedicine/kmitl_telemedicine.dart';

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
