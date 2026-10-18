//
//  SetSchemes.swift
//  Forge
//
//  Default set prescriptions for templates that don't calculate weights from
//  training maxes. Weights are left blank (and editable) for the lifter to fill in.
//

import Foundation

enum SetScheme {
    /// `count` sets of `reps` (nil for timed holds like planks, logged by the lifter).
    static func straight(_ count: Int, reps: Int?) -> [ExerciseSet] {
        (0..<count).map { ExerciseSet(setIndex: $0, reps: reps, isEditable: true) }
    }

    /// `count` sets of `reps`, the last taken to as many reps as possible (e.g. Greyskull's 2x5, 1x5+).
    static func lastSetAmrap(_ count: Int, reps: Int) -> [ExerciseSet] {
        (0..<count).map { index in
            let isAmrap = index == count - 1
            return ExerciseSet(
                setIndex: index,
                reps: reps,
                isEditable: true,
                isAmrap: isAmrap,
                amrapTargetReps: isAmrap ? reps : nil
            )
        }
    }

    /// `count` working sets, each taken to failure; `reps` is the target to beat.
    static func toFailure(_ count: Int, reps: Int) -> [ExerciseSet] {
        (0..<count).map { index in
            ExerciseSet(setIndex: index, reps: reps, isEditable: true, isAmrap: true, amrapTargetReps: reps)
        }
    }

    /// A single tick-off item, like a run, with no reps or weight to log.
    static func session() -> [ExerciseSet] {
        [ExerciseSet(setIndex: 0, reps: nil, isEditable: true)]
    }
}
