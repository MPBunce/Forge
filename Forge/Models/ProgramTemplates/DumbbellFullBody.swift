//
//  DumbbellFullBody.swift
//  Forge
//
//  Peter Christian-style full body for a home gym, three different workouts a week.
//  Two working sets per exercise, both to failure. Most lifts get a PR session early in
//  the week and a Mastery session on Friday; rows, flies and reverse lunges come up once
//  and are PR every time.
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
        trainingDays = [
            Self.day(0, "Mon · A · PR", [
                ("Bulgarian Split Squat", 5),
                ("Single-Leg Dumbbell Calf Raise", 6),
                ("Dumbbell Bench Press", 5),
                ("Pull-up", 5),
                ("Dumbbell Lateral Raise", 12),
                ("Dumbbell Curl", 12),
                ("Hanging Leg Raise", 8),
            ]),
            Self.day(1, "Wed · B · PR", [
                ("Single-Leg Dumbbell RDL", 5),
                ("Dumbbell Reverse Lunge", 6),
                ("Single-Leg Dumbbell Calf Raise (Mastery)", 6),
                ("One-Arm Dumbbell Row", 5),
                ("Dumbbell Fly", 12),
                ("Overhead Dumbbell Triceps Extension", 12),
                ("Hanging Leg Raise (Mastery)", 8),
            ]),
            Self.day(2, "Fri · C · Mastery", [
                ("Bulgarian Split Squat", 5),
                ("Single-Leg Dumbbell RDL", 5),
                ("Dumbbell Bench Press", 5),
                ("Pull-up", 5),
                ("Dumbbell Lateral Raise", 12),
                ("Dumbbell Curl", 12),
                ("Overhead Dumbbell Triceps Extension", 12),
            ]),
        ]
    }
}
