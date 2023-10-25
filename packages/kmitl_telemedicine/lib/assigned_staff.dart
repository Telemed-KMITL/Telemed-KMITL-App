import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kmitl_telemedicine/user.dart';

part 'assigned_staff.freezed.dart';
part 'assigned_staff.g.dart';

@freezed
class AssignedStaff with _$AssignedStaff {
  const factory AssignedStaff({
    @JsonKey(name: "uid") required String userId,
    @JsonKey(name: "name") required String displayName,
    required UserRole role,
  }) = _AssignedStaff;

  factory AssignedStaff.fromJson(Map<String, dynamic> json) =>
      _$AssignedStaffFromJson(json);

  factory AssignedStaff.fromSnapshot(DocumentSnapshot<User> snapshot) =>
      _AssignedStaff(
        userId: snapshot.id,
        displayName: snapshot.data()!.getDisplayName(),
        role: snapshot.data()!.role,
      );
}
