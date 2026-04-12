import 'package:cat_calories_core/features/planning/domain/plan_item.dart';

final class Plan {
  String id;
  List<PlanItem> items;

  Plan(
    this.id,
    this.items,
  );
}
