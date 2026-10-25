//
//  UpperLower.swift
//  Forge
//
//  Created by Matthew Bunce on 2025-06-10.
//
import SwiftData

@Model
class UpperLowerProgram: ProgramProtocol {
    var trainingDays: [TrainingDay]
    
    func copyTrainingDays() -> [TrainingDay] {
        return trainingDays.map { $0.copy() }
    }
    
    init() {
        // The same Upper and Lower day twice a week, so every lift comes up twice and
        // you can beat last time.
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
            )
        ]
    }
}
