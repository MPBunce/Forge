//
//  Progression.swift
//  Forge
//
//  Double progression: sets have a rep range (5–8). Once every set reaches the top of it,
//  the weight goes up next time and the reps start again from the bottom. Programs that
//  work from training maxes (5/3/1, nSuns) or add weight every session (Greyskull) have
//  their own rules, so they're left alone.
//

import Foundation

enum Progression {
    /// Whether a cycle's program progresses by working through a rep range.
    static func usesRepRanges(_ cycle: Cycles) -> Bool {
        guard let template = Template.named(cycle.template) else { return true }   // custom templates
        return !template.programType.usesTrainingMaxes && template.programType != .greySkull
    }

    /// The top of the range for a target: 5 → 8, 8 → 12, 12 → 20.
    static func top(forTarget target: Int) -> Int {
        if target < 8 { return target + 3 }
        if target < 12 { return target + 4 }
        return target + 8
    }

    /// "5–8"
    static func rangeText(forTarget target: Int) -> String {
        "\(target)–\(top(forTarget: target))"
    }

    /// Every ranged set done, each at the top of its range.
    static func earnedIncrease(_ sets: [ExerciseSet]) -> Bool {
        let ranged = sets.filter { $0.isAmrap && $0.amrapTargetReps != nil }
        guard !ranged.isEmpty else { return false }
        return ranged.allSatisfy { set in
            set.completionStatus == .completedSuccessfully && (set.reps ?? 0) >= top(forTarget: set.amrapTargetReps ?? 0)
        }
    }
}

/// Forge Plus: lighter sets that build up to the working weight, about 40%, 60% and 80%
/// of it, plus the empty bar for barbell lifts.
enum WarmUp {
    struct Step: Equatable {
        let weight: Double
        let reps: Int
    }

    static func steps(to working: Double, bar: Double, smallest: Double, isBarbell: Bool) -> [Step] {
        let increment = max(smallest * 2, 0.5)
        let floor = isBarbell ? bar : increment
        // Too light to need a ramp.
        guard working >= (isBarbell ? bar * 1.5 : increment * 4) else { return [] }
        var steps: [Step] = isBarbell ? [Step(weight: bar, reps: 5)] : []
        for (share, reps) in [(0.4, 5), (0.6, 3), (0.8, 2)] {
            let raw = working * share
            let rounded = max(floor, (raw / increment).rounded(.down) * increment)
            let previous = steps.last?.weight ?? 0
            guard (rounded < working) && (rounded > previous) else { continue }
            steps.append(Step(weight: rounded, reps: reps))
        }
        return steps
    }

    /// Dumbbell, cable and machine work doesn't start from an empty bar.
    static func isBarbell(_ name: String) -> Bool {
        let lower = name.lowercased()
        return !["dumbbell", "db ", "cable", "machine", "pulldown", "leg press", "kettlebell", "goblet"]
            .contains { lower.contains($0) }
    }
}

/// Forge Plus: a note on a lift, shown each time it comes up ("Seat at 4", "Left shoulder: go light").
enum ExerciseNotes {
    private static let key = "exerciseNotes"

    static func note(for name: String) -> String? {
        let all = UserDefaults.standard.dictionary(forKey: key) as? [String: String] ?? [:]
        return all[PersonalBests.key(name)].flatMap { $0.isEmpty ? nil : $0 }
    }

    static func setNote(_ text: String, for name: String) {
        var all = UserDefaults.standard.dictionary(forKey: key) as? [String: String] ?? [:]
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        all[PersonalBests.key(name)] = trimmed.isEmpty ? nil : trimmed
        UserDefaults.standard.set(all, forKey: key)
    }
}
