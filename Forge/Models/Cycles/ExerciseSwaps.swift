//
//  ExerciseSwaps.swift
//  Forge
//
//  Forge Plus: swapping a program's exercises for variations when starting a cycle,
//  e.g. Squat → Front Squat. Sets, reps and weights stay as the program sets them.
//

import Foundation

enum ExerciseSwaps {
    /// Programs tag some exercises with a suffix like "Squat (BBB)". Swaps apply to the
    /// lift itself, so the suffix is kept: "Front Squat (BBB)".
    static func split(_ name: String) -> (base: String, suffix: String) {
        guard let open = name.range(of: " (", options: .backwards), name.hasSuffix(")") else {
            return (name, "")
        }
        return (String(name[..<open.lowerBound]), String(name[open.lowerBound...]))
    }

    /// Each lift in the program once, in the order it first appears.
    static func lifts(in days: [TrainingDay]) -> [String] {
        var seen = Set<String>()
        return days.sorted { $0.dayIndex < $1.dayIndex }
            .flatMap { $0.day.sorted { $0.exerciseIndex < $1.exerciseIndex } }
            .map { split($0.name).base }
            .filter { seen.insert($0).inserted }
    }

    /// Renames swapped lifts on every day, keeping any program suffix.
    static func apply(_ swaps: [String: String], to days: [TrainingDay]) {
        guard !swaps.isEmpty else { return }
        for exercise in days.flatMap(\.day) {
            let (base, suffix) = split(exercise.name)
            if let replacement = swaps[base], !replacement.isEmpty {
                exercise.name = replacement + suffix
            }
        }
    }

    /// Common variations for a lift, matched on the words in its name.
    static func alternatives(for lift: String) -> [String] {
        let name = lift.lowercased()
        let options: [String]
        switch true {
        case name.contains("front squat"):
            options = ["Back Squat", "Safety Bar Squat", "Goblet Squat", "Hack Squat"]
        case name.contains("split squat") || name.contains("lunge"):
            options = ["Bulgarian Split Squats", "Walking Lunges", "Reverse Lunges", "Step-ups", "Split Squat"]
        case name.contains("squat"):
            options = ["Front Squat", "Safety Bar Squat", "High Bar Squat", "Low Bar Squat", "Box Squat", "Pause Squat", "Hack Squat", "Leg Press"]
        case name.contains("sumo"):
            options = ["Deadlift", "Trap Bar Deadlift", "Romanian Deadlift"]
        case name.contains("rdl") || name.contains("romanian") || name.contains("stiff"):
            options = ["Romanian Deadlift", "Stiff-Leg Deadlift", "Good Mornings", "Dumbbell RDL", "Back Extensions"]
        case name.contains("deadlift"):
            options = ["Sumo Deadlift", "Trap Bar Deadlift", "Deficit Deadlift", "Block Pull", "Romanian Deadlift"]
        case name.contains("incline"):
            options = ["Incline Bench Press", "Incline Dumbbell Press", "Bench Press", "Landmine Press"]
        case name.contains("close grip"):
            options = ["Bench Press", "Dips", "JM Press", "Floor Press"]
        case name.contains("bench") || name == "dumbbell press":
            options = ["Close Grip Bench Press", "Incline Bench Press", "Dumbbell Bench Press", "Pause Bench Press", "Floor Press", "Larsen Press"]
        case name.contains("overhead press") || name.contains("ohp") || name == "press":
            options = ["Push Press", "Seated Overhead Press", "Dumbbell Shoulder Press", "Z Press", "Landmine Press"]
        case name.contains("row"):
            options = ["Barbell Rows", "Pendlay Rows", "Dumbbell Row", "Chest-Supported Row", "Seal Row", "Cable Rows", "T-Bar Rows"]
        case name.contains("pull") && (name.contains("up") || name.contains("down")) || name.contains("chin"):
            options = ["Pull-ups", "Chin Ups", "Weighted Pullup", "Lat Pulldowns", "Neutral Grip Pull-ups", "Assisted Pull-ups"]
        case name.contains("curl") && !name.contains("leg") && !name.contains("hamstring"):
            options = ["Barbell Curls", "EZ Bar Curls", "Dumbbell Curls", "Hammer Curls", "Incline Curls", "Cable Curls", "Preacher Curls"]
        case name.contains("hip thrust") || name.contains("glute"):
            options = ["Hip Thrust", "Glute Bridge", "Bulgarian Split Squats", "Cable Glute Kickback", "Hip Abduction"]
        case name.contains("leg curl") || name.contains("hamstring"):
            options = ["Leg Curls", "Seated Leg Curls", "Nordic Curls", "Glute-Ham Raises", "Romanian Deadlift"]
        case name.contains("tricep") || name.contains("push down") || name.contains("pushdown") || name.contains("skull") || name == "dips":
            options = ["Tricep Push Downs", "Overhead Tricep Extension", "Skullcrushers", "Dips", "Close Grip Bench Press"]
        case name.contains("lateral") || name.contains("front raise"):
            options = ["Lateral Raises", "Cable Lateral Raises", "Machine Lateral Raises", "Upright Rows"]
        case name.contains("rear delt") || name.contains("face pull"):
            options = ["Face Pulls", "Rear Delt Flys", "Reverse Pec Deck", "Band Pull-Aparts"]
        case name.contains("calf"):
            options = ["Calf Raises", "Seated Calf Raises", "Leg Press Calf Raises", "Single-Leg Calf Raises"]
        case name.contains("leg press") || name.contains("leg extension"):
            options = ["Leg Press", "Hack Squat", "Leg Extensions", "Goblet Squat"]
        case name.contains("abs") || name.contains("plank") || name.contains("raise") || name.contains("crunch"):
            options = ["Hanging Leg Raises", "Hanging Knee Raises", "Ab Wheel", "Cable Crunches", "Plank"]
        case name.contains("shrug"):
            options = ["Dumbbell Shrugs", "Barbell Shrugs", "Farmer's Carry"]
        default:
            options = []
        }
        return options.filter { $0.caseInsensitiveCompare(lift) != .orderedSame }
    }
}
