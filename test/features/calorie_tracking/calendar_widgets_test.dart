import 'package:cat_calories/app/state/calendar_mode_cubit.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_bars.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_cell_card.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_data_builder.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_screen.dart';
import 'package:cat_calories/features/calorie_tracking/ui/calendar/calendar_widget.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calendar_cells.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/day_nutrition.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/day_status.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/tracking_gap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.now();
  DateTime daysAgo(int days) => DateTime(now.year, now.month, now.day - days);

  CalendarData data({List<TrackingGap> gaps = const []}) => CalendarData(
        profileId: 'p1',
        goal: 2000,
        nutrition: [
          for (var i = 400; i >= 0; i--)
            DayNutrition(
              day: daysAgo(i),
              kcal: i % 5 == 0 ? 5000 : 2345.67,
              protein: 112.4,
              fat: 68.2,
              carbs: 190.9,
              recordCount: 3,
              recordsWithMacros: i % 2 == 0 ? 3 : 2,
            ),
        ],
        gaps: gaps,
      );

  Future<CalendarModeCubit> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = CalendarModeCubit();
    addTearDown(cubit.close);
    await tester.pumpWidget(BlocProvider.value(
      value: cubit,
      child: MaterialApp(home: Scaffold(body: child)),
    ));

    return cubit;
  }

  testWidgets('the strip starts in weeks with the current week at the right',
      (tester) async {
    await pump(tester, CalendarStrip(data: data()));

    expect(find.text('Calendar · Weeks'), findsOneWidget);
    final cards = tester.widgetList<CalendarCellCard>(
      find.byType(CalendarCellCard),
    );
    expect(cards.first.cell.days.any((day) => day.isToday), isTrue);
  });

  testWidgets('the menu switches the mode for the strip', (tester) async {
    await pump(tester, CalendarStrip(data: data()));

    await tester.tap(find.byTooltip('Calendar options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Months'));
    await tester.pumpAndSettle();

    expect(find.text('Calendar · Months'), findsOneWidget);
  });

  testWidgets('every mode lays out on a narrow phone', (tester) async {
    final cubit = await pump(tester, CalendarStrip(data: data()));

    for (final mode in CalendarMode.values) {
      cubit.select(mode);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('the strip scrolls back into older periods', (tester) async {
    await pump(tester, CalendarStrip(data: data()));
    final newest = tester
        .widget<CalendarCellCard>(find.byType(CalendarCellCard).first)
        .cell;

    await tester.drag(find.byType(ListView), const Offset(400, 0));
    await tester.pumpAndSettle();

    final visible = tester
        .widget<CalendarCellCard>(find.byType(CalendarCellCard).first)
        .cell;
    expect(visible.start.isBefore(newest.start), isTrue);
  });

  testWidgets('tapping a cell shows the average and the gap', (tester) async {
    final gap = TrackingGap(
      id: 'g1',
      profileId: 'p1',
      startedAt: daysAgo(10),
      endedAt: daysAgo(9),
      description: 'Dinner out',
      createdAt: now,
      updatedAt: now,
    );
    await pump(tester, CalendarStrip(data: data(gaps: [gap])));

    final week = data(gaps: [gap])
        .cells(CalendarMode.weeks)
        .lastWhere((cell) => cell.hasGap);
    await tester.dragUntilVisible(
      find.text(week.kcalLabel).first,
      find.byType(ListView),
      const Offset(50, 0),
    );
    await tester.tap(find.text(week.kcalLabel).first);
    await tester.pumpAndSettle();

    expect(find.textContaining('per day'), findsOneWidget);
    expect(find.text('Dinner out'), findsOneWidget);
    expect(find.text('Add gap'), findsOneWidget);
    expect(find.text('Show records'), findsNothing);
  });

  testWidgets('a day cell offers its records', (tester) async {
    final cubit = await pump(tester, CalendarStrip(data: data()));
    cubit.select(CalendarMode.days);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CalendarCellCard).first);
    await tester.pumpAndSettle();

    expect(find.text('Show records'), findsOneWidget);
  });

  testWidgets('the full screen lays out in every mode', (tester) async {
    final cubit = await pump(tester, CalendarScreenBody(data: data()));

    for (final mode in CalendarMode.values) {
      cubit.select(mode);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('bars paint every kind of day', (tester) async {
    CalendarDay day(DayStatus? status, double kcal,
            {bool isToday = false, bool isFuture = false}) =>
        CalendarDay(
          day: now,
          status: status,
          kcal: kcal,
          isToday: isToday,
          isFuture: isFuture,
        );

    await pump(
      tester,
      SizedBox(
        width: 56,
        child: CalendarBars(
          goal: 2000,
          height: 32,
          days: [
            day(null, 0),
            day(DayStatus.tracked, 1800),
            day(DayStatus.tracked, 5000),
            day(DayStatus.partial, 900),
            day(DayStatus.unknown, 0),
            day(DayStatus.empty, 0),
            day(DayStatus.tracked, 1250, isToday: true),
            day(null, 0, isFuture: true),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
