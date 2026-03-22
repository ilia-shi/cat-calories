class DayResultModel {
  double valueSum;
  double positiveValueSum;
  double negativeValueSum;
  DateTime createdAtDay;

  DayResultModel({
    required this.valueSum,
    required this.positiveValueSum,
    required this.negativeValueSum,
    required this.createdAtDay,
  });

  factory DayResultModel.fromJson(Map<String, dynamic> json) => DayResultModel(
        valueSum: json['value_sum'],
        positiveValueSum: double.parse(json['positive_value_sum'].toString()),
        negativeValueSum: double.parse(json['negative_value_sum'].toString()),
        createdAtDay: DateTime.fromMillisecondsSinceEpoch(
            json['created_at_day'] * 100000),
      );
}
