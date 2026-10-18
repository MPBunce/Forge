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
    @Test func weekLayoutAndVolume() {
        let days = HybridUpperLowerProgram().trainingDays
        #expect(days.map(\.dayName) == ["Mon · Lower A", "Tue · Easy Run", "Wed · Upper A", "Thu · Tempo Run",
                                        "Fri · Lower B", "Sat · Long Run", "Sun · Upper B"])
        let lowerA = days[0].day.reduce(0) { $0 + $1.sets.count }
        let upperA = days[2].day.reduce(0) { $0 + $1.sets.count }
        #expect(lowerA == 14)  // 2 squat + 4 quad + 4 ham + 4 glute
        #expect(upperA == 15)  // 4 chest + 4 back + 3 shoulder + 4 arms
        // Every lifting set is taken to failure.
        #expect(days[0].day.allSatisfy { $0.sets.allSatisfy(\.isAmrap) })
    }
}
