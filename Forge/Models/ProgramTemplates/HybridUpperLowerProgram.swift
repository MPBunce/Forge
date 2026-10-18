//
//  HybridUpperLowerProgram.swift
//  Forge
//
//  Upper/lower lifting with running: low volume, high intensity, every working set to
//  failure. Lifting Monday, Wednesday, Friday and Sunday, with an easy run, a tempo run
//  and a long run between.
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
        // Compounds aim for 6+ reps to failure, isolation work for 10+.
        let heavy = { (sets: Int) in SetScheme.toFailure(sets, reps: 6) }
        let light = { (sets: Int) in SetScheme.toFailure(sets, reps: 10) }

        trainingDays = [
            Self.day(0, "Mon · Lower A", [
                ("Squat", heavy(2)),
                ("Leg Press", heavy(2)),
                ("Leg Extension", light(2)),
                ("Romanian Deadlift", heavy(2)),
                ("Lying Leg Curl", light(2)),
                ("Hip Thrust", heavy(2)),
                ("Hip Abduction", light(2)),
            ]),
            Self.day(1, "Tue · Easy Run", [
                ("Easy run: 30–45 min, conversational pace", SetScheme.session()),
            ]),
            Self.day(2, "Wed · Upper A", [
                ("Incline Dumbbell Press", heavy(2)),
                ("Machine Chest Press", heavy(2)),
                ("Lat Pulldown", heavy(2)),
                ("Chest-Supported Row", heavy(2)),
                ("Lateral Raise", light(3)),
                ("Incline Dumbbell Curl", light(2)),
                ("Tricep Pushdown", light(2)),
            ]),
            Self.day(3, "Thu · Tempo Run", [
                ("Tempo run: 10 min easy, 15–20 min comfortably hard, 10 min easy", SetScheme.session()),
            ]),
            Self.day(4, "Fri · Lower B", [
                ("Squat", heavy(2)),
                ("Hack Squat", heavy(2)),
                ("Leg Extension", light(2)),
                ("Seated Leg Curl", light(2)),
                ("Stiff-Leg Deadlift", heavy(2)),
                ("Bulgarian Split Squat", heavy(2)),
                ("Cable Glute Kickback", light(2)),
            ]),
            Self.day(5, "Sat · Long Run", [
                ("Long run: 60–90 min, easy pace", SetScheme.session()),
            ]),
            Self.day(6, "Sun · Upper B", [
                ("Bench Press", heavy(2)),
                ("Cable Fly", light(2)),
                ("Pull-up", heavy(2)),
                ("Seated Cable Row", heavy(2)),
                ("Shoulder Press", heavy(1)),
                ("Lateral Raise", light(2)),
                ("Hammer Curl", light(2)),
                ("Overhead Tricep Extension", light(2)),
            ]),
        ]
    }
}
