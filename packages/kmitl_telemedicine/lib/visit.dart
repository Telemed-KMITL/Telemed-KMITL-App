import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'date_time_converter.dart';

part 'visit.freezed.dart';
part 'visit.g.dart';

@freezed
class Visit with _$Visit {
  const factory Visit({
    required bool isFinished,
    required String jitsiRoomName,
    @Default([]) List<String> callerIds,
    @DateTimeConverter() required DateTime createdAt,
  }) = _Visit;

  factory Visit.fromJson(Map<String, dynamic> json) => _$VisitFromJson(json);
}
