//
//  Preferences.swift
//  Forge
//
//  Small per-device display preferences kept in UserDefaults.
//

import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: Self { self }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    /// nil follows the device setting.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum PreferenceKeys {
    static let appearance = "appearance"
    /// Lifts shown on the Progress charts, stored as newline-separated names.
    static let trackedLifts = "trackedLifts"
    /// Stretching routines shown on the Today tab, stored as newline-separated IDs.
    static let stretchRoutines = "stretchRoutines"
    /// Set once the launch quote has been shown, so it only appears on first launch.
    static let hasSeenSplash = "hasSeenSplash"
    /// Import running workouts from Apple Health.
    static let importHealthRuns = "importHealthRuns"
    /// Forge Plus: start a rest timer after each set.
    static let restTimerEnabled = "restTimerEnabled"
    static let showPlates = "showPlates"
}

/// A lift that can be charted, plus the exercise names in the app's templates that count as it.
struct TrackableLift: Hashable {
    let name: String
    let aliases: [String]

    init(_ name: String, aliases: [String] = []) {
        self.name = name
        self.aliases = aliases
    }

    func matches(_ exerciseName: String) -> Bool {
        ([name] + aliases).contains { $0.caseInsensitiveCompare(exerciseName) == .orderedSame }
    }
}

enum TrackedLifts {
    /// The lifts in the Exercise Index (Chapter Seven) of The Greyskull LP, in book order.
    static let catalog: [TrackableLift] = [
        TrackableLift("Squat", aliases: ["Squat (BBB)"]),
        TrackableLift("Deadlift", aliases: ["Deadlift (BBB)"]),
        TrackableLift("Sumo Deadlift"),
        TrackableLift("Rack Pull"),
        TrackableLift("Bench Press", aliases: ["Bench Press (BBB)"]),
        TrackableLift("Overhead Press", aliases: ["Press", "Overhead Press (BBB)"]),
        TrackableLift("Incline Bench Press"),
        TrackableLift("Close Grip Bench Press"),
        TrackableLift("Decline Bench Press"),
        TrackableLift("Front Squat"),
        TrackableLift("Deficit Deadlift"),
        TrackableLift("Trap Bar Deadlift"),
        TrackableLift("Power Snatch"),
        TrackableLift("Weighted Chin-up", aliases: ["Weighted Chin-ups", "Weighted Pullup", "Weighted Pull Ups", "Weighted Pull-ups"]),
        TrackableLift("Yates Row", aliases: ["Barbell Row", "Barbell Rows"]),
        TrackableLift("V-Handle Pull-down"),
        TrackableLift("Dumbbell Row", aliases: ["Dumbbell Rows"]),
        TrackableLift("EZ Bar Curl", aliases: ["EZ Bar Curls", "Standing EZ Curl Bar Curl"]),
        TrackableLift("Seated Alternating Dumbbell Curl"),
        TrackableLift("EZ Bar Drag Curl", aliases: ["Drag Curl"]),
        TrackableLift("Neck Extension")
    ]

    static let defaults = ["Squat", "Bench Press", "Deadlift", "Overhead Press"]
    static let defaultStorage = defaults.joined(separator: "\n")

    static func lift(named name: String) -> TrackableLift? {
        catalog.first { $0.name == name }
    }

    /// Drops anything no longer in the catalog (e.g. lifts picked before it was limited).
    static func decode(_ stored: String) -> [String] {
        stored.split(separator: "\n").map(String.init).filter { lift(named: $0) != nil }
    }

    static func encode(_ lifts: [String]) -> String {
        lifts.joined(separator: "\n")
    }
}
