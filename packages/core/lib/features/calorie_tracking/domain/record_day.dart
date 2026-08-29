import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal.dart';

/// Midnight of [moment]'s calendar day — the key every day grouping uses.
DateTime dayOf(DateTime moment) =>
    DateTime(moment.year, moment.month, moment.day);

/// The calendar day a record belongs to: the day it was eaten if it was eaten,
/// otherwise the day it is planned for, otherwise the day it was entered.
///
/// Eaten wins over planned on purpose. Saturday's plan eaten on Sunday counts
/// on Sunday, and needs no correction from the user.
///
/// The same rule is materialized into the `created_at_day` column by
/// [CalorieRecord.toJson], so the SQL day queries and this function agree.
DateTime recordDay(CalorieRecord record) => dayOf(record.dayAnchor);

/// The day a meal belongs to, by the same rule. Only meaningful for a meal
/// holding no records: one with records is placed by where its records land,
/// so that a dish half-eaten on another day is not claimed by two days at once.
DateTime mealDay(Meal meal) =>
    dayOf(meal.eatenAt ?? meal.plannedFor ?? meal.createdAt);
