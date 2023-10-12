import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'date_time_converter.dart';

part 'visit.freezed.dart';
part 'visit.g.dart';

enum VisitStatus {
  waiting,
  calling,
}

@freezed
class Visit with _$Visit {
  const factory Visit({
    required VisitStatus status,
    required bool isFinished,
    required String jitsiRoomName,
    @DateTimeConverter() required DateTime createdAt,
  }) = _Visit;

  factory Visit.fromJson(Map<String, dynamic> json) => _$VisitFromJson(json);
}
