//
//  GreyskullLPProgram.swift
//  Forge
//
//  Created by Matthew Bunce on 2025-06-15.
//

import Foundation
import SwiftData

@Model
class GreyskullLPProgram: ProgramProtocol {
    var trainingDays: [TrainingDay]
    
    func copyTrainingDays() -> [TrainingDay] {
        return trainingDays.map { $0.copy() }
    }
    
    /// Greyskull LP over two weeks. The upper-body days alternate A (bench, row) and
    /// B (overhead press, pull-up), while the lower-body lift runs squat, deadlift, squat
    /// every week on its own, so each lower lift lands on both upper days over time.
    init() {
        enum Upper { case a, b }
        enum Lower { case squat, deadlift }
        let schedule: [(Upper, Lower)] = [
            (.a, .squat), (.b, .deadlift), (.a, .squat),
            (.b, .squat), (.a, .deadlift), (.b, .squat),
        ]

        self.trainingDays = schedule.enumerated().map { index, pair in
            let (upper, lower) = pair
            var exercises: [(String, [ExerciseSet])] = []
            switch upper {
            case .a:
                exercises.append(("Bench Press", SetScheme.lastSetAmrap(3, reps: 5)))
                exercises.append(("Barbell Row", SetScheme.lastSetAmrap(3, reps: 5)))
            case .b:
                exercises.append(("Overhead Press", SetScheme.lastSetAmrap(3, reps: 5)))
                exercises.append(("Weighted Pullup", SetScheme.lastSetAmrap(3, reps: 5)))
            }
            switch lower {
            case .squat:
                exercises.append(("Squat", SetScheme.lastSetAmrap(3, reps: 5)))
            case .deadlift:
                exercises.append(("Deadlift", SetScheme.lastSetAmrap(1, reps: 5)))
            }
            switch upper {
            case .a:
                exercises.append(("Bicep Curl", SetScheme.straight(3, reps: 12)))
                exercises.append(("Tricep Pushdown", SetScheme.straight(3, reps: 12)))
            case .b:
                exercises.append(("Lateral Raise", SetScheme.straight(3, reps: 15)))
                exercises.append(("Rear Delt", SetScheme.straight(3, reps: 15)))
            }
            if lower == .deadlift {
                exercises.append(("Split Squat", SetScheme.straight(3, reps: 10)))
            }
            exercises.append(("Abs", SetScheme.straight(3, reps: 15)))

            let week = index / 3 + 1, day = index % 3 + 1
            let title = "Week \(week) · Day \(day): \(exercises[0].0), \(lower == .squat ? "Squat" : "Deadlift")"
            return TrainingDay(
                dayIndex: index,
                dayName: title,
                day: exercises.enumerated().map { i, item in
                    Exercise(exerciseIndex: i, name: item.0, sets: item.1)
                },
                completedDate: nil
            )
        }
    }
}
