//
//  DumbbellUpperLower.swift
//  Forge
//
//  Upper/lower for a home gym (pull-up bar, flat bench, adjustable dumbbells). Two working
//  sets per exercise, both to failure; every muscle twice a week; lower days are all
//  single-leg work.
//

import Foundation

final class DumbbellUpperLowerProgram: ProgramProtocol {
    let trainingDays: [TrainingDay]

    func copyTrainingDays() -> [TrainingDay] {
        trainingDays.map { $0.copy() }
    }

    /// Every working set goes to failure; the target is the bottom of the rep range.
    private static func day(_ index: Int, _ name: String, _ exercises: [(String, Int)]) -> TrainingDay {
        TrainingDay(
            dayIndex: index,
            dayName: name,
            day: exercises.enumerated().map { i, item in
                Exercise(exerciseIndex: i, name: item.0, sets: SetScheme.toFailure(2, reps: item.1))
            },
            completedDate: nil
        )
    }

    /// Main lifts 5–8 reps, accessories 12–20.
    static let upper: [(String, Int)] = [
        ("Dumbbell Bench Press", 5),
        ("Pull-up", 5),
        ("Dumbbell Fly", 12),
        ("Dumbbell Lateral Raise", 12),
        ("Dumbbell Curl", 12),
        ("Overhead Dumbbell Triceps Extension", 12),
    ]

    /// Per leg, except the leg raises.
    static let lower: [(String, Int)] = [
        ("Bulgarian Split Squat", 5),
        ("Single-Leg Dumbbell RDL", 5),
        ("Dumbbell Reverse Lunge", 6),
        ("Single-Leg Dumbbell Calf Raise", 6),
        ("Hanging Leg Raise", 8),
    ]

    init() {
        trainingDays = [
            Self.day(0, "Mon · Upper", Self.upper),
            Self.day(1, "Tue · Lower", Self.lower),
            Self.day(2, "Thu · Upper", Self.upper),
            Self.day(3, "Fri · Lower", Self.lower),
        ]
    }
}
