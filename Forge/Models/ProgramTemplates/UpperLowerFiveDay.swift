//
//  UpperLowerFiveDay.swift
//  Forge
//
//  Created by Matthew Bunce on 2025-06-15.
//

import Foundation
import SwiftData

@Model
class FiveDayUpperLowerProgram: ProgramProtocol {
    var trainingDays: [TrainingDay]
    
    func copyTrainingDays() -> [TrainingDay] {
        return trainingDays.map { $0.copy() }
    }
    
    init() {
        // Upper and Lower twice a week, plus a short arms and shoulders day.
        self.trainingDays = [
            TrainingDay(
                dayIndex: 0,
                dayName: "Upper",
                day: [
                    Exercise(exerciseIndex: 0, name: "Bench Press", sets: SetScheme.straight(4, reps: 6)),
                    Exercise(exerciseIndex: 1, name: "Barbell Rows", sets: SetScheme.straight(4, reps: 8)),
                    Exercise(exerciseIndex: 2, name: "Overhead Press", sets: SetScheme.straight(3, reps: 8)),
                    Exercise(exerciseIndex: 3, name: "Lat Pulldowns", sets: SetScheme.straight(3, reps: 10)),
                    Exercise(exerciseIndex: 4, name: "Barbell Curls", sets: SetScheme.straight(3, reps: 12)),
                    Exercise(exerciseIndex: 5, name: "Tricep Extensions", sets: SetScheme.straight(3, reps: 12))
                ],
                completedDate: nil
            ),
            TrainingDay(
                dayIndex: 1,
                dayName: "Lower",
                day: [
                    Exercise(exerciseIndex: 0, name: "Squat", sets: SetScheme.straight(4, reps: 6)),
                    Exercise(exerciseIndex: 1, name: "Romanian Deadlift", sets: SetScheme.straight(3, reps: 8)),
                    Exercise(exerciseIndex: 2, name: "Leg Press", sets: SetScheme.straight(3, reps: 10)),
                    Exercise(exerciseIndex: 3, name: "Calf Raises", sets: SetScheme.straight(4, reps: 12)),
                    Exercise(exerciseIndex: 4, name: "Abs", sets: SetScheme.straight(3, reps: 15))
                ],
                completedDate: nil
            ),
            TrainingDay(
                dayIndex: 2,
                dayName: "Upper",
                day: [
                    Exercise(exerciseIndex: 0, name: "Bench Press", sets: SetScheme.straight(4, reps: 6)),
                    Exercise(exerciseIndex: 1, name: "Barbell Rows", sets: SetScheme.straight(4, reps: 8)),
                    Exercise(exerciseIndex: 2, name: "Overhead Press", sets: SetScheme.straight(3, reps: 8)),
                    Exercise(exerciseIndex: 3, name: "Lat Pulldowns", sets: SetScheme.straight(3, reps: 10)),
                    Exercise(exerciseIndex: 4, name: "Barbell Curls", sets: SetScheme.straight(3, reps: 12)),
                    Exercise(exerciseIndex: 5, name: "Tricep Extensions", sets: SetScheme.straight(3, reps: 12))
                ],
                completedDate: nil
            ),
            TrainingDay(
                dayIndex: 3,
                dayName: "Lower",
                day: [
                    Exercise(exerciseIndex: 0, name: "Squat", sets: SetScheme.straight(4, reps: 6)),
                    Exercise(exerciseIndex: 1, name: "Romanian Deadlift", sets: SetScheme.straight(3, reps: 8)),
                    Exercise(exerciseIndex: 2, name: "Leg Press", sets: SetScheme.straight(3, reps: 10)),
                    Exercise(exerciseIndex: 3, name: "Calf Raises", sets: SetScheme.straight(4, reps: 12)),
                    Exercise(exerciseIndex: 4, name: "Abs", sets: SetScheme.straight(3, reps: 15))
                ],
                completedDate: nil
            ),
            TrainingDay(
                dayIndex: 4,
                dayName: "Arms & Shoulders",
                day: [
                    Exercise(exerciseIndex: 0, name: "Lateral Raises", sets: SetScheme.straight(3, reps: 15)),
                    Exercise(exerciseIndex: 1, name: "EZ Bar Curls", sets: SetScheme.straight(3, reps: 12)),
                    Exercise(exerciseIndex: 2, name: "Tricep Extensions", sets: SetScheme.straight(3, reps: 12)),
                    Exercise(exerciseIndex: 3, name: "Face Pulls", sets: SetScheme.straight(3, reps: 15))
                ],
                completedDate: nil
            )
        ]
    }
}
