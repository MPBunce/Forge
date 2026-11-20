//
//  RestActivity.swift
//  Shared between Forge and its widgets.
//
//  Forge Plus: the rest countdown as a Live Activity, on the Lock Screen and in the Dynamic
//  Island, with +30s and Skip. The buttons run in the app (LiveActivityIntent), which
//  hands them to the rest timer through `RestTimerBridge`.
//

import ActivityKit
import AppIntents
import Foundation

struct RestActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var startDate: Date
        var endDate: Date
    }
}

/// Set by the app's rest timer at launch; the widget extension never calls these.
enum RestTimerBridge {
    @MainActor static var add: ((TimeInterval) -> Void)?
    @MainActor static var skip: (() -> Void)?
}

struct AddRestTimeIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Add 30 Seconds"
    static let isDiscoverable = false

    init() {}

    func perform() async throws -> some IntentResult {
        await MainActor.run { RestTimerBridge.add?(30) }
        return .result()
    }
}

struct SkipRestIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Skip Rest"
    static let isDiscoverable = false

    init() {}

    func perform() async throws -> some IntentResult {
        await MainActor.run { RestTimerBridge.skip?() }
        return .result()
    }
}

/// The next lifting day, saved by the app for the Next Workout widget.
struct NextWorkoutSnapshot: Codable, Equatable {
    var program: String
    var dayName: String
    var exercises: [String]
    /// Today's day is already done; `dayName` is then the one after it, if any.
    var doneToday: Bool

    private static let key = "nextWorkout"

    static func load() -> NextWorkoutSnapshot? {
        guard let data = AppGroup.defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(NextWorkoutSnapshot.self, from: data)
    }

    /// Returns whether anything changed, so widgets only reload when they need to.
    @discardableResult
    static func save(_ snapshot: NextWorkoutSnapshot?) -> Bool {
        guard snapshot != load() else { return false }
        if let snapshot, let data = try? JSONEncoder().encode(snapshot) {
            AppGroup.defaults.set(data, forKey: key)
        } else {
            AppGroup.defaults.removeObject(forKey: key)
        }
        return true
    }
}
