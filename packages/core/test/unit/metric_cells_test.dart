import 'package:cat_calories_core/features/calorie_tracking/domain/calendar_cells.dart';
import 'package:cat_calories_core/features/metrics/domain/day_metric.dart';
import 'package:cat_calories_core/features/metrics/domain/day_metric_entry.dart';
import 'package:cat_calories_core/features/metrics/domain/metric_cells.dart';
import 'package:test/test.dart';

void main() {
  // A Wednesday. Its week starts on Monday, October 26.
  final now = DateTime(2026, 10, 28, 12);
  final monday = DateTime(2026, 10, 26);

  DayMetricEntry entry(
    DateTime day,
    double value, {
    DayMetric metric = DayMetric.steps,
    String? note,
  }) =>
      DayMetricEntry.manual(
        profileId: 'p1',
        metric: metric,
        day: day,
        value: value,
        note: note,
        now: now,
      );

  MetricCell week(List<DayMetricEntry> entries, DateTime start,
          {DayMetric metric = DayMetric.steps}) =>
      metricCellFor(
        entries: entries,
        metric: metric,
        start: start,
        mode: CalendarMode.weeks,
        now: now,
      );

  final lastMonday = DateTime(2026, 10, 19);

  group('metricCells', () {
    test('no value gives no cells', () {
      expect(
        metricCells(
          entries: [entry(monday, 1, metric: DayMetric.burnedKcal)],
          metric: DayMetric.steps,
          mode: CalendarMode.weeks,
          now: now,
        ),
        isEmpty,
      );
    });

    test('a month without values has a cell with a dash', () {
      final cells = metricCells(
        entries: [entry(DateTime(2026, 8, 5), 100), entry(monday, 100)],
        metric: DayMetric.steps,
        mode: CalendarMode.months,
        now: now,
      );

      expect(cells.map((cell) => cell.start.month), [8, 9, 10]);
      expect(cells[1].label, '—');
    });

    test('ignores deleted entries and other metrics', () {
      final cells = metricCells(
        entries: [
          entry(DateTime(2026, 8, 5), 100).markedDeleted(now),
          entry(DateTime(2026, 9, 5), 100, metric: DayMetric.burnedKcal),
          entry(monday, 100),
        ],
        metric: DayMetric.steps,
        mode: CalendarMode.months,
        now: now,
      );

      expect(cells.single.start, DateTime(2026, 10));
    });
  });

  group('sum', () {
    test('adds days with a value and states how many', () {
      final cell = week([
        entry(lastMonday, 8000),
        entry(DateTime(2026, 10, 20), 9000),
        entry(DateTime(2026, 10, 21), 10000),
      ], lastMonday);

      expect(cell.label, '27K');
      expect(cell.average, 9000);
      expect(cell.detailLabel, '27K, 9000 per day, 3 of 7 days');
    });

    test('today is in the sum and out of the average', () {
      final cell = week([
        entry(monday, 4000),
        entry(DateTime(2026, 10, 28), 2000),
      ], monday);

      expect(cell.value, 6000);
      expect(cell.average, 4000);
      expect(cell.countedDays, 1);
    });

    test('only today shows the sum without an average', () {
      final cell = week([entry(DateTime(2026, 10, 28), 2000)], monday);

      expect(cell.average, isNull);
      expect(cell.detailLabel, '2K');
    });

    test('a saved zero counts as a value', () {
      final cell = week([entry(lastMonday, 0), entry(DateTime(2026, 10, 20), 8000)],
          lastMonday);

      expect(cell.countedDays, 2);
      expect(cell.average, 4000);
    });

    test('burned kcal carries its unit in the details', () {
      final cell = week([
        entry(lastMonday, 2400, metric: DayMetric.burnedKcal),
      ], lastMonday, metric: DayMetric.burnedKcal);

      expect(cell.detailLabel, '2.4K kcal, 2400 per day, 1 of 7 days');
    });

    test('a value of only zero still is a value', () {
      expect(week([entry(lastMonday, 0)], lastMonday).label, '0');
    });
  });

  group('average', () {
    const sleep = DayMetric.sleepMinutes;

    test('shows the average per night', () {
      final cell = week([
        entry(lastMonday, 420, metric: sleep),
        entry(DateTime(2026, 10, 20), 480, metric: sleep),
      ], lastMonday, metric: sleep);

      expect(cell.label, '7h 30m');
      expect(cell.detailLabel, '7 h 30 min per night, 2 of 7 nights');
    });

    test('includes today, because that night has ended', () {
      final cell = week([
        entry(monday, 420, metric: sleep),
        entry(DateTime(2026, 10, 28), 480, metric: sleep),
      ], monday, metric: sleep);

      expect(cell.value, 450);
      expect(cell.countedDays, 2);
    });

    test('rounds to a whole minute', () {
      final cell = week([
        entry(lastMonday, 420, metric: sleep),
        entry(DateTime(2026, 10, 20), 421, metric: sleep),
      ], lastMonday, metric: sleep);

      expect(cell.label, '7h 1m');
    });
  });

  group('labels', () {
    test('a day shows the full value and no K', () {
      final cell = metricCellFor(
        entries: [entry(monday, 12345)],
        metric: DayMetric.steps,
        start: monday,
        mode: CalendarMode.days,
        now: now,
      );

      expect(cell.label, '12345');
      expect(cell.detailLabel, '12345');
    });

    test('compact sleep drops an empty part', () {
      expect(DayMetric.compactSleep(420), '7h');
      expect(DayMetric.compactSleep(30), '30m');
    });
  });

  group('metricBar', () {
    MetricDay day(double? value, {bool isToday = false, bool isFuture = false}) =>
        MetricDay(
          day: monday,
          value: value,
          note: null,
          isToday: isToday,
          isFuture: isFuture,
        );

    test('scales to the fixed full height of the metric', () {
      expect(metricBar(day(12000), DayMetric.steps).height, 0.6);
      expect(metricBar(day(360), DayMetric.sleepMinutes).height, 0.5);
      expect(metricBar(day(2500), DayMetric.burnedKcal).height, 0.5);
    });

    test('caps at full height in the normal kind', () {
      final bar = metricBar(day(50000), DayMetric.steps);

      expect(bar.height, 1);
      expect(bar.kind, CalendarBarKind.normal);
    });

    test('a day without a value is blank, not a highlighted slot', () {
      expect(metricBar(day(null), DayMetric.steps).kind, CalendarBarKind.blank);
    });

    test('marks today and a day that has not come', () {
      expect(
        metricBar(day(100, isToday: true), DayMetric.steps).kind,
        CalendarBarKind.today,
      );
      expect(
        metricBar(day(null, isFuture: true), DayMetric.steps).kind,
        CalendarBarKind.future,
      );
    });
  });
}
