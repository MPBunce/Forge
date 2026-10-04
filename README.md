# Forge

**Lift, run, and show up every day.**

Forge is a training log for lifting cycles, running plans, daily bodyweight work, stretching, step goals and personal challenges, with progress charts and habit grids that make consistency visible. Built with SwiftUI and SwiftData.

<p align="center">
  <img src="assets/screenshots/6.9-inch/02-today.png" width="160" alt="Today">
  <img src="assets/screenshots/6.9-inch/03-training-strength.png" width="160" alt="Strength training">
  <img src="assets/screenshots/6.9-inch/04-training-running.png" width="160" alt="Running">
  <img src="assets/screenshots/6.9-inch/05-progress-activity.png" width="160" alt="Activity">
  <img src="assets/screenshots/6.9-inch/06-progress-charts.png" width="160" alt="Charts">
</p>

Forge was previously released as **Strength Cycles**. It keeps the same bundle identifier (`mpbunce.Strength-Cycles`) so existing installs update in place and keep their data.

## Features

### Today
The home tab for the current day.

- **Steps**: today's step count from Apple Health, progress toward your daily goal, and the last seven days at a glance. Set the goal in Settings.
- **Daily Work**: bodyweight exercises you do every day, using one of three methods:
  - *Total reps*: hit a number of reps spread across the day.
  - *Ladder*: 1, 2, 3 … up to a peak rung.
  - *Sets*: a fixed number of sets of a fixed number of reps.

  Log reps with the quick-add button or set an exact count. Logs reset each day.
- **Stretching**: guided routines such as DeFranco's Agile 8, a quick 5 Stretches, and Starting Stretching levels, logged once a day.
- **Challenges**: one-off goals you tick off when done. Start from presets (Villain Challenge stages, 60s dead hang, 100 push-ups in one set, 20 strict pull-ups, Murph, Deck of Cards, 10,000 swings and more) or write your own.

### Training
- Start a cycle from a built-in program: 5/3/1, 5/3/1 Boring But Big, nSuns (4, 5 and 6 day), Greyskull LP, Menzer, Arnold Split, Push Pull Legs, or Upper Lower (4 and 5 day).
- 5/3/1 and nSuns calculate working weights from your training maxes. The other programs leave weights blank for you to fill in.
- **Custom templates** (Forge Plus): build your own program with named days and exercises prescribed as sets × reps, with an optional AMRAP last set. Find them under *My Templates* when adding a cycle; swipe to edit or delete.
- Tick off sets as you go: tap once for done, twice for failed, three times to reset. AMRAP sets open a sheet to log the reps you hit.

### Running
Under Training › Running, separate from strength cycles.

- Plans: Couch to 5K, 5K to 10K and Half Marathon. Interval runs have a guided timer with spoken run/walk cues.
- **Custom running plans** (Forge Plus): intervals, timed runs or distances, grouped into weeks.
- Log distance and (for distance runs) time after each run; log single runs outside a plan.
- Log race results for 5K, 10K, half and full marathon, with pace and personal bests.

### Progress
- **Charts**: estimated one-rep max over time for squat, bench, deadlift and overhead press, using sets marked done on completed training days.
- **Activity**: GitHub-style grids of the last 16 weeks for Worked Out, Ran, Step Goal, Daily Work and Stretching. Tap one for its full history.
- **Goals**: strength milestones that tick themselves off from logged sets, and running goals for each race distance, including a fixed top-5% time.
- **Badges**: workouts and step days per year, kilometres run per year, and unbroken streaks for daily work and stretching.

### Widgets
A medium Home Screen widget for each Activity grid, showing this year's total or the current streak. Tapping one opens that habit's history.

### Settings
- Weight unit (lbs or kg). Each cycle keeps the unit it was created with.
- Training maxes for squat, bench, deadlift and overhead press.
- Daily step goal.
- Equipment: barbell weight and smallest plate, used to round calculated weights.
- Appearance: System, Light or Dark.

A full in-app guide lives under Settings › How Forge Works.

## Forge Plus

Plus unlocks creating your own strength templates and running plans; everything else is free. It's a one-time, non-consumable in-app purchase with product ID `mpbunce.forge.plus`, bought and restored in Settings › Forge Plus. `Forge/Models/Plus/PlusStore.swift` uses StoreKit 2 to check what's owned at launch and on every App Store update (including refunds) and sets `ForgePlus.isActive`. Development (DEBUG) builds have Plus on by default, with a toggle under Settings › Forge Plus. `ForgeTests/ForgePlus.storekit` is a local StoreKit configuration used by the purchase test.

## Requirements

- Xcode 16 or later
- iOS 18.4 or later
- HealthKit capability (already configured in `Forge.entitlements`). Step tracking needs a device or simulator with the Health app.

## Getting started

1. Open `Forge.xcodeproj` in Xcode.
2. Select the **Forge** scheme and an iPhone simulator or device.
3. Build and run (⌘R).

To run on your own device, set your development team under *Signing & Capabilities*.

## Project structure

```
Forge/
├── ForgeApp.swift          App entry point and SwiftData container
├── ContentView.swift       Tab bar: Today, Training, Progress, Settings
├── Models/
│   ├── Cycles/             Cycles, training days, exercises, sets, custom templates
│   ├── ProgramTemplates/   Built-in programs and default set schemes
│   ├── Progress/           Strength goals
│   ├── Settings/           User settings and unit conversion
│   └── Today/              Daily work, challenges, Apple Health step counter
└── Views/
    ├── TodayViews/
    ├── CyclesViews/        Includes the custom template editor
    ├── ProgressViews/
    └── SettingsViews/
ForgeWidget/                Streak widgets (WidgetKit extension)
Shared/                     Code shared by the app and widgets: habit list and the App Group snapshot
```

## Data and privacy

All training data is stored on device with SwiftData. Step counts are read from Apple Health with your permission and are never written back or sent anywhere.

## Credits

- Launch screen photo: marble copy of the *Farnese Hercules*, from [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Marble_copy_of_the_famous,_bronze_%E2%80%9CHercules_Farnese%E2%80%9D_03.jpg), released under CC0 (no rights reserved).
- Launch screen quote: Alexis Carrel.
