import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'date_time_converter.dart';

part 'waiting_user.freezed.dart';
part 'waiting_user.g.dart';

enum WaitingUserStatus {
  waiting,
  onCall,
  waitingAgain,
  finished,
}

@freezed
class WaitingUser with _$WaitingUser {
  const factory WaitingUser({
    required String userName,
    required String userId,
    required WaitingUserStatus status,
    required String? jitsiRoomName,
    @DateTimeConverter() required DateTime createdAt,
  }) = _WaitingUser;

  factory WaitingUser.fromJson(Map<String, dynamic> json) =>
      _$WaitingUserFromJson(json);
}
