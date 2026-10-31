## 0. Prerequisites

- [ ] 0.1 Confirm `fix-tracking-stats-numbers` is applied and archived, so `openspec/specs/tracking-stats` and `openspec/specs/data-export` exist
- [ ] 0.2 Confirm `openspec/specs/sync/spec.md` is committed

## 1. Domain

- [ ] 1.1 Add `TrackingGap` and `TrackingGapRepositoryInterface` in `packages/core/lib/features/calorie_tracking/domain/`, with `toJson`/`fromJson` in epoch milliseconds
- [ ] 1.2 Add `day_status.dart`: `DayStatus`, `DayStat`, `dayStats`, with overlap over the union of gaps
- [ ] 1.3 Test `dayStats` for every "Day status" scenario, a DST day, overlapping gaps and deleted gaps
- [ ] 1.4 Add the `dayStats` based form of `averageDailyKcal`, tested against the "Seven-day average" scenarios
- [ ] 1.5 Replace `weeklyTotals` with per-week averages, tested and with `weekly_totals_test.dart` updated
- [ ] 1.6 Add `fetchFirstRecordDay(profile)` to `CalorieRecordRepositoryInterface` and both repositories

## 2. App data

- [ ] 2.1 Check the highest migration, add `v019_add_tracking_gaps.dart` and register it in `migration_runner.dart`
- [ ] 2.2 Add `TrackingGapRepository` in `lib/features/calorie_tracking/data/sqlite/`, with a soft delete and `fetchByProfile` excluding deleted rows
- [ ] 2.3 Register the repository in `service_registry.dart`

## 3. Sync and server

- [ ] 3.1 Add `TrackingGapSyncAdapter` in core with a test mirroring `calorie_record_sync_adapter_test.dart`
- [ ] 3.2 Add `TrackingGapSyncRepository`, whose `findAllByScopes` includes soft-deleted gaps, and register it in `SyncAdapterRegistry`
- [ ] 3.3 Add a test that a soft delete replicates to a second device, through REST and folder sync
- [ ] 3.4 Add `SyncEntryRepository.findAllByUserAndType` with a test that entries of other users are excluded
- [ ] 3.5 Update `home_handler.dart` to use gaps and day statuses for `avg_7_days`, with a test for a pushed and a deleted gap
- [ ] 3.6 Update `home_controller.dart` the same way

## 4. Gap UI

- [ ] 4.1 Add `trackingGaps` and `firstRecordDay` to `HomeFetched` and load them in `_emitHomeData`
- [ ] 4.2 Add the gap sheet in `lib/features/calorie_tracking/ui/widgets/` with start, end, description, hint and validation
- [ ] 4.3 Add `TrackingGapsScreen` with list, add, edit and delete, reached from `DaysScreen`

## 5. Statuses in the UI

- [ ] 5.1 Build `DaysScreen` from `dayStats` over 30 calendar days, with display by status, highlight and tap to open the prefilled sheet
- [ ] 5.2 Show day statuses in the daily history of `main_info_tab.dart`
- [ ] 5.3 Add the empty-day count row to the Tracking tab
- [ ] 5.4 Pass only `tracked` days to `CalorieRecommendationService` in `home_bloc.dart`, with a core test for the "Recommendation uses tracked days only" scenarios
- [ ] 5.5 Switch `7-Day Avg` in `tracking_tab.dart` to the status based average
- [ ] 5.6 Rebuild `stats_widget.dart` as average kcal per day with goal line, no-data placeholder and every third label, keeping it under the widget size cap

## 6. Hours

- [ ] 6.1 Show `≥`, `—` and hidden `left`/`over` text in `indicators_widget.dart` for 24h Rolling, Today, Yesterday and Period
- [ ] 6.2 Show gap buckets as hatched in `density_scale_widget.dart`, with a "Not tracked" tooltip

## 7. LLM export

- [ ] 7.1 Add `gaps` to `LlmExportFormatter.format` and write `## Tracking gaps` with its own explanation
- [ ] 7.2 Mark `partial` day headers and write `## Unconfirmed empty days` with ranges
- [ ] 7.3 Rewrite `_writeWeeklySummary` on `dayStats`
- [ ] 7.4 Update `llm_export_formatter_test.dart` for every export scenario, including a custom preamble
- [ ] 7.5 Pass gaps through `LlmExportService.buildMarkdown` and update its registration

## 8. Verification

- [ ] 8.1 `cd packages/core && dart test`
- [ ] 8.2 `cd packages/server && dart test` and `make test-server`
- [ ] 8.3 `make test-dart` and `make test-web`
- [ ] 8.4 `flutter analyze` and `make arch`
- [ ] 8.5 Run the `review-ui` skill on the changed widgets
- [ ] 8.6 Run the app and check the flow: highlighted day, marked gap, average update, sync to a second device
