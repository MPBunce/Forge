//
//  Settings.swift
//  Forge
//
//  Created by Matthew Bunce on 2025-05-31.
//

import SwiftUI
import SwiftData

extension EnvironmentValues {
    /// Unit label ("lbs" or "kg") for the weights currently on screen.
    @Entry var weightUnit: String = "lbs"
    /// How much one tap of + or − changes a weight: a pair of the smallest plates.
    @Entry var weightStep: Double = 5
    /// Where + starts from when a set has no weight yet (the last weight used, or the bar).
    @Entry var weightStart: Double = 45
    /// Forge Plus: rest between sets, in seconds.
    @Entry var restSeconds: Int = 120
    /// The empty bar and smallest plate, in the weights' unit, for the plate calculator.
    @Entry var barWeight: Double = 45
    @Entry var smallestPlate: Double = 2.5
}

// MARK: - Plate rounding

/// Rounds calculated working weights to what can actually be loaded:
/// down to the nearest pair of the smallest plates, and never below the empty bar.
struct WeightRounding {
    let increment: Double
    let barbell: Double

    init(smallestPlate: Double, barbell: Double) {
        self.increment = max(smallestPlate * 2, 0.01)
        self.barbell = barbell
    }

    func round(_ weight: Double) -> Double {
        // Small epsilon so 85.0000001% style float noise doesn't drop a whole jump.
        let loadable = floor((weight + 1e-6) / increment) * increment
        return max(barbell, (loadable * 100).rounded() / 100)
    }

    static let plateOptionsLbs: [Double] = [1.25, 2.5, 5]
    static let plateOptionsKg: [Double] = [0.5, 1.25, 2.5]
    static let barbellOptionsLbs: [Double] = [25, 35, 45, 55]
    static let barbellOptionsKg: [Double] = [10, 15, 20, 25]
}

// MARK: - Unit Conversion Utilities
struct WeightConverter {
    static func lbsToKg(_ lbs: Double) -> Double {
        return lbs / 2.20462
    }
    
    static func kgToLbs(_ kg: Double) -> Double {
        return kg * 2.20462
    }
    
    /// "65" rather than "65.0", keeping real fractions like "67.5" and "1.25".
    static func format(_ weight: Double) -> String {
        weight.formatted(.number.precision(.fractionLength(0...2)).grouping(.never))
    }

    static func roundToAppropriateIncrement(_ weight: Double, isKilograms: Bool) -> Double {
        if isKilograms {
            // Round to nearest 2.5kg
            return round(weight / 2.5) * 2.5
        } else {
            // Round down to nearest 5lbs
            return floor(weight / 5.0) * 5.0
        }
    }
}

@Model
class Settings {
    var usesKilograms: Bool = false
    var enableNotifications: Bool = true
    var enableRestTimerSound: Bool = true
    var defaultRestTime: Int = 120 // in seconds
    var enableProgressPhotos: Bool = false
    var enableCloudSync: Bool = true
    var showTutorial: Bool = true
    var dailyStepGoal: Int = 10000

    // Equipment, kept per unit so switching lbs/kg keeps sensible values.
    /// Smallest plate the lifter owns (one plate, loaded on each side).
    var smallestPlateLbs: Double = 2.5
    var smallestPlateKg: Double = 1.25
    var barbellLbs: Double = 45
    var barbellKg: Double = 20
    
    // Training Maxes - Always stored in pounds for consistency
    var benchPressMax: Double = 0
    var squatMax: Double = 0
    var deadliftMax: Double = 0
    var overheadPressMax: Double = 0
    
    init(
        usesKilograms: Bool = false,
        enableNotifications: Bool = true,
        enableRestTimerSound: Bool = true,
        defaultRestTime: Int = 120,
        enableProgressPhotos: Bool = false,
        enableCloudSync: Bool = true,
        showTutorial: Bool = true,
        benchPressMax: Double = 0.0,
        squatMax: Double = 0.0,
        deadliftMax: Double = 0.0,
        overheadPressMax: Double = 0.0
    ) {
        self.usesKilograms = usesKilograms
        self.enableNotifications = enableNotifications
        self.enableRestTimerSound = enableRestTimerSound
        self.defaultRestTime = defaultRestTime
        self.enableProgressPhotos = enableProgressPhotos
        self.enableCloudSync = enableCloudSync
        self.showTutorial = showTutorial
        self.benchPressMax = benchPressMax
        self.squatMax = squatMax
        self.deadliftMax = deadliftMax
        self.overheadPressMax = overheadPressMax
    }
}

extension Settings {
    static var defaultSettings: Settings {
        return Settings(
            usesKilograms: false,
            enableNotifications: true,
            enableRestTimerSound: true,
            defaultRestTime: 90,
            enableProgressPhotos: false,
            enableCloudSync: true,
            showTutorial: true,
            benchPressMax: 100.0,  // Stored in lbs
            squatMax: 135.0,       // Stored in lbs
            deadliftMax: 135.0,    // Stored in lbs
            overheadPressMax: 100.0 // Stored in lbs
        )
    }
    
    // MARK: - Unit Conversion Methods
    
    /// Convert a training max from stored lbs to display units
    func convertedTrainingMax(_ max: Double) -> Double {
        if usesKilograms {
            return WeightConverter.roundToAppropriateIncrement(
                WeightConverter.lbsToKg(max),
                isKilograms: true
            )
        }
        return WeightConverter.roundToAppropriateIncrement(max, isKilograms: false)
    }
    
    /// Get a formatted string for display of training max
    func displayTrainingMaxString(_ max: Double) -> String {
        let convertedMax = convertedTrainingMax(max)
        let unit = usesKilograms ? "kg" : "lbs"
        
        if usesKilograms && convertedMax.truncatingRemainder(dividingBy: 1) != 0 {
            return String(format: "%.1f %@", convertedMax, unit)
        } else {
            return String(format: "%.0f %@", convertedMax, unit)
        }
    }
    
    /// Convert user input back to lbs for storage
    func convertInputToStorageUnit(_ inputValue: Double) -> Double {
        if usesKilograms {
            return WeightConverter.kgToLbs(inputValue)
        }
        return inputValue
    }
    
    // MARK: - Convenience Properties for Display
    
    var displayBenchPressMax: Double {
        convertedTrainingMax(benchPressMax)
    }
    
    var displaySquatMax: Double {
        convertedTrainingMax(squatMax)
    }
    
    var displayDeadliftMax: Double {
        convertedTrainingMax(deadliftMax)
    }
    
    var displayOverheadPressMax: Double {
        convertedTrainingMax(overheadPressMax)
    }
    
    // MARK: - Formatted String Properties
    
    var benchPressMaxString: String {
        displayTrainingMaxString(benchPressMax)
    }
    
    var squatMaxString: String {
        displayTrainingMaxString(squatMax)
    }
    
    var deadliftMaxString: String {
        displayTrainingMaxString(deadliftMax)
    }
    
    var overheadPressMaxString: String {
        displayTrainingMaxString(overheadPressMax)
    }
    
    /// Rounding for the unit currently in use.
    var weightRounding: WeightRounding {
        usesKilograms
            ? WeightRounding(smallestPlate: smallestPlateKg, barbell: barbellKg)
            : WeightRounding(smallestPlate: smallestPlateLbs, barbell: barbellLbs)
    }

    var weightUnitString: String {
        usesKilograms ? "kg" : "lbs"
    }
    
    // MARK: - Update Methods
    
    /// Update bench press max from user input
    func updateBenchPressMax(from inputValue: Double) {
        benchPressMax = convertInputToStorageUnit(inputValue)
    }
    
    /// Update squat max from user input
    func updateSquatMax(from inputValue: Double) {
        squatMax = convertInputToStorageUnit(inputValue)
    }
    
    /// Update deadlift max from user input
    func updateDeadliftMax(from inputValue: Double) {
        deadliftMax = convertInputToStorageUnit(inputValue)
    }
    
    /// Update overhead press max from user input
    func updateOverheadPressMax(from inputValue: Double) {
        overheadPressMax = convertInputToStorageUnit(inputValue)
    }
}
