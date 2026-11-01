## Context

`ProductWeightInputSheet` already turns a typed weight into calories and macros and
saves through its callers' `onSubmit`, so the feature only has to supply the number.
`CalorieRecord.weightGrams` already stores it.

The [BOOKOO Mini protocol](https://github.com/BooKooCode/OpenSource/blob/main/bookoo_mini_scale/protocols.md)
is published under MIT:

- service `0x0FFE`, weight notifications on `0xFF11`, commands on `0xFF12`;
- a 20-byte frame of product `03`, type `0B`, a 24-bit timestamp in ms, unit, weight
  sign, 24-bit weight in grams x 100 big-endian, flow rate, battery, standby time,
  buzzer, smoothing, reserved, XOR checksum;
- tare is `03 0A 01 00 00 08`.

The firmware is proprietary, and no custom firmware was found. Reading the protocol
documents gave no update rate and no encoding for the sign byte, and no stable flag
exists. The Mini holds 1000 g on an 80 x 80 mm platform, and one device connects at a time.

## Goals / Non-Goals

**Goals:**
- Live weight and tare in the existing sheet, with no change when no scale is paired.
- A parser testable without a scale.

**Non-Goals:**
- Other scales, or more than one paired scale.
- Saving without pressing OK, or automatic tare after OK.
- Powering the scale off or resetting its sleep timer. Those commands need firmware
  v1.4.2, whose release is unconfirmed.
- iOS, desktop and web Bluetooth.
- Storing whether a weight came from the scale.

## Decisions

### `universal_ble` as the Bluetooth library

It is BSD-3-Clause and supports Android. `flutter_blue_plus` is the better known option,
but its current license requires a paid license for commercial use, including for
individuals. `flutter_reactive_ble` was not evaluated.

### Parser and interface in core

`packages/core/lib/features/scale/domain/`:

```
ScaleReading { double grams, bool isStable }
parseBookooFrame(List<int> bytes) → double? grams
bookooTareCommand
StableWeightDetector
enum ScaleStatus { notPaired, searching, connected, notFound }
abstract interface class ScaleConnectionInterface {
  Stream<ScaleStatus> status; Stream<ScaleReading> readings;
  Future<void> open(); void release(); Future<void> tare();
}
```

`parseBookooFrame` returns null for a wrong length, a wrong header or a bad checksum,
so a corrupt packet can never become a weight.

`lib/features/scale/` holds `BookooScaleConnection` and the pairing screen, with its own
`scale_isolation` rule. The sheet is in `common/widgets` and `meal_cooking_screen` is in a
sibling feature, so neither may import `features/scale`. Both reach it through the core
interface, registered in `service_registry.dart`. The sheet takes it as an optional
constructor argument defaulting to the locator, so its tests can pass a fake.

### Stability is decided in the app

The protocol has no stable flag. `StableWeightDetector` calls a reading stable when it
stayed within 0.3 g for 1 second. Both numbers are starting points for the spike.

### Manual input wins

The first keypad press stops following the scale for that sheet, and a typed weight is
never overwritten. Zero and negative readings do not fill the field. The field shows one
decimal, as the scale resolves 0.1 g.

### Tare

The Tare button waits for a stable reading, up to 3 seconds, and then writes the command.
It is disabled unless connected. After writing, readings are ignored until one is within
1 g of zero or 3 seconds pass, so a packet sent before the tare cannot record the
previous product's weight.

Automatic tare after OK was rejected: a reading that is still moving would shift the
zero with nothing on screen to show it.

If tare fails in the needed mode, the fallback is to subtract the last reading in the
app, with the scale's display showing the running total. That is decided in the spike.

### Connection lifetime

The sheet calls `open()` and `release()`. Scanning runs while a sheet is open, so turning
the scale on afterwards still connects. After the last `release()` the connection stays
for 60 seconds, so the next product does not wait, then closes so the scale's auto
power-off is not held back.

### Pairing

A "Scale" entry in the app menu opens `ScalePairingScreen`: scan, pick, forget. The id
and name live in `SharedPreferences`, per device, because a Bluetooth id means nothing on
another device. Permissions are requested only here.

### Android

`BLUETOOTH_SCAN` with `neverForLocation`, `BLUETOOTH_CONNECT`, and for Android 11 and
below `BLUETOOTH`, `BLUETOOTH_ADMIN` and `ACCESS_FINE_LOCATION` with `maxSdkVersion 30`.

## Risks / Trade-offs

- [The 1000 g limit includes the container] → Documented; a light bowl is the workaround.
- [Firmware is closed and can change] → Tests on recorded frames; a checksum failure
  leaves the sheet working by hand.
- [The BOOKOO app holds the connection] → The status reads "Not found"; the pairing
  screen says to disconnect that app.
- [The protocol copies gave different 128-bit service UUIDs] → The spike confirms it on
  the real scale.
- [Scale mode can auto-tare] → The spike tests tare in each mode, and the pairing screen
  names the mode to use.
- [`universal_ble` reliability on real phones is unproven here] → The interface keeps
  the library replaceable.
