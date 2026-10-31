//
//  DumbbellFullBody.swift
//  Forge
//
//  Full body for a home gym, three different workouts a week. Two working sets per
//  exercise, both to failure.
//

import Foundation

final class DumbbellFullBodyProgram: ProgramProtocol {
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

    init() {
        // Upper body first while you're fresh, then legs, then abs. Monday and Friday are
        // a push, a pull, triceps then biceps; Wednesday is dips, pull-ups and laterals
        // with four lower-body lifts.
        trainingDays = [
            Self.day(0, "Mon · A", [
                ("Dumbbell Bench Press", 5),
                ("Pull-up", 5),
                ("Overhead Dumbbell Triceps Extension", 12),
                ("Dumbbell Curl", 12),
                ("Bulgarian Split Squat", 5),
                ("Single-Leg Dumbbell Calf Raise", 6),
                ("Hanging Leg Raise", 8),
            ]),
            Self.day(1, "Wed · B", [
                ("Dips", 5),
                ("Pull-up", 5),
                ("Dumbbell Lateral Raise", 12),
                ("Single-Leg Dumbbell RDL", 5),
                ("Dumbbell Reverse Lunge", 6),
                ("Single-Leg Dumbbell Calf Raise", 6),
                ("Hanging Leg Raise", 8),
            ]),
            Self.day(2, "Fri · C", [
                ("Dumbbell Bench Press", 5),
                ("One-Arm Dumbbell Row", 5),
                ("Overhead Dumbbell Triceps Extension", 12),
                ("Dumbbell Curl", 12),
                ("Bulgarian Split Squat", 5),
                ("Single-Leg Dumbbell RDL", 5),
            ]),
        ]
    }
}
