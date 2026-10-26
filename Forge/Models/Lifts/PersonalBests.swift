//
//  PersonalBests.swift
//  Forge
//
//  Personal bests for lifts: the heaviest set for a lift across every cycle, compared by
//  estimated one-rep max so 225 × 5 beats 235 × 1. Names are matched loosely, so
//  "Barbell Rows" and "Barbell Row" count as the same lift.
//

import Foundation
import SwiftData

enum PersonalBests {
    struct Best: Equatable {
        /// Estimated one-rep max, in pounds.
        var estimatedMax: Double
        /// The set itself, in the unit it was logged in.
        var weight: Double
        var reps: Int
        var usesKilograms: Bool
        var date: Date?
    }

    /// Epley's formula. Past 12 reps it overestimates, so those count as 12.
    static func estimatedMax(weight: Double, reps: Int) -> Double {
        reps <= 1 ? weight : weight * (1 + Double(min(reps, 12)) / 30)
    }

    /// "Pull-ups (BBB)" and "Pull Ups" both become "pullup".
    static func key(_ name: String) -> String {
        let base = ExerciseSwaps.split(name).base.lowercased()
        let words = base.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map { word -> String in
            var w = String(word)
            if w.count > 3, w.hasSuffix("s"), !w.hasSuffix("ss") { w.removeLast() }
            return w
        }
        return words.joined()
    }

    private static func pounds(_ weight: Double, kilograms: Bool) -> Double {
        kilograms ? WeightConverter.kgToLbs(weight) : weight
    }

    /// The best successful set for a lift, leaving out `excluding` (the sets being logged now).
    static func best(for name: String, in cycles: [Cycles], excluding: Set<PersistentIdentifier> = []) -> Best? {
        let lift = key(name)
        var best: Best?
        for cycle in cycles {
            for day in cycle.trainingDays {
                for exercise in day.day where key(exercise.name) == lift {
                    for set in exercise.sets where !excluding.contains(set.persistentModelID) {
                        guard set.completionStatus == .completedSuccessfully,
                              let weight = set.weight, weight > 0, let reps = set.reps, reps > 0 else { continue }
                        let max = estimatedMax(weight: pounds(weight, kilograms: cycle.usesKilograms), reps: reps)
                        if max > (best?.estimatedMax ?? 0) {
                            best = Best(estimatedMax: max, weight: weight, reps: reps,
                                        usesKilograms: cycle.usesKilograms, date: day.completedDate)
                        }
                    }
                }
            }
        }
        return best
    }

    /// The set that beats `previous`, if any of these does. A lift's first ever session
    /// sets the bar rather than counting as a PB.
    static func newBest(among sets: [ExerciseSet], usesKilograms: Bool, previous: Best?) -> ExerciseSet? {
        guard let previous else { return nil }
        let scored = sets.compactMap { set -> (ExerciseSet, Double)? in
            guard set.completionStatus == .completedSuccessfully,
                  let weight = set.weight, weight > 0, let reps = set.reps, reps > 0 else { return nil }
            return (set, estimatedMax(weight: pounds(weight, kilograms: usesKilograms), reps: reps))
        }
        guard let top = scored.max(by: { $0.1 < $1.1 }), top.1 > previous.estimatedMax + 0.01 else { return nil }
        return top.0
    }
}
