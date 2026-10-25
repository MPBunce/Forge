//
//  DumbbellUpperLower.swift
//  Forge
//
//  Upper and lower twice a week with nothing but dumbbells, for home or a busy gym.
//  Every lower day is the same, and so is every upper day (a push, a pull, shoulders,
//  then arms), so each lift comes up twice a week and is easy to progress.
//

import Foundation

final class DumbbellUpperLowerProgram: ProgramProtocol {
    let trainingDays: [TrainingDay]

    func copyTrainingDays() -> [TrainingDay] {
        trainingDays.map { $0.copy() }
    }

    private static func day(_ index: Int, _ name: String, _ exercises: [(String, Int, Int)]) -> TrainingDay {
        TrainingDay(
            dayIndex: index,
            dayName: name,
            day: exercises.enumerated().map { i, item in
                Exercise(exerciseIndex: i, name: item.0, sets: SetScheme.straight(item.1, reps: item.2))
            },
            completedDate: nil
        )
    }

    init() {
        let lower = [
            ("Dumbbell Split Squat", 3, 10),
            ("Dumbbell RDL", 3, 10),
            ("Dumbbell Calf Raise", 3, 15),
            ("Abs", 3, 15),
        ]
        let upper = [
            ("Dumbbell Bench Press", 4, 10),
            ("One-Arm Dumbbell Row", 4, 10),
            ("Dumbbell Shoulder Press", 3, 10),
            ("Lateral Raises", 3, 15),
            ("Dumbbell Curls", 3, 12),
            ("Overhead Tricep Extension", 3, 12),
        ]
        trainingDays = [
            Self.day(0, "Upper", upper),
            Self.day(1, "Lower", lower),
            Self.day(2, "Upper", upper),
            Self.day(3, "Lower", lower),
        ]
    }
}
