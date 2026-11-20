//
//  LastWeight.swift
//  Forge
//
//  The weight last logged for a lift, from any cycle, so a new set starts there.
//

import Foundation
import SwiftData

enum LastWeight {
    /// The last weight logged for this lift before the given exercise, newest session
    /// first. Only sets that were actually done count (programmed weights don't), and
    /// only in the same unit. Names match loosely, so "Barbell Rows" finds "Barbell Row".
    static func find(for exercise: Exercise, in cycles: [Cycles], usesKilograms: Bool) -> Double? {
        lastSession(for: exercise, in: cycles, usesKilograms: usesKilograms)?.weight
    }

    /// The most recent earlier session of this lift: its last logged weight and its sets.
    static func lastSession(for exercise: Exercise, in cycles: [Cycles], usesKilograms: Bool) -> (weight: Double, sets: [ExerciseSet], cycle: Cycles)? {
        let key = PersonalBests.key(exercise.name)
        let current = exercise.persistentModelID
        var best: (date: Date, weight: Double, sets: [ExerciseSet], cycle: Cycles)?
        for cycle in cycles where cycle.usesKilograms == usesKilograms {
            for day in cycle.trainingDays {
                // Days without a date are ordered within their cycle by position.
                let date = day.completedDate ?? cycle.startDate.addingTimeInterval(Double(day.dayIndex))
                if let best, date <= best.date { continue }
                for other in day.day where other.persistentModelID != current && PersonalBests.key(other.name) == key {
                    let done = other.orderedSets.filter { $0.completionStatus != .notStarted && $0.weight != nil }
                    if let weight = done.last?.weight {
                        best = (date, weight, other.orderedSets, cycle)
                    }
                }
            }
        }
        return best.map { ($0.weight, $0.sets, $0.cycle) }
    }
}
