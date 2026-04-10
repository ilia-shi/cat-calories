class DayResult {
  double valueSum;
  double positiveValueSum;
  double negativeValueSum;
  DateTime createdAtDay;

  DayResult({
    required this.valueSum,
    required this.positiveValueSum,
    required this.negativeValueSum,
    required this.createdAtDay,
  });

  factory DayResult.fromJson(Map<String, dynamic> json) => DayResult(
        valueSum: json['value_sum'],
        positiveValueSum: double.parse(json['positive_value_sum'].toString()),
        negativeValueSum: double.parse(json['negative_value_sum'].toString()),
        createdAtDay: DateTime.fromMillisecondsSinceEpoch(
            json['created_at_day'] * 100000),
      );
}
