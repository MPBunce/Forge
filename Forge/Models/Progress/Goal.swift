//
//  Goal.swift
//  Forge
//
//  Created by Matthew Bunce on 2025-06-08.
//
import Foundation
import SwiftData

@Model
class Goal {
    var goal: String = ""
    var completionDate: Date?
    var isCompleted: Bool = false
    /// Display position; SwiftData doesn't keep insertion order.
    var order: Int = 0
    /// Auto-tracked goals: the lift name (or `Goal.totalLift`) and target weight in lbs.
    /// Nil for goals the user ticks off by hand.
    var autoLift: String? = nil
    var targetLbs: Double? = nil

    init(goal: String, order: Int = 0, completionDate: Date? = nil, isCompleted: Bool = false) {
        self.goal = goal
        self.order = order
        self.completionDate = completionDate
        self.isCompleted = isCompleted
    }
}

extension Goal {
    /// Marker for the squat + bench + deadlift total.
    static let totalLift = "Total"
    static let totalLifts = ["Squat", "Bench Press", "Deadlift"]

    /// Default goals that the app can check from logged sets, keyed by their text.
    static let autoTargets: [String: (lift: String, lbs: Double)] = [
        "135lbs OHP": ("Overhead Press", 135),
        "225lbs Bench": ("Bench Press", 225),
        "315lbs Squat": ("Squat", 315),
        "405lbs Deadlift": ("Deadlift", 405),
        "1000lbs total (Total of your 1 rep max on Squat, Bench, and Deadlift)": (totalLift, 1000)
    ]

    var isAutoTracked: Bool { autoLift != nil && targetLbs != nil }

    /// Fills in auto-tracking for default goals created before it existed.
    func backfillAutoTarget() {
        guard autoLift == nil, let target = Goal.autoTargets[goal] else { return }
        autoLift = target.lift
        targetLbs = target.lbs
    }

    static var defaultGoals: [Goal] {
        [
            "135lbs OHP",
            "225lbs Bench",
            "315lbs Squat",
            "405lbs Deadlift",
            "1000lbs total (Total of your 1 rep max on Squat, Bench, and Deadlift)",
            "Sub 6-minute mile",
            "60s Dead Hang",
            "Bodyweight farmers walk for 100m (e.g., 200lbs = 100lbs per hand)"
        ].enumerated().map { index, text in
            let goal = Goal(goal: text, order: index)
            goal.backfillAutoTarget()
            return goal
        }
    }
}
