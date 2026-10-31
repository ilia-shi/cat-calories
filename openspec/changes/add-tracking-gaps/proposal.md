## Why

The app cannot tell "ate nothing" or "logged only breakfast" from "did not count that
day". Partial days read as a deficit: they lower averages and raise today's
recommended calories. The user needs to mark a period as not tracked, see which days
are worth marking, and leave a rough description so an external LLM can make estimates.

## What Changes

- New synced entity `TrackingGap`: a closed period with an optional free-text
  description. Records inside a gap stay untouched.
- Each past day gets a status: `tracked`, `empty`, `partial` or `unknown`. `empty` days
  count as 0 kcal and are highlighted so the user can mark them.
- Lists of days become a full calendar, because days without records are currently
  absent from `fetchDaysByProfile`.
- Averages, the weekly chart, the Yesterday, Today, 24h and Period indicators and the
  calorie recommendation take statuses into account.
- The weekly chart shows average kcal per day with a goal line, replacing the weekly
  total.
- The LLM export gains a tracking gaps section with descriptions, unconfirmed empty
  days and a weekly summary based on statuses.
- The 24h density scale shows gap hours as not tracked.

## Capabilities

### New Capabilities

- `tracking-gaps`: creating, editing and deleting gaps, and how they replicate.
- `day-status`: classifying days and highlighting empty ones.

### Modified Capabilities

- `tracking-stats`: the seven-day average skips days with a gap; indicators and the
  weekly chart show lower bounds and unknown values. Created by
  `fix-tracking-stats-numbers`, which must be archived first.
- `data-export`: the LLM export reports gaps and statuses. Created by
  `fix-tracking-stats-numbers`.
- `sync`: `tracking_gap` becomes a synced entity type.

## Impact

- New: core domain and sync adapter, app repository, migration v019, gap screen and
  sheet.
- Changed: `home_bloc.dart`, `home_state.dart`, `tracking_tab.dart`, `stats_widget.dart`,
  `indicators_widget.dart`, `density_scale_widget.dart`, `days_screen.dart`,
  `main_info_tab.dart`, `home_controller.dart`, `llm_export_formatter.dart`,
  `llm_export_service.dart`, `service_registry.dart`, `calorie_recommendation_service`
  callers, server `home_handler.dart` and `sync_entry_repository.dart`.
- No server schema change and no `api/openapi.yaml` shape change. `avg_7_days` changes
  value.
- Descriptions reach the server through sync, and the export file through auto-export
  when it is enabled.
- Depends on `fix-tracking-stats-numbers`.
