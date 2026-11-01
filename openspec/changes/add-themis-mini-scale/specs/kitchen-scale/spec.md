## ADDED Requirements

### Requirement: Scale pairing
The app SHALL let the user scan for a BOOKOO Themis Mini, pair one, and forget it, on a
"Scale" screen reached from the app menu. The pairing SHALL be stored on the device and
SHALL NOT be synced. Bluetooth permissions SHALL be requested only on this screen.

#### Scenario: Pairing a scale
- **WHEN** the user turns the scale on, opens the Scale screen and picks it
- **THEN** the scale is remembered across app restarts

#### Scenario: Forgetting a scale
- **WHEN** the user forgets the paired scale
- **THEN** the weight sheet behaves as if no scale was ever paired

### Requirement: Frame parsing
The app SHALL accept a weight only from a 20-byte frame with product `03`, type `0B` and
a valid XOR checksum, and SHALL read the weight as grams x 100.

#### Scenario: Valid frame
- **WHEN** a valid frame carries the raw weight 18240
- **THEN** the reading is 182.4 g

#### Scenario: Bad checksum
- **WHEN** a frame's checksum does not match
- **THEN** the frame is ignored

#### Scenario: Other frame type
- **WHEN** a frame has a type other than `0B`
- **THEN** the frame is ignored

### Requirement: Live weight in the sheet
While `ProductWeightInputSheet` is open with a paired scale, the app SHALL search for the
scale, show its status, and follow its weight in the Weight field, with calories and
macros updating. A reading of 0 g or less SHALL NOT fill the field. An unstable reading
SHALL be marked as settling, and OK SHALL remain available.

#### Scenario: Food on the scale
- **WHEN** the sheet is open and the scale reports 182.4 g
- **THEN** the Weight field shows 182.4 and the kcal summary matches that weight

#### Scenario: Scale turned on after opening
- **WHEN** the sheet is open and the user turns the scale on
- **THEN** the sheet connects without being reopened

#### Scenario: Saving
- **WHEN** the user presses OK with a weight from the scale
- **THEN** the record is saved through the existing path with that weight

### Requirement: Manual input wins
The first keypad press in a sheet SHALL stop that sheet following the scale. A typed
weight SHALL NOT be overwritten by a reading.

#### Scenario: Typing over the scale
- **WHEN** the scale reports 182.4 g and the user types 150
- **THEN** the field stays at 150 while new readings arrive

### Requirement: Tare from the sheet
The sheet SHALL offer a Tare button while connected. It SHALL send the tare command once
the reading is stable, or after 3 seconds. After the command, readings SHALL be ignored
until one is within 1 g of zero or 3 seconds pass.

#### Scenario: Weighing two products in a row
- **WHEN** a 100 g apple is saved, the user taps Tare with the apple left on the scale, picks a pear and places 100 g of it
- **THEN** the pear's sheet shows 100 g and its record stores 100 g

#### Scenario: Stale packet after tare
- **WHEN** a frame with the old weight arrives right after the tare command
- **THEN** it does not fill the Weight field

### Requirement: Connection between products
The connection SHALL stay open for 60 seconds after the last sheet closes, and then
close.

#### Scenario: Next product
- **WHEN** the user saves a product and opens the next sheet within 60 seconds
- **THEN** the sheet shows live weight without reconnecting

#### Scenario: Leaving the scale alone
- **WHEN** no sheet is open for 60 seconds
- **THEN** the connection closes

### Requirement: Works without a scale
The sheet SHALL accept manual input as it does today, with no prompt that blocks it, when
no scale is paired, Bluetooth is off, permission is denied or the scale is not found.

#### Scenario: No paired scale
- **WHEN** no scale is paired
- **THEN** the sheet shows no scale status and no Tare button

#### Scenario: Connection lost
- **WHEN** the scale switches off while the sheet is open
- **THEN** the last weight stays in the field and the keypad and OK keep working
