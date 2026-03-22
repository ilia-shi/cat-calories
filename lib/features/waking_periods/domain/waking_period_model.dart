class WakingPeriodModel {
  int? id;
  String? description;
  final DateTime createdAt;
  DateTime updatedAt;
  DateTime startedAt;
  DateTime? endedAt;
  double caloriesValue;
  final int profileId;
  int expectedWakingTimeSeconds;
  double caloriesLimitGoal;

  WakingPeriodModel({
    required this.id,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.startedAt,
    required this.endedAt,
    required this.caloriesValue,
    required this.profileId,
    required this.expectedWakingTimeSeconds,
    required this.caloriesLimitGoal,
  });

  factory WakingPeriodModel.fromJson(Map<String, dynamic> json) => WakingPeriodModel(
        id: json['id'],
        description: json['description'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updated_at']),
        startedAt: DateTime.fromMillisecondsSinceEpoch(json['started_at']),
        endedAt: json['ended_at'] == null ? null : DateTime.fromMillisecondsSinceEpoch(json['ended_at']),
        caloriesValue: json['calories_value'],
        profileId: json['profile_id'],
        expectedWakingTimeSeconds: json['expected_waking_time_seconds'],
        caloriesLimitGoal: json['calories_limit_goal'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'started_at': startedAt.millisecondsSinceEpoch,
        'ended_at': endedAt == null ? null : endedAt!.millisecondsSinceEpoch,
        'calories_value': caloriesValue,
        'profile_id': profileId,
        'expected_waking_time_seconds': expectedWakingTimeSeconds,
        'calories_limit_goal': caloriesLimitGoal,
      };

  Duration getExpectedWakingDuration() {
    return Duration(seconds: this.expectedWakingTimeSeconds);
  }

  int getPeriodTimestamp() {
    return (startedAt.millisecondsSinceEpoch / 1000).round().toInt();
  }

  DateTime getToDateTime() {
    return startedAt.add(getExpectedWakingDuration());
  }

  int getToTimestamp() {
    return (getToDateTime().millisecondsSinceEpoch / 1000).round().toInt();
  }

  int totalRangeSeconds() {
    return getToTimestamp() - getPeriodTimestamp();
  }

  double getCaloriesPerSecond() {
    return caloriesLimitGoal / totalRangeSeconds();
  }

  double getCaloriesPerMinute() {
    return getCaloriesPerSecond() * 60;
  }

  double getCaloriesPerHour() {
    return getCaloriesPerMinute() * 60;
  }

  WakingPeriodModel setExpectedWakingDuration(Duration duration) {
    this.expectedWakingTimeSeconds = duration.inSeconds;

    return this;
  }
}
