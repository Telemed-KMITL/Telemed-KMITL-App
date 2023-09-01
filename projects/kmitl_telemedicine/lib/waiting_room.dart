import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'date_time_converter.dart';

part 'waiting_room.freezed.dart';
part 'waiting_room.g.dart';

@freezed
class WaitingRoom with _$WaitingRoom {
  const factory WaitingRoom({
    required String name,
    required String description,
    @DateTimeConverter() required DateTime createdAt,
    @DateTimeConverter() DateTime? updatedAt,
  }) = _WaitingRoom;

  factory WaitingRoom.fromJson(Map<String, dynamic> json) =>
      _$WaitingRoomFromJson(json);
}
