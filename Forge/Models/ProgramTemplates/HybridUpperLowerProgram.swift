//
//  HybridUpperLowerProgram.swift
//  Forge
//
//  Upper/lower lifting for runners: low volume, high intensity, every working set to
//  failure. Lifting Monday, Wednesday, Friday and Sunday; the runs between are the
//  Hybrid Runs plan in Training › Running.
//

import Foundation

final class HybridUpperLowerProgram: ProgramProtocol {
    let trainingDays: [TrainingDay]

    func copyTrainingDays() -> [TrainingDay] {
        trainingDays.map { $0.copy() }
    }

    private static func day(_ index: Int, _ name: String, _ exercises: [(String, [ExerciseSet])]) -> TrainingDay {
        TrainingDay(
            dayIndex: index,
            dayName: name,
            day: exercises.enumerated().map { i, item in Exercise(exerciseIndex: i, name: item.0, sets: item.1) },
            completedDate: nil
        )
    }

    init() {
        // Compounds aim for 8+ reps to failure, accessories for 12+.
        let heavy = { (sets: Int) in SetScheme.toFailure(sets, reps: 8) }
        let light = { (sets: Int) in SetScheme.toFailure(sets, reps: 12) }

        // Five exercises a day. Lower: 2 squat, 4 quad, 4 hamstring, 4 glute.
        // Upper: 4 push, 4 pull, 3 lateral raise, 4 arms.
        trainingDays = [
            Self.day(0, "Mon · Lower A", [
                ("Squat", heavy(2)),
                ("Leg Extension", light(4)),
                ("Romanian Deadlift", heavy(2)),
                ("Lying Leg Curl", light(2)),
                ("Hip Thrust", heavy(4)),
            ]),
            Self.day(1, "Wed · Upper A", [
                ("Incline Dumbbell Press", heavy(4)),
                ("Lat Pulldown", heavy(4)),
                ("Lateral Raise", light(3)),
                ("Incline Dumbbell Curl", light(2)),
                ("Tricep Pushdown", light(2)),
            ]),
            Self.day(2, "Fri · Lower B", [
                ("Squat", heavy(2)),
                ("Leg Press", heavy(4)),
                ("Stiff-Leg Deadlift", heavy(2)),
                ("Seated Leg Curl", light(2)),
                ("Cable Glute Kickback", light(4)),
            ]),
            Self.day(3, "Sun · Upper B", [
                ("Bench Press", heavy(4)),
                ("Chest-Supported Row", heavy(4)),
                ("Lateral Raise", light(3)),
                ("Hammer Curl", light(2)),
                ("Overhead Tricep Extension", light(2)),
            ]),
        ]
    }
}
