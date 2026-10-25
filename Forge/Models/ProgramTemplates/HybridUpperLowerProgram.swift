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

        // One lower and one upper day, each done twice a week with the same five lifts,
        // so each one comes up twice and you can beat last time.
        // Lower: quad, hamstring, glute, abs, calves. Upper: push, pull, laterals, biceps, triceps.
        // Functions, so each day gets its own sets rather than sharing them.
        let lower = { () -> [(String, [ExerciseSet])] in [
            ("Squat", heavy(4)),
            ("Romanian Deadlift", heavy(4)),
            ("Hip Thrust", heavy(4)),
            ("Hanging Leg Raise", light(3)),
            ("Standing Calf Raise", light(3)),
        ] }
        let upper = { () -> [(String, [ExerciseSet])] in [
            ("Incline Dumbbell Press", heavy(4)),
            ("Lat Pulldown", heavy(4)),
            ("Lateral Raise", light(3)),
            ("Incline Dumbbell Curl", light(2)),
            ("Tricep Pushdown", light(2)),
        ] }
        trainingDays = [
            Self.day(0, "Mon · Lower", lower()),
            Self.day(1, "Wed · Upper", upper()),
            Self.day(2, "Fri · Lower", lower()),
            Self.day(3, "Sun · Upper", upper()),
        ]
    }
}
