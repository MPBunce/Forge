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
