# Cat Calories

A calorie tracking app for Android built with Flutter. Track food intake across custom waking periods, browse a built-in nutritional database, manage multiple profiles, and optionally view/edit records from a PC browser.

## Features

- **Calorie tracking** -- log food entries with calories, protein, fat, and carbs; view daily and period-based summaries
- **Waking periods** -- define time-bounded periods (e.g. a work shift) with their own calorie goals, instead of only tracking by calendar day
- **Built-in food database** -- ~hundreds of products (fruits, vegetables, fish, legumes, nuts, eggs, oils, bakery) with nutritional ranges per 100g, organized by category with search
- **Custom products** -- create and manage your own products with full nutritional info and barcodes
- **Multiple profiles** -- separate calorie goals, waking durations, and history per profile
- **Smart recommendations** -- rolling calorie tracker with compensation algorithm that adjusts targets based on historical eating patterns
- **Calorie history** -- browse past entries by date with daily summaries, averages, and macro breakdowns
- **Data export** -- export today's, current period's, or all data to JSON and share
- **Embedded web server** -- start an HTTP server on port 18080 to view and edit calorie records from any device on the same network
- **Dark / light theme** -- system, light, or dark mode

## Requirements

- Flutter SDK >= 3.0.0
- Android SDK for building

## Getting started

```bash
flutter pub get
flutter run
```

## Building

```bash
flutter build apk
```

## Project structure

```
lib/
  blocs/          -- BLoC state management (home, theme)
  database/       -- SQLite helpers and seed data
    seeds/        -- built-in product nutritional database
  models/         -- data models (Profile, CalorieItem, Product, WakingPeriod, etc.)
  repositories/   -- data access layer
  screens/        -- UI, organized by feature
    home/         -- main tabs, drawer, widgets
    calories/     -- calorie history and daily views
    products/     -- product browsing and management
    profile/      -- profile create/edit
    waking_periods/
  service/        -- business logic (calorie tracker, recommendations, web server, export)
  ui/             -- theme, colors, shared widgets
  utils/          -- helpers
```

## Tech stack

- **State management**: flutter_bloc
- **Database**: sqflite (SQLite)
- **DI**: get_it
- **Fonts**: Ubuntu
