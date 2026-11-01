## 0. Spike on a real scale (blocks everything below)

- [ ] 0.1 Buy a Themis Mini, note its firmware version, and confirm with nRF Connect the 128-bit service UUID and that weight streams with the BOOKOO app disconnected
- [ ] 0.2 Record real frames for 0 g, a positive and a negative weight, and save them as test data, confirming the sign byte's encoding and the update rate
- [ ] 0.3 Test the tare command with food left on the scale in every scale mode, and record which mode to use
- [ ] 0.4 Update design.md with the findings, including the stability thresholds, and the tare fallback if it is needed

## 1. Core

- [ ] 1.1 Add `parseBookooFrame` and `bookooTareCommand`, tested on recorded frames for every "Frame parsing" scenario
- [ ] 1.2 Add `ScaleReading`, `ScaleStatus` and `ScaleConnectionInterface`
- [ ] 1.3 Add `StableWeightDetector` with tests for settling, stability and a change after stability

## 2. Bluetooth

- [ ] 2.1 Add `universal_ble`, and the Android permissions from design.md
- [ ] 2.2 Add `lib/features/scale/` with a `scale_isolation` rule in `analysis_options.yaml`
- [ ] 2.3 Implement `BookooScaleConnection`: scan, connect, notifications, tare write, and the 60-second release, tested with a fake Bluetooth layer
- [ ] 2.4 Register the interface in `service_registry.dart`
- [ ] 2.5 Add `ScalePairingScreen` with scan, pick, forget and the hint to disconnect the BOOKOO app, and its entry in the app menu

## 3. Weight sheet

- [ ] 3.1 Add the optional scale argument and status line to `ProductWeightInputSheet`, with no status when not paired
- [ ] 3.2 Follow readings in the Weight field, with the settling mark, and stop on the first keypad press
- [ ] 3.3 Add the Tare button with the stable-reading wait and stale-reading guard
- [ ] 3.4 Add widget tests with a fake connection for every scenario of "Live weight in the sheet", "Manual input wins", "Tare from the sheet" and "Works without a scale"

## 4. Verification

- [ ] 4.1 `cd packages/core && dart test`
- [ ] 4.2 `flutter test`, `flutter analyze` and `make arch`
- [ ] 4.3 Run the `review-ui` skill on the changed widgets
- [ ] 4.4 Build the APK and check on a phone with the real scale: pairing, live weight, apple then pear with tare, and the scale switched off mid-weighing
