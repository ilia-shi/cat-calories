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
  List<MetricValueInterface> values = [];

  SetRecord({
    required this.id,
    required this.order,
  });

  void addValue(MetricValueInterface newValue) {
    for (var value in this.values) {
      if (newValue.name() == value.name()) {
        throw Exception(
          'The metrics ' + value.name() + ' is already exist.',
        );
      }
    }

    this.values.add(newValue);
  }
}
