import 'package:cat_calories_core/features/calorie_tracking/domain/record_day.dart';

/// A period the user did not log food fully. Records inside it are left alone;
/// it only says they cannot be trusted as complete.
final class TrackingGap {
  String? id;
  final String profileId;
  DateTime startedAt;
  DateTime endedAt;
  String? description;
  final DateTime createdAt;
  DateTime updatedAt;

  /// A soft delete, because Syncer never pushes a deletion from the phone: a
  /// removed row would stay on the server and on every other device.
  DateTime? deletedAt;

  TrackingGap({
    required this.id,
    required this.profileId,
    required this.startedAt,
    required this.endedAt,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory TrackingGap.fromJson(Map<String, dynamic> json) => TrackingGap(
        id: json['id'],
        profileId: json['profile_id']?.toString() ?? '',
        startedAt: DateTime.fromMillisecondsSinceEpoch(json['started_at']),
        endedAt: DateTime.fromMillisecondsSinceEpoch(json['ended_at']),
        description: json['description'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updated_at']),
        deletedAt: json['deleted_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(json['deleted_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'profile_id': profileId,
        'started_at': startedAt.millisecondsSinceEpoch,
        'ended_at': endedAt.millisecondsSinceEpoch,
        'description': description,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'deleted_at': deletedAt?.millisecondsSinceEpoch,
      };

  bool get isDeleted => deletedAt != null;

  /// Half-open: a gap ending exactly at [start] does not overlap.
  bool overlaps(DateTime start, DateTime end) {
    return startedAt.isBefore(end) && endedAt.isAfter(start);
  }
}

bool gapOverlaps(List<TrackingGap> gaps, DateTime start, DateTime end) {
  return gaps.any((gap) => !gap.isDeleted && gap.overlaps(start, end));
}

/// Why a gap with these bounds cannot be saved, or null when it can. Checked on
/// save only: a pulled gap is already a fact, so sync and statistics accept it.
String? trackingGapError(DateTime startedAt, DateTime endedAt, DateTime now) {
  if (!startedAt.isBefore(endedAt)) {
    return 'The start must be before the end';
  }
  if (endedAt.isAfter(now)) {
    return 'A gap cannot end in the future';
  }
  return null;
}

/// A prefilled whole local day, cut at [now] so today stays saveable.
(DateTime, DateTime) wholeDayBounds(DateTime day, DateTime now) {
  final start = dayOf(day);
  final end = DateTime(start.year, start.month, start.day + 1);

  return (start, end.isAfter(now) ? now : end);
}
