//
//  SettingsView.swift
//  Forge
//
//  Created by Matthew Bunce on 2025-06-01.
//
import SwiftUI
import SwiftData

 
struct SettingsView: View {
    @Environment(\.modelContext) var context
    @Query var settings: [Settings]
    @AppStorage(PreferenceKeys.appearance) private var appearance = AppearanceMode.system.rawValue
    @AppStorage(PreferenceKeys.importHealthRuns) private var importHealthRuns = false
    @AppStorage(PreferenceKeys.restTimerEnabled) private var restTimerEnabled = true
    private var plus = ForgePlus.shared
    @State private var importMessage: String?
    
    private var userSettings: Settings {
        if let existingSettings = settings.first {
            return existingSettings
        } else {
            // This shouldn't happen if we initialize properly, but fallback
            let newSettings = Settings.defaultSettings
            context.insert(newSettings)
            try? context.save()
            return newSettings
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                // About Section
                Section {
                    NavigationLink(destination: AboutView()) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            Text("About")
                        }
                    }
                    NavigationLink(destination: ForgePlusView()) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            Text("Forge Plus")
                        }
                    }
                    NavigationLink(destination: GuideView()) {
                        HStack {
                            Image(systemName: "book")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            Text("How Forge Works")
                        }
                    }
                }
                
                // Appearance Section
                Section("Appearance") {
                    Picker(selection: $appearance) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.title).tag(mode.rawValue)
                        }
                    } label: {
                        Label("Theme", systemImage: "circle.lefthalf.filled")
                    }
                }
                
                // Units Section
                Section {
                    Picker(selection: Binding(
                        get: { userSettings.usesKilograms },
                        set: { newValue in updateSetting { userSettings.usesKilograms = newValue } }
                    )) {
                        Text("lbs").tag(false)
                        Text("kg").tag(true)
                    } label: {
                        Label("Weight Unit", systemImage: "scalemass")
                    }
                } header: {
                    Text("Units")
                } footer: {
                    Text("Existing cycles keep the unit they were created with.")
                }
                
                // Daily Steps Section
                Section {
                    Stepper(value: Binding(
                        get: { userSettings.dailyStepGoal },
                        set: { newValue in updateSetting { userSettings.dailyStepGoal = newValue } }
                    ), in: 1_000...50_000, step: 500) {
                        // Value under the title: side by side with the stepper the row was too narrow.
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Daily Step Goal")
                                Text("\(userSettings.dailyStepGoal.formatted()) steps")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                        } icon: {
                            Image(systemName: "figure.walk")
                        }
                    }
                } header: {
                    Text("Steps")
                } footer: {
                    Text("Steps are read from Apple Health and shown on the Today tab.")
                }

                Section {
                    Toggle(isOn: $importHealthRuns) {
                        Label("Import Runs from Health", systemImage: "heart.text.square")
                    }
                    .onChange(of: importHealthRuns) { _, on in
                        guard on else { importMessage = nil; return }
                        Task {
                            let added = await HealthRunImporter.importNewRuns(into: context)
                            importMessage = added == 0 ? "No new runs found in the last \(HealthRunImporter.firstImportDays) days."
                                : "Added \(added) run\(added == 1 ? "" : "s") from Apple Health."
                        }
                    }
                } header: {
                    Text("Running")
                } footer: {
                    Text(importMessage ?? "Running workouts from Apple Health, like Apple Watch or Strava runs, are added to Training › Running and count on the Ran grid.")
                }
                
                // Rest Timer (Forge Plus)
                Section {
                    if plus.isActive {
                        Toggle(isOn: $restTimerEnabled) {
                            Label("Rest Timer", systemImage: "timer")
                        }
                        if restTimerEnabled {
                            Picker(selection: Binding(
                                get: { userSettings.defaultRestTime },
                                set: { newValue in updateSetting { userSettings.defaultRestTime = newValue } }
                            )) {
                                ForEach(RestTimer.durations, id: \.self) { seconds in
                                    Text(RaceTime.format(seconds)).tag(seconds)
                                }
                            } label: {
                                Label("Rest Length", systemImage: "hourglass")
                            }
                        }
                    } else {
                        NavigationLink {
                            ForgePlusView()
                        } label: {
                            HStack {
                                Label("Rest Timer", systemImage: "lock")
                                Spacer()
                                PlusBadge()
                            }
                        }
                    }
                } header: {
                    Text("Workouts")
                } footer: {
                    Text("Starts a countdown when you tick off a set, and notifies you when rest is over. Tap the weight while logging a set to see the plates for each side.")
                }

                // Equipment Section
                Section {
                    Picker(selection: Binding(
                        get: { userSettings.usesKilograms ? userSettings.barbellKg : userSettings.barbellLbs },
                        set: { newValue in updateSetting {
                            if userSettings.usesKilograms { userSettings.barbellKg = newValue } else { userSettings.barbellLbs = newValue }
                        } }
                    )) {
                        ForEach(userSettings.usesKilograms ? WeightRounding.barbellOptionsKg : WeightRounding.barbellOptionsLbs, id: \.self) { weight in
                            Text("\(WeightConverter.format(weight)) \(userSettings.weightUnitString)").tag(weight)
                        }
                    } label: {
                        Label("Barbell", systemImage: "line.horizontal.3")
                    }

                    Picker(selection: Binding(
                        get: { userSettings.usesKilograms ? userSettings.smallestPlateKg : userSettings.smallestPlateLbs },
                        set: { newValue in updateSetting {
                            if userSettings.usesKilograms { userSettings.smallestPlateKg = newValue } else { userSettings.smallestPlateLbs = newValue }
                        } }
                    )) {
                        ForEach(userSettings.usesKilograms ? WeightRounding.plateOptionsKg : WeightRounding.plateOptionsLbs, id: \.self) { plate in
                            Text("\(WeightConverter.format(plate)) \(userSettings.weightUnitString)").tag(plate)
                        }
                    } label: {
                        Label("Smallest Plate", systemImage: "circle.circle")
                    }
                } header: {
                    Text("Equipment")
                } footer: {
                    let rounding = userSettings.weightRounding
                    Text("Calculated weights round down to the nearest \(WeightConverter.format(rounding.increment)) \(userSettings.weightUnitString) (one smallest plate per side) and never go below the \(WeightConverter.format(rounding.barbell)) \(userSettings.weightUnitString) bar. Applies to new cycles.")
                }

                // Training Maxes Section
                Section {
                    TrainingMaxRow(
                        title: "Bench Press",
                        icon: "dumbbell",
                        value: Binding(
                            get: { displayValue(userSettings.benchPressMax) },
                            set: { newValue in
                                updateSetting { userSettings.benchPressMax = userSettings.convertInputToStorageUnit(newValue) }
                            }
                        ),
                        unit: userSettings.weightUnitString
                    )
                    .id(userSettings.usesKilograms) // reload the text when the unit flips
                    
                    TrainingMaxRow(
                        title: "Squat",
                        icon: "dumbbell",
                        value: Binding(
                            get: { displayValue(userSettings.squatMax) },
                            set: { newValue in
                                updateSetting { userSettings.squatMax = userSettings.convertInputToStorageUnit(newValue) }
                            }
                        ),
                        unit: userSettings.weightUnitString
                    )
                    .id(userSettings.usesKilograms) // reload the text when the unit flips
                    
                    TrainingMaxRow(
                        title: "Deadlift",
                        icon: "dumbbell",
                        value: Binding(
                            get: { displayValue(userSettings.deadliftMax) },
                            set: { newValue in
                                updateSetting { userSettings.deadliftMax = userSettings.convertInputToStorageUnit(newValue) }
                            }
                        ),
                        unit: userSettings.weightUnitString
                    )
                    .id(userSettings.usesKilograms) // reload the text when the unit flips
                    
                    TrainingMaxRow(
                        title: "Overhead Press",
                        icon: "dumbbell",
                        value: Binding(
                            get: { displayValue(userSettings.overheadPressMax) },
                            set: { newValue in
                                updateSetting { userSettings.overheadPressMax = userSettings.convertInputToStorageUnit(newValue) }
                            }
                        ),
                        unit: userSettings.weightUnitString
                    )
                    .id(userSettings.usesKilograms) // reload the text when the unit flips
                } header: {
                    Text("Training Maxes")
                } footer: {
                    Text("Used to calculate weights when you start a 5/3/1 or nSuns cycle. Changes apply to new cycles only.")
                }
            }
            .navigationTitle("Settings")
            .onAppear { RestTimer.migrateDefault(settings.first) }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                initializeDefaultSettingsIfNeeded()
            }
        }
    }
    
    /// Training maxes are stored in lbs; show them in the chosen unit, to the nearest 0.1.
    private func displayValue(_ lbs: Double) -> Double {
        guard userSettings.usesKilograms else { return lbs }
        return (WeightConverter.lbsToKg(lbs) * 10).rounded() / 10
    }
    
    // MARK: - Settings Management
    private func initializeDefaultSettingsIfNeeded() {
        // Only initialize if no settings exist
        if settings.isEmpty {
            let defaultSettings = Settings.defaultSettings
            context.insert(defaultSettings)
            
            do {
                try context.save()
            } catch {
                print("Failed to save default settings: \(error)")
            }
        }
    }
    
    private func updateSetting(_ update: () -> Void) {
        // Ensure we have settings in the context
        if settings.isEmpty {
            initializeDefaultSettingsIfNeeded()
        }
        
        update()
        
        do {
            try context.save()
        } catch {
            print("Failed to save settings: \(error)")
        }
    }
    
    private func resetToDefaults() {
        let defaultSettings = Settings.defaultSettings
        userSettings.usesKilograms = defaultSettings.usesKilograms
        userSettings.enableNotifications = defaultSettings.enableNotifications
        userSettings.enableRestTimerSound = defaultSettings.enableRestTimerSound
        userSettings.defaultRestTime = defaultSettings.defaultRestTime
        userSettings.enableProgressPhotos = defaultSettings.enableProgressPhotos
        userSettings.enableCloudSync = defaultSettings.enableCloudSync
        userSettings.showTutorial = defaultSettings.showTutorial
        userSettings.benchPressMax = defaultSettings.benchPressMax
        userSettings.squatMax = defaultSettings.squatMax
        userSettings.deadliftMax = defaultSettings.deadliftMax
        userSettings.overheadPressMax = defaultSettings.overheadPressMax
        
        do {
            try context.save()
        } catch {
            print("Failed to reset settings: \(error)")
        }
    }
}

// MARK: - Training Max Row Component
struct TrainingMaxRow: View {
    let title: String
    let icon: String
    @Binding var value: Double
    let unit: String
    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.red)
                .frame(width: 20)
            Text(title)
            Spacer()
            
            TextField("0", text: $textValue)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($isFocused)
                .onAppear {
                    textValue = value == 0 ? "" : WeightConverter.format(value)
                }
                .onChange(of: textValue) { _, newValue in
                    // Only save what the user types. Filling the field with the (rounded) display
                    // value must not write back, or each lbs/kg switch nudges the stored max.
                    guard isFocused else { return }
                    if let doubleValue = Double(newValue) {
                        value = doubleValue
                    } else if newValue.isEmpty {
                        value = 0.0
                    }
                }
                .onSubmit {
                    if let doubleValue = Double(textValue) {
                        value = doubleValue
                    } else {
                        textValue = value == 0 ? "" : WeightConverter.format(value)
                    }
                }
            
            Text(unit)
                .foregroundColor(.secondary)
                .font(.caption)
                .frame(width: 25, alignment: .leading)
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Settings.self, inMemory: true)
}
