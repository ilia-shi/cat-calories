## 1. Core functions

- [x] 1.1 Add `averageDailyKcal` in `packages/core/lib/features/calorie_tracking/domain/average_daily_kcal.dart` with the window rule from design.md
- [x] 1.2 Add `packages/core/test/unit/average_daily_kcal_test.dart` covering every scenario of the "Seven-day average" requirement, plus a window that crosses a DST switch
- [x] 1.3 Add `eatenInLast24h(records, asOf)` to core with a test for both window boundaries

## 2. Call sites

- [x] 2.1 In `tracking_tab.dart`, compute `macros24h` from `eatenInLast24h`
- [x] 2.2 In `tracking_tab.dart`, replace `_calculateAverageLast7Days` with `averageDailyKcal` and remove the `getAverageDaily` fallback
- [x] 2.3 In `tracking_tab.dart`, pass `_currentTime` as `IndicatorData.now`
- [x] 2.4 In `home_controller.dart`, replace the inline average with `averageDailyKcal`
- [x] 2.5 In `home_handler.dart`, read days through the server's calorie record repository, use `averageDailyKcal`, and pass the repository in from `packages/server/bin/server.dart`
- [x] 2.6 In `calorie_exporter.dart`, fill `calorie_content` from `caloriesPer100g`

## 3. Verification

- [x] 3.1 `cd packages/core && dart test`
- [x] 3.2 `cd packages/server && dart test` and `make test-server`
- [x] 3.3 `make test-dart` and `make test-web`
- [x] 3.4 `flutter analyze` and `make arch`
