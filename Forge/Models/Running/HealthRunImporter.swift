//
//  HealthRunImporter.swift
//  Forge
//
//  Brings running workouts from Apple Health (Apple Watch, Strava, Nike Run Club...) into
//  Forge as logged runs, so they count on the Ran grid and towards distance badges.
//

import Foundation
import HealthKit
import SwiftData

@MainActor
enum HealthRunImporter {
    /// How far back the first import looks.
    static let firstImportDays = 90

    private static let store = HKHealthStore()
    private static let lastImportKey = "healthRunsLastImport"
    private static let importedKey = "healthRunsImported"

    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: PreferenceKeys.importHealthRuns)
    }

    /// Asks for access to workouts (iOS shows the prompt once).
    static func requestAccess() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        do {
            try await store.requestAuthorization(toShare: [], read: [HKObjectType.workoutType(),
                                                                    HKQuantityType(.distanceWalkingRunning)])
            return true
        } catch {
            return false
        }
    }

    /// Adds runs finished since the last import. Returns how many were added.
    @discardableResult
    static func importNewRuns(into context: ModelContext) async -> Int {
        #if DEBUG
        if DemoData.isEnabled { return 0 }
        #endif
        guard isEnabled, await requestAccess() else { return 0 }

        let defaults = UserDefaults.standard
        let since = (defaults.object(forKey: lastImportKey) as? Date)
            ?? Calendar.current.date(byAdding: .day, value: -firstImportDays, to: Date())!
        let started = Date()
        guard let workouts = try? await runs(since: since.addingTimeInterval(-3600)) else { return 0 }

        // Skip runs already imported here, or imported on another device and synced over iCloud.
        var imported = Set(defaults.stringArray(forKey: importedKey) ?? [])
        let existing = (try? context.fetch(FetchDescriptor<LoggedRun>())) ?? []
        imported.formUnion(existing.compactMap(\.healthID))

        var added = 0
        for workout in workouts where !imported.contains(workout.uuid.uuidString) {
            let metres = workout.statistics(for: HKQuantityType(.distanceWalkingRunning))?
                .sumQuantity()?.doubleValue(for: .meter())
                ?? workout.totalDistance?.doubleValue(for: .meter()) ?? 0
            guard metres >= 200 else { continue }
            let run = LoggedRun(date: workout.startDate, kilometres: (metres / 10).rounded() / 100,
                                seconds: Int(workout.duration.rounded()))
            run.healthID = workout.uuid.uuidString
            context.insert(run)
            imported.insert(workout.uuid.uuidString)
            added += 1
        }
        defaults.set(Array(imported), forKey: importedKey)
        defaults.set(started, forKey: lastImportKey)
        return added
    }

    private static func runs(since start: Date) async throws -> [HKWorkout] {
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            HKQuery.predicateForWorkouts(with: .running),
            HKQuery.predicateForSamples(withStart: start, end: nil),
        ])
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.workout(predicate)],
            sortDescriptors: [SortDescriptor(\.startDate)]
        )
        return try await descriptor.result(for: store)
    }
}
