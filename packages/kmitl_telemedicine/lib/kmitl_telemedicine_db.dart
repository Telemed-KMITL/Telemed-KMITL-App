import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kmitl_telemedicine/kmitl_telemedicine.dart';

class KmitlTelemedicineDb {
  static FirebaseFirestore get _dbInstance => FirebaseFirestore.instance;
  static FieldValue get _currentTime => FieldValue.serverTimestamp();

  static CollectionReference<User> get users =>
      _dbInstance.collection("users").withConverter(
            fromFirestore: (snapshot, _) => User.fromJson(snapshot.data()!),
            toFirestore: (value, _) => value.toJson(),
          );

  static DocumentReference<User> getUser(String userId) => users.doc(userId);

  static Future<DocumentReference<User>> createUser(
    String name,
    List<UserRole> role,
  ) async {
    var result = await _dbInstance.collection("users").add({
      "name": name,
      "role": role,
      "createdAt": FieldValue.serverTimestamp(),
    });
    return result.withConverter(
      fromFirestore: (snapshot, _) => User.fromJson(snapshot.data()!),
      toFirestore: (value, _) => value.toJson(),
    );
  }

  static CollectionReference<WaitingRoom> get waitingRooms =>
      _dbInstance.collection("waitingRooms").withConverter(
            fromFirestore: (snapshot, _) =>
                WaitingRoom.fromJson(snapshot.data()!),
            toFirestore: (value, _) => value.toJson(),
          );

  static Query<WaitingUser> getWaitingUsers(
    DocumentReference<WaitingRoom> room,
  ) =>
      room
          .collection("waitingUsers")
          .orderBy(
            "createdAt",
            descending: true,
          )
          .withConverter(
            fromFirestore: (snapshot, _) =>
                WaitingUser.fromJson(snapshot.data()!),
            toFirestore: (value, _) => value.toJson(),
          );

  static Future<DocumentReference<WaitingUser>> addWaitingUser(
    DocumentReference<WaitingRoom> room,
    DocumentReference<User> user,
    WaitingUserStatus status,
    String? jitsiRoomName,
  ) async {
    final userDocument = await user.get();

    final response = await room.collection("waitingUsers").add({
      "userName": userDocument.data()!.name,
      "userId": user.id,
      "status": status,
      "jitsiRoomName": jitsiRoomName,
      "createdAt": _currentTime,
    });

    return response.withConverter(
      fromFirestore: (snapshot, _) => WaitingUser.fromJson(snapshot.data()!),
      toFirestore: (value, _) => value.toJson(),
    );
  }
}
