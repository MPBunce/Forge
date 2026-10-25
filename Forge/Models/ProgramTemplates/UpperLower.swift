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
        // The same accessories every upper and every lower day, so they can be progressed;
        // the main lift alternates (bench and overhead press, squat and deadlift) so both
        // get trained heavy each week. The deadlift day uses leg curls instead of RDLs, so
        // the hinge isn't doubled up.
        self.trainingDays = [
            TrainingDay(
                dayIndex: 0,
                dayName: "Upper · Bench",
                day: [
                    Exercise(exerciseIndex: 0, name: "Bench Press", sets: SetScheme.straight(4, reps: 6)),
                    Exercise(exerciseIndex: 1, name: "Barbell Rows", sets: SetScheme.straight(4, reps: 8)),
                    Exercise(exerciseIndex: 2, name: "Lat Pulldowns", sets: SetScheme.straight(3, reps: 10)),
                    Exercise(exerciseIndex: 3, name: "Barbell Curls", sets: SetScheme.straight(3, reps: 12)),
                    Exercise(exerciseIndex: 4, name: "Tricep Extensions", sets: SetScheme.straight(3, reps: 12))
                ],
                completedDate: nil
            ),
            TrainingDay(
                dayIndex: 1,
                dayName: "Lower · Squat",
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
                dayName: "Upper · Press",
                day: [
                    Exercise(exerciseIndex: 0, name: "Overhead Press", sets: SetScheme.straight(4, reps: 6)),
                    Exercise(exerciseIndex: 1, name: "Barbell Rows", sets: SetScheme.straight(4, reps: 8)),
                    Exercise(exerciseIndex: 2, name: "Lat Pulldowns", sets: SetScheme.straight(3, reps: 10)),
                    Exercise(exerciseIndex: 3, name: "Barbell Curls", sets: SetScheme.straight(3, reps: 12)),
                    Exercise(exerciseIndex: 4, name: "Tricep Extensions", sets: SetScheme.straight(3, reps: 12))
                ],
                completedDate: nil
            ),
            TrainingDay(
                dayIndex: 3,
                dayName: "Lower · Deadlift",
                day: [
                    Exercise(exerciseIndex: 0, name: "Deadlift", sets: SetScheme.straight(3, reps: 5)),
                    Exercise(exerciseIndex: 1, name: "Leg Press", sets: SetScheme.straight(3, reps: 10)),
                    Exercise(exerciseIndex: 2, name: "Leg Curls", sets: SetScheme.straight(3, reps: 12)),
                    Exercise(exerciseIndex: 3, name: "Calf Raises", sets: SetScheme.straight(4, reps: 12)),
                    Exercise(exerciseIndex: 4, name: "Abs", sets: SetScheme.straight(3, reps: 15))
                ],
                completedDate: nil
            )
        ]
    }
}
