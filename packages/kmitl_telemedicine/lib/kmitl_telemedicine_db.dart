import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kmitl_telemedicine/kmitl_telemedicine.dart';

class KmitlTelemedicineDb {
  static FirebaseFirestore get _dbInstance => FirebaseFirestore.instance;
  static Map<String, dynamic> get _currentTimestamp => {
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
    await pureUserRef.set(json);
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

  static DocumentReference<WaitingRoom> getWaitingRoomRef(String id) =>
      waitingRooms.doc(id);

  static Future<void> updateWaitingRoom(
      DocumentReference<WaitingRoom> roomRef, WaitingRoom waitingRoom) async {
    final pureRoomRef = _getPureReference(roomRef);
    final json = {
      ...waitingRoom.toJson(),
      ..._currentTimestamp,
    };
    await pureRoomRef.set(json);
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

  static DocumentReference<WaitingUser> getWaitingUserRef(
    DocumentReference<WaitingRoom> roomRef,
    String id,
  ) =>
      getWaitingUsers(roomRef).doc(id);

  static Future<void> setWaitingUserStatus(
    DocumentReference<WaitingUser> userRef,
    WaitingUserStatus status,
  ) async {
    await _getPureReference(userRef).set({
      "status": status.name,
      ..._currentTimestamp,
    }, SetOptions(merge: true));
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
