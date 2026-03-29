final class Profile {
  String? id;
  String name;
  int wakingTimeSeconds;
  double caloriesLimitGoal;
  final DateTime createdAt;
  DateTime updatedAt;

  Profile({
    required this.id,
    required this.name,
    required this.wakingTimeSeconds,
    required this.caloriesLimitGoal,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id']?.toString(),
        name: json['name'],
        wakingTimeSeconds: json['waking_time_seconds'],
        caloriesLimitGoal: json['calories_limit_goal'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'waking_time_seconds': wakingTimeSeconds,
        'calories_limit_goal': caloriesLimitGoal,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  Duration getExpectedWakingDuration() {
    return Duration(seconds: this.wakingTimeSeconds);
  }

  Profile setExpectedWakingDuration(Duration duration) {
    this.wakingTimeSeconds = duration.inSeconds;

    return this;
  }
}
