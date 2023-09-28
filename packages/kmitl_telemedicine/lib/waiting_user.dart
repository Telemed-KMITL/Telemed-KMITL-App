import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'date_time_converter.dart';
import 'user.dart';

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
    required String userId,
    required String visitId,
    required User user,
    required WaitingUserStatus status,
    required String jitsiRoomName,
    @DateTimeConverter() required DateTime? updatedAt,
  }) = _WaitingUser;

  factory WaitingUser.fromJson(Map<String, dynamic> json) =>
      _$WaitingUserFromJson(json);
}
