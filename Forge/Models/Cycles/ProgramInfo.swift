//
//  ProgramInfo.swift
//  Forge
//
//  A short explanation of each built-in program: how often you train and how it works.
//

import Foundation

extension ProgramType {
    /// How often you train, for the program list.
    var frequency: String {
        switch self {
        case .fiveThreeOneBasicProgram, .fiveThreeOneBBBProgram: "4 days a week · 4-week cycles"
        case .greySkull: "3 days a week · full body"
        case .arnoldProgram: "6 days a week · each muscle twice"
        case .menzer: "Every 4–7 days · one hard set"
        case .nSuns4Days: "4 days a week"
        case .nSuns5Days: "5 days a week"
        case .nSuns6DaysSquat, .nSuns6DaysDeadlift: "6 days a week"
        case .pushPullLegs: "3 or 6 days a week"
        case .upperLowerFourDay: "4 days a week"
        case .upperLowerFiveDay: "5 days a week"
        }
    }

    /// What the program is and how to run it.
    var about: String {
        switch self {
        case .fiveThreeOneBasicProgram:
            "Jim Wendler's 5/3/1. One main lift a day (press, deadlift, bench, squat), worked up to a top set you push for as many reps as you can. Weeks run 5s, 3s, then 5/3/1, with a lighter deload in week 4. Raise your training maxes after each cycle: 5 lb for upper body, 10 lb for lower."
        case .fiveThreeOneBBBProgram:
            "5/3/1 with Boring But Big: the same main-lift sets, followed by 5 sets of 10 at a lighter weight to build size. Four days a week over 4-week cycles, with a deload in week 4. Raise your training maxes after each cycle."
        case .greySkull:
            "John Sheaffer's Greyskull LP, a beginner linear progression. Three full-body days a week. Upper-body days alternate bench and row with overhead press and pull-ups, while the lower-body lift runs squat, deadlift, squat each week. Main lifts are 2 sets of 5 and a last set of as many reps as you can (deadlift is one set); add weight each session, and reset by 10% if you stall."
        case .arnoldProgram:
            "Arnold Schwarzenegger's classic split: chest and back, shoulders and arms, then legs, run twice through the week with Sunday off. High volume with lots of sets per muscle, so it suits lifters with some experience and time to recover."
        case .menzer:
            "Mike Mentzer's Heavy Duty: very few sets, each taken all the way to failure, with long rest between workouts. Train every 4 to 7 days and only add weight or reps when you've fully recovered."
        case .nSuns4Days:
            "nSuns, a high-volume progression built on 5/3/1. Each day pairs a main lift with a secondary lift, with 8 or 9 sets each and an as-many-reps-as-you-can set that decides next week's training max. Four days: bench, squat, press and deadlift."
        case .nSuns5Days:
            "nSuns over five days, adding a second bench day. Each day pairs a main lift with a secondary lift; your as-many-reps-as-you-can set on the main lift decides how much to raise its training max next week."
        case .nSuns6DaysSquat:
            "nSuns over six days with an extra squat day, for lifters who want the most squat practice. Very high volume, so it's best for experienced lifters who recover well."
        case .nSuns6DaysDeadlift:
            "nSuns over six days with an extra deadlift day. Very high volume, so it's best for experienced lifters who recover well."
        case .pushPullLegs:
            "Push (chest, shoulders, triceps), pull (back, biceps) and legs. Run it 3 days a week for one hit per muscle, or twice through for 6 days. Add weight or reps when you hit the top of each rep range."
        case .upperLowerFourDay:
            "Alternate upper body and lower body days, training each twice a week. A balanced middle ground between strength and size; add weight when you hit the top of the rep range."
        case .upperLowerFiveDay:
            "An upper and lower split over five days with an extra upper day, for more chest, back and arm volume. Add weight when you hit the top of the rep range."
        }
    }
}
