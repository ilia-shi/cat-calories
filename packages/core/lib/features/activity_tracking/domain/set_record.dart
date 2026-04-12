import 'package:cat_calories_core/features/activity_tracking/domain/tracking_metric.dart';
import 'package:uuid/uuid.dart';

extension type SetRecordId(String value) {
  static SetRecordId next() {
    return SetRecordId(Uuid().v4());
  }
}

enum Side { left, right, both }

final class SetRecord {
  SetRecordId id;
  int order;
  Side? side = null;
  List<MetricValue> values = [];

  SetRecord({
    required this.id,
    required this.order,
  });

  void addValue(MetricValue newValue) {
    for (var value in this.values) {
      if (newValue.metric.name == value.metric.name) {
        throw Exception(
          'The metrics ' + value.metric.name + ' is already exist.',
        );
      }
    }

    this.values.add(newValue);
  }
}
