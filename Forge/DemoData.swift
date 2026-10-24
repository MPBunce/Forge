//
//  DemoData.swift
//  Forge
//
//  Development-only sample data for App Store screenshots. Launch with
//  `-ForgeDemoData` to use an in-memory store filled with a few months of
//  realistic training. Never compiled into release builds.
//

import Foundation
import SwiftData

enum DemoData {
    /// Development-only launch options for screenshots, e.g. `-ForgeTab 2 -ForgeProgress Charts`.
    /// Release builds always start on Today with default sections.
    static func launchOption(_ key: String) -> String? {
        #if DEBUG
        return UserDefaults.standard.string(forKey: key)
        #else
        return nil
        #endif
    }

    static var launchTab: Int { Int(launchOption("ForgeTab") ?? "") ?? 0 }

    #if DEBUG
    static var isEnabled: Bool { CommandLine.arguments.contains("-ForgeDemoData") }

    /// Plausible daily step totals for the last `days` days, ending today (keyed by start of day).
    static func steps(days: Int) -> [Date: Int] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var result: [Date: Int] = [:]
        for n in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: -n, to: today) else { continue }
            // Deterministic variety: most days over 10k, a few lighter ones, today in progress.
            let base = [11_240, 9_310, 12_880, 10_460, 14_120, 7_950, 10_930, 11_780, 13_050, 8_640][n % 10]
            result[day] = n == 0 ? 7_412 : base + (n % 7) * 137
        }
        return result
    }

    @MainActor
    static func seed(into context: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        func daysAgo(_ n: Int, hour: Int = 18) -> Date {
            let day = calendar.date(byAdding: .day, value: -n, to: today) ?? today
            return calendar.date(byAdding: .hour, value: hour, to: day) ?? day
        }

        // Settings and maxes (stored in lbs).
        let settings = Settings.defaultSettings
        settings.benchPressMax = 205
        settings.squatMax = 285
        settings.deadliftMax = 345
        settings.overheadPressMax = 125
        context.insert(settings)

        UserDefaults.standard.set("dark", forKey: PreferenceKeys.appearance)
        UserDefaults.standard.set(["movementbydavid-5", "starting-stretching-intermediate"].joined(separator: "\n"),
                                  forKey: PreferenceKeys.stretchRoutines)

        // Two 5/3/1 cycles: an older, lighter one and the current one, so the charts climb.
        let fiveThreeOne = Template.loadTemplates().first { $0.programType == .fiveThreeOneBasicProgram }!
        func completedCycle(scale: Double, startDaysAgo: Int, daysDone: Int) {
            let older = Settings.defaultSettings
            older.benchPressMax = settings.benchPressMax * scale
            older.squatMax = settings.squatMax * scale
            older.deadliftMax = settings.deadliftMax * scale
            older.overheadPressMax = settings.overheadPressMax * scale
            let cycle = fiveThreeOne.createCycle(with: UserSettings(from: older), startDate: daysAgo(startDaysAgo))
            let days = cycle.trainingDays.sorted { $0.dayIndex < $1.dayIndex }
            for (index, day) in days.prefix(daysDone).enumerated() {
                // Mon / Wed / Fri / Sat rhythm.
                let offsets = [0, 2, 4, 5]
                let dayOffset = (index / 4) * 7 + offsets[index % 4]
                day.completedDate = daysAgo(startDaysAgo - dayOffset)
                for exercise in day.day {
                    for set in exercise.sets {
                        if set.reps == nil { set.reps = 10 }
                        if set.isAmrap, let target = set.amrapTargetReps { set.reps = target + 3 }
                        set.completionStatus = .completedSuccessfully
                    }
                }
            }
            context.insert(cycle)
        }
        completedCycle(scale: 0.9, startDaysAgo: 70, daysDone: 16)
        completedCycle(scale: 1.0, startDaysAgo: 30, daysDone: 13)

        // Greyskull LP, just started.
        if CommandLine.arguments.contains("-ForgeDemoHybrid") {
            let hybrid = Template.loadTemplates().first { $0.programType == .hybridUpperLower }!
            context.insert(hybrid.createCycle(with: UserSettings(from: settings), startDate: Date()))
        }
        let greyskull = Template.loadTemplates().first { $0.programType == .greySkull }!
        context.insert(greyskull.createCycle(with: UserSettings(from: settings), startDate: daysAgo(1)))

        // Daily work with a solid streak.
        let items = [
            DailyWorkItem(name: "Push-ups", method: .totalReps, reps: 50, order: 0),
            DailyWorkItem(name: "Chin-ups/Pull-ups", method: .sets, reps: 5, setCount: 5, order: 1),
            DailyWorkItem(name: "Bodyweight Squats", method: .ladder, reps: 10, order: 2)
        ]
        for item in items {
            item.createdAt = daysAgo(60)
            context.insert(item)
        }
        for n in 0..<60 where n % 9 != 4 {
            for item in items {
                let reps = n == 0 ? item.dailyTarget * 3 / 5 : item.dailyTarget
                context.insert(DailyWorkEntry(itemID: item.id, day: daysAgo(n), reps: reps))
            }
        }

        // Stretching most days, with a current run of 23.
        for n in 1..<75 where n > 23 ? n % 3 != 0 : true {
            context.insert(StretchEntry(routineID: "movementbydavid-5", day: daysAgo(n)))
        }

        // Running: Couch to 5K well under way, plus races and single runs.
        let plan = RunPlanTemplate.couchTo5K.createPlan()
        plan.startDate = daysAgo(40)
        for (index, session) in plan.orderedSessions.prefix(16).enumerated() {
            plan.setCompleted(session.id, on: daysAgo(40 - index * 2 - index / 3, hour: 7))
            plan.setDistance(session.id, kilometres: 2.5 + Double(index) * 0.12)
        }
        context.insert(plan)
        context.insert(RaceResult(distance: .fiveK, seconds: 24 * 60 + 38, date: daysAgo(12, hour: 9), name: "Harbourfront 5K"))
        context.insert(RaceResult(distance: .fiveK, seconds: 26 * 60 + 5, date: daysAgo(55, hour: 9), name: "Spring Fun Run"))
        context.insert(RaceResult(distance: .tenK, seconds: 52 * 60 + 41, date: daysAgo(33, hour: 9), name: "City 10K"))
        context.insert(LoggedRun(date: daysAgo(3, hour: 7), kilometres: 6.2, seconds: 33 * 60 + 10))
        context.insert(LoggedRun(date: daysAgo(9, hour: 7), kilometres: 8.0, seconds: 44 * 60 + 2))

        // Challenges.
        let done = Challenge(title: "60s Dead Hang", details: "Hang from a bar for a full minute without letting go.")
        done.completedAt = daysAgo(6)
        context.insert(done)
        context.insert(Challenge(title: "Villain Challenge 1: Stage 2",
                                 details: "3 sets of burpees, building toward 30 reps in 90 sec per set with 1 minute rest."))
        context.insert(Challenge(title: "100 Push-ups in One Set"))

        // Goals: one strength goal already hit.
        for goal in Goal.defaultGoals {
            if goal.goal == "135lbs OHP" {
                goal.isCompleted = true
                goal.completionDate = daysAgo(8)
            }
            context.insert(goal)
        }

        try? context.save()
    }
    #endif
}
