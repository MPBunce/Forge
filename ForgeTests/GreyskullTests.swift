//
//  GreyskullTests.swift
//  ForgeTests
//

import Testing
@testable import Forge

struct GreyskullTests {
    @Test func lowerLiftRotatesIndependentlyOfUpperDays() {
        let days = GreyskullLPProgram().trainingDays
        #expect(days.count == 6)
        let lower = days.map { day in day.day.contains { $0.name == "Deadlift" } ? "D" : "S" }
        #expect(lower == ["S", "D", "S", "S", "D", "S"])
        let upper = days.map { day in day.day.first?.name ?? "" }
        #expect(upper == ["Bench Press", "Overhead Press", "Bench Press", "Overhead Press", "Bench Press", "Overhead Press"])
        // Each lower lift is paired with both upper days over the two weeks.
        let squatDays = Set(days.filter { $0.day.contains { $0.name == "Squat" } }.compactMap { $0.day.first?.name })
        let deadliftDays = Set(days.filter { $0.day.contains { $0.name == "Deadlift" } }.compactMap { $0.day.first?.name })
        #expect(squatDays.count == 2 && deadliftDays.count == 2)
    }
}

struct HybridUpperLowerTests {
    @Test func liftingDaysOnly() {
        let days = HybridUpperLowerProgram().trainingDays
        let names = days.map { $0.dayName }
        let indexes = days.map { $0.dayIndex }
        let lowerSets = days[0].day.reduce(0) { $0 + $1.sets.count }
        let upperSets = days[1].day.reduce(0) { $0 + $1.sets.count }
        let allToFailure = days.allSatisfy { day in day.day.allSatisfy { ex in ex.sets.allSatisfy { $0.isAmrap } } }
        let fiveEach = days.allSatisfy { $0.day.count == 5 }
        #expect(names == ["Mon · Lower A", "Wed · Upper A", "Fri · Lower B", "Sun · Upper B"])
        #expect(indexes == [0, 1, 2, 3])
        #expect(lowerSets == 18)  // 4 quad + 4 ham + 4 glute + 3 abs + 3 calves
        #expect(upperSets == 15)  // 4 chest + 4 back + 3 shoulder + 4 arms
        #expect(allToFailure)
        #expect(fiveEach)
    }

    @Test func hybridRunsPlan() {
        let sessions = RunPlanTemplate.hybridRuns.makeSessions()
        let count = sessions.count
        let allTimed = sessions.allSatisfy { $0.isTimed }
        let hasTempo = sessions.contains { session in session.segments.contains { $0.kind == .tempo } }
        #expect(count == 24)
        #expect(allTimed)
        #expect(hasTempo)
    }
}

struct DayPagerTests {
    private func days(_ names: [String]) -> [TrainingDay] {
        names.enumerated().map { TrainingDay(dayIndex: $0.offset, dayName: $0.element, day: []) }
    }

    @Test func groupsByWeekOrSevens() {
        let weekly = days(["Week 1 - Bench", "Week 1 - Squat", "Week 2 - Bench", "Week 2 - Squat"])
        let weeklyPages = DayPager.pages(weekly).map(\.count)
        #expect(weeklyPages == [2, 2])
        let flat = days((1...9).map { "Day \($0)" })
        let flatPages = DayPager.pages(flat).map(\.count)
        #expect(flatPages == [7, 2])
    }

    @Test func titlesDropRepeatedPrefixes() {
        let weekly = days(["Week 1 - Bench", "Week 1 - Squat", "Week 2 - Bench"])
        let t1 = DayPager.title(for: weekly[2], in: weekly)
        #expect(t1 == "Week 2 · Day 1 · Bench")
        let hybrid = days(["Mon · Lower A", "Wed · Upper A"])
        let t2 = DayPager.title(for: hybrid[1], in: hybrid)
        #expect(t2 == "Wed · Upper A")
        let ppl = days(["Push", "Pull", "Legs"])
        let t3 = DayPager.title(for: ppl[1], in: ppl)
        #expect(t3 == "Day 2 · Pull")
    }
}
