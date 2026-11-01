## Why

Typing a weight for every product is the slowest part of logging. The user reads it off
a kitchen scale and retypes it. BOOKOO publishes an open Bluetooth protocol for the
Themis Mini, so the app can take the weight directly and tare the scale, including
between products that stay on it.

## What Changes

- Pair one BOOKOO Themis Mini with the phone from a new "Scale" screen.
- `ProductWeightInputSheet` follows the live weight while it is open. Calories and
  macros update with it, and OK saves through the existing path.
- A Tare button on the sheet zeroes the scale with food left on it, so several products
  can be weighed in a row.
- Manual keypad input always wins over the scale, and without a scale the sheet behaves
  as it does today.
- New Android Bluetooth permissions and the `universal_ble` dependency.

## Capabilities

### New Capabilities

- `kitchen-scale`: pairing, live weight, tare, and behaviour when the scale is absent.

### Modified Capabilities

None.

## Impact

- `packages/core/lib/features/scale/`: packet parser, reading model, connection
  interface. No Flutter imports.
- `lib/features/scale/`: Bluetooth implementation and pairing screen.
- `lib/common/widgets/calculator/product_weight_input_sheet.dart`, and through it all
  three callers: `product_search_field.dart`, `products_tab.dart`,
  `meal_cooking_screen.dart`.
- `lib/common/service_registry.dart`, `lib/features/dashboard/ui/app_bar.dart`,
  `analysis_options.yaml`, `android/app/src/main/AndroidManifest.xml`, `pubspec.yaml`.
- No migration, no sync change, no API change. Android only.
- Needs a physical scale: group 0 of the tasks blocks the rest.
