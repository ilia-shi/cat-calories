abstract class PlanItem {
  void setCompletedAt(DateTime completedAt);

  void setUncompleted();

  DateTime plannedAt();

  DateTime? completedAt();

  String identifier();

  Status status();

  PlanItem copy(DateTime createdAt);
}

enum Status {
  planned,
  completed,
  skipped,
}
