class DayResult {
  double valueSum;
  double positiveValueSum;
  double negativeValueSum;
  DateTime day;

  DayResult({
    required this.valueSum,
    required this.positiveValueSum,
    required this.negativeValueSum,
    required this.day,
  });

  factory DayResult.fromJson(Map<String, dynamic> json) => DayResult(
        valueSum: json['value_sum'],
        positiveValueSum: double.parse(json['positive_value_sum'].toString()),
        negativeValueSum: double.parse(json['negative_value_sum'].toString()),
        day: DateTime.fromMillisecondsSinceEpoch(
            json['record_day'] * 100000),
      );
}
