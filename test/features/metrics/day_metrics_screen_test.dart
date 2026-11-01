import 'package:cat_calories/features/metrics/ui/day_metric_input_sheet.dart';
import 'package:cat_calories/features/metrics/ui/day_metrics_cubit.dart';
import 'package:cat_calories/features/metrics/ui/day_metrics_screen.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/record_day.dart';
import 'package:cat_calories_core/features/metrics/domain/day_metric.dart';
import 'package:cat_calories_core/features/metrics/domain/day_metric_entry.dart';
import 'package:cat_calories_core/features/metrics/domain/day_metric_repository_interface.dart';
import 'package:cat_calories_core/features/profile/domain/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryRepository implements DayMetricRepositoryInterface {
  final Map<String, DayMetricEntry> rows = {};

  @override
  Future<List<DayMetricEntry>> findAll() async => rows.values.toList();

  @override
  Future<List<DayMetricEntry>> fetchByProfile(Profile profile) async =>
      rows.values.where((entry) => !entry.isDeleted).toList();

  @override
  Future<DayMetricEntry?> find(String id) async => rows[id];

  @override
  Future<void> save(DayMetricEntry entry) async => rows[entry.id] = entry;

  @override
  Future<void> delete(DayMetricEntry entry) async =>
      rows[entry.id] = entry.markedDeleted(DateTime.now());

  @override
  Future<void> purge(String id) async => rows.remove(id);
}

void main() {
  final profile = Profile(
    id: 'p1',
    name: 'Test',
    wakingTimeSeconds: 16 * 60 * 60,
    caloriesLimitGoal: 2000,
    createdAt: DateTime(2020),
    updatedAt: DateTime(2020),
  );
  final today = dayOf(DateTime.now());
  DateTime daysAgo(int days) =>
      DateTime(today.year, today.month, today.day - days);

  late _MemoryRepository repository;
  late DayMetricsCubit cubit;

  DayMetricEntry stored(DayMetric metric, DateTime day, double value) =>
      DayMetricEntry.manual(
        profileId: 'p1',
        metric: metric,
        day: day,
        value: value,
        note: null,
        now: DateTime.now(),
      );

  setUp(() {
    repository = _MemoryRepository();
    cubit = DayMetricsCubit(repository, profile);
  });

  tearDown(() => cubit.close());

  Future<void> pump(
    WidgetTester tester, {
    double width = 360,
    VoidCallback? onChangesClosed,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await cubit.load();
    await tester.pumpWidget(MaterialApp(
      home: BlocProvider.value(
        value: cubit,
        child: DayMetricsView(onChangesClosed: onChangesClosed),
      ),
    ));
    await tester.pumpAndSettle();
  }

  group('DayMetricsCubit', () {
    test('lists today back to 30 days ago, newest first', () async {
      await cubit.load();

      expect(cubit.state.days, hasLength(31));
      expect(cubit.state.days.first, today);
      expect(cubit.state.days.last, daysAgo(30));
    });

    test('reaches the oldest entry', () async {
      await repository.save(stored(DayMetric.steps, daysAgo(60), 1));

      await cubit.load();

      expect(cubit.state.days.last, daysAgo(60));
    });

    test('an unknown metric neither shows nor extends the list', () async {
      final json = stored(DayMetric.steps, daysAgo(60), 1).toJson()
        ..['metric_key'] = 'heart_rate';
      await repository.save(DayMetricEntry.fromJson(json));

      await cubit.load();

      expect(cubit.state.days, hasLength(31));
    });

    test('a picked date extends the list and stays after a reload', () async {
      await cubit.showFrom(daysAgo(90));
      await cubit.load();

      expect(cubit.state.days.last, daysAgo(90));
    });

    test('a value can be entered for a picked old day', () async {
      await cubit.showFrom(daysAgo(90));

      await cubit.save(DayMetric.steps, daysAgo(90), 5000, null);

      expect(
        cubit.state.entryFor(daysAgo(90), DayMetric.steps)?.value,
        5000,
      );
    });

    test('clearing returns the day to absent', () async {
      await cubit.save(DayMetric.steps, today, 5000, null);

      await cubit.clear(cubit.state.entryFor(today, DayMetric.steps)!);

      expect(cubit.state.entryFor(today, DayMetric.steps), isNull);
    });
  });

  group('DayMetricsView', () {
    testWidgets('an absent value is a dash and a saved zero is 0',
        (tester) async {
      await repository.save(stored(DayMetric.steps, today, 0));
      await pump(tester);

      expect(find.text('0'), findsOneWidget);
      expect(find.text('—'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows a long sleep value and a date at 360 px',
        (tester) async {
      await repository.save(stored(DayMetric.sleepMinutes, today, 645));
      await repository.save(stored(DayMetric.burnedKcal, today, 12400));
      await repository.save(stored(DayMetric.steps, today, 123456));
      await pump(tester);

      expect(find.text('10 h 45 min'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('typing sleep in hours stores minutes', (tester) async {
      await pump(tester);

      await tester.tap(find.text('—').at(1));
      await tester.pumpAndSettle();
      expect(find.textContaining('night that ended'), findsOneWidget);

      await tester.tap(find.text('7').last);
      await tester.pump();
      await tester.tap(find.text('.'));
      await tester.pump();
      await tester.tap(find.text('5').last);
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        cubit.state.entryFor(today, DayMetric.sleepMinutes)?.value,
        450,
      );
      expect(find.text('7 h 30 min'), findsOneWidget);
    });
  });

  group('closing the screen', () {
    testWidgets('asks for a reload after a change', (tester) async {
      var closed = 0;
      await pump(tester, onChangesClosed: () => closed++);

      await cubit.save(DayMetric.steps, today, 5000, null);
      await tester.pumpWidget(const SizedBox());

      expect(closed, 1);
    });

    testWidgets('stays quiet when nothing changed', (tester) async {
      var closed = 0;
      await pump(tester, onChangesClosed: () => closed++);

      await tester.pumpWidget(const SizedBox());

      expect(closed, 0);
    });
  });

  group('DayMetricInputSheet', () {
    Future<List<double>> pumpSheet(
      WidgetTester tester,
      DayMetric metric, {
      DayMetricEntry? entry,
      VoidCallback? onClear,
    }) async {
      final saved = <double>[];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DayMetricInputSheet(
            metric: metric,
            day: today,
            entry: entry,
            onSave: (value, note) => saved.add(value),
            onClear: onClear ?? () {},
          ),
        ),
      ));

      return saved;
    }

    testWidgets('states why too much sleep cannot be saved', (tester) async {
      final saved = await pumpSheet(tester, DayMetric.sleepMinutes);

      await tester.tap(find.text('2').last);
      await tester.pump();
      await tester.tap(find.text('5').last);
      await tester.pump();

      expect(find.text('Sleep cannot be over 24 hours'), findsOneWidget);

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(saved, isEmpty);
    });

    testWidgets('saves zero', (tester) async {
      final saved = await pumpSheet(tester, DayMetric.steps);

      await tester.tap(find.text('0').last);
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(saved, [0]);
    });

    testWidgets('prefills an existing value and offers Clear', (tester) async {
      var cleared = false;
      await pumpSheet(
        tester,
        DayMetric.sleepMinutes,
        entry: stored(DayMetric.sleepMinutes, today, 450),
        onClear: () => cleared = true,
      );

      expect(find.text('7.5'), findsOneWidget);

      await tester.tap(find.text('Clear'));
      await tester.pump();

      expect(cleared, isTrue);
    });

    testWidgets('offers no Clear without a value', (tester) async {
      await pumpSheet(tester, DayMetric.steps);

      expect(find.text('Clear'), findsNothing);
    });
  });
}
