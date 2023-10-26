import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kmitl_telemedicine/assigned_staff.dart';
import 'date_time_converter.dart';

part 'waiting_room.freezed.dart';
part 'waiting_room.g.dart';

@freezed
class WaitingRoom with _$WaitingRoom {
  @JsonSerializable(explicitToJson: true)
  const factory WaitingRoom({
    required String name,
    required String description,
    @Default([]) List<AssignedStaff> assignedStaffList,
    @Default(false) bool disableDeleting,
    @DateTimeConverter() required DateTime? updatedAt,
  }) = _WaitingRoom;

  factory WaitingRoom.fromJson(Map<String, dynamic> json) =>
      _$WaitingRoomFromJson(json);
}
