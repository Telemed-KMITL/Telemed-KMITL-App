import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kmitl_telemedicine/kmitl_telemedicine.dart';

class KmitlTelemedicineDb {
  static FirebaseFirestore get _dbInstance => FirebaseFirestore.instance;
  static Map<String, dynamic> get _currentTimestamp => {
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      };
  static DocumentReference<Map<String, dynamic>> _getPureReference<T>(
          DocumentReference<T> ref) =>
      ref.firestore.doc(ref.path);

  // User

  static CollectionReference<User> get users =>
      _dbInstance.collection("users").withConverter(
            fromFirestore: (snapshot, _) => User.fromJson(snapshot.data()!),
            toFirestore: (value, _) => value.toJson(),
          );

  static DocumentReference<User> getUserRef(String userId) => users.doc(userId);

  static Future<DocumentReference<User>> createOrUpdateUser(
    String userId,
    User user,
  ) async {
    final userRef = getUserRef(userId);
    final pureUserRef = _getPureReference(userRef);
    final json = {
      ...user.toJson(),
      ..._currentTimestamp,
    };
    await pureUserRef.set(json, SetOptions(mergeFields: ["createdAt"]));
    return userRef;
  }

  // WaitingRoom

  static CollectionReference<WaitingRoom> get waitingRooms =>
      _dbInstance.collection("waitingRooms").withConverter(
            fromFirestore: (snapshot, _) =>
                WaitingRoom.fromJson(snapshot.data()!),
            toFirestore: (value, _) => value.toJson(),
          );

  static Future<DocumentReference<WaitingRoom>> createWaitingRoom(
      WaitingRoom waitingRoom) async {
    final ref = waitingRooms.doc();
    await updateWaitingRoom(ref, waitingRoom);
    return ref;
  }

  static Future<void> updateWaitingRoom(
      DocumentReference<WaitingRoom> roomRef, WaitingRoom waitingRoom) async {
    final pureRoomRef = _getPureReference(roomRef);
    final json = {
      ...waitingRoom.toJson(),
      ..._currentTimestamp,
    };
    await pureRoomRef.set(json, SetOptions(mergeFields: ["createdAt"]));
  }

  // WaitingUser

  static CollectionReference<WaitingUser> getWaitingUsers(
    DocumentReference<WaitingRoom> roomRef,
  ) =>
      roomRef.collection("waitingUsers").withConverter(
            fromFirestore: (snapshot, _) =>
                WaitingUser.fromJson(snapshot.data()!),
            toFirestore: (value, _) => value.toJson(),
          );

  static Query<WaitingUser> getSortedWaitingUsers(
          DocumentReference<WaitingRoom> roomRef) =>
      getWaitingUsers(roomRef).orderBy(
        "updatedAt",
        descending: true,
      );

  static Future<DocumentReference<WaitingUser>> createWaitingUser(
      DocumentReference<WaitingRoom> roomRef,
      DocumentSnapshot<User> userSnapshot) async {
    final waitingUserRef = getWaitingUsers(roomRef).doc(userSnapshot.id);
    final waitingUserPureRef = _getPureReference(waitingUserRef);

    final json = {
      ...WaitingUser(
        userId: userSnapshot.id,
        user: userSnapshot.data()!,
        status: WaitingUserStatus.waiting,
        jitsiRoomName: null,
        createdAt: DateTime(2023),
      ).toJson(),
      ..._currentTimestamp,
    };
    waitingUserPureRef.set(json);

    return waitingUserRef;
  }

  static Future<DocumentReference<WaitingUser>> transferWaitingUser(
    DocumentReference<WaitingUser> waitingUserRef,
    DocumentReference<WaitingRoom> destinationRoomRef,
  ) async {
    final waitingUser = (await waitingUserRef.get()).data()!;
    final newDocumentRef = getWaitingUsers(destinationRoomRef).doc();
    final newDocumentPureRef = _getPureReference(newDocumentRef);

    final json = {
      ...waitingUser.toJson(),
      ..._currentTimestamp,
      "status": WaitingUserStatus.waiting.toString(),
    };

    final batch = _dbInstance.batch();
    batch.delete(waitingUserRef);
    batch.set(newDocumentPureRef, json);
    await batch.commit();

    return newDocumentRef;
  }
}
