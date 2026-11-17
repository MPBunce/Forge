//
//  CarryOverTests.swift
//  ForgeTests
//

import Foundation
import SwiftData
import Testing
@testable import Forge

@MainActor
struct CarryOverTests {
    private let settings = UserSettings(from: Settings.defaultSettings)

    private func template(_ type: ProgramType) -> Template {
        Template.loadTemplates().first { $0.programType == type }!
    }

    @Test func swapsCarryIntoTheNextCycle() {
        let dumbbell = template(.dumbbellUpperLower)
        let cycle = dumbbell.createCycle(with: settings, swaps: ["Bulgarian Split Squat": "Reverse Lunges"])
        let swaps = ExerciseSwaps.made(in: cycle, template: dumbbell, settings: settings)
        #expect(swaps == ["Bulgarian Split Squat": "Reverse Lunges"])

        let next = dumbbell.createCycle(with: settings, swaps: swaps)
        let lower = next.trainingDays.first { $0.dayIndex == 1 }!
        #expect(lower.day.first?.name == "Reverse Lunges")
    }

    @Test func noSwapsMeansNothingCarries() {
        let greyskull = template(.greySkull)
        let cycle = greyskull.createCycle(with: settings)
        #expect(ExerciseSwaps.made(in: cycle, template: greyskull, settings: settings).isEmpty)
    }

    @Test func aLateSwapStillCarries() {
        let dumbbell = template(.dumbbellUpperLower)
        let cycle = dumbbell.createCycle(with: settings)
        // Swapped mid-cycle: only the last two days changed.
        let later = cycle.trainingDays.filter { $0.dayIndex >= 2 }
        ExerciseSwaps.apply(["Pull-up": "Lat Pulldown"], to: later)
        #expect(ExerciseSwaps.made(in: cycle, template: dumbbell, settings: settings) == ["Pull-up": "Lat Pulldown"])
    }

    @Test func lastUsedPicksTheNewestCycleOfThatProgram() {
        let dumbbell = template(.dumbbellUpperLower)
        let old = dumbbell.createCycle(with: settings, startDate: .now.addingTimeInterval(-90 * 86_400),
                                       swaps: ["Pull-up": "Chin-up"])
        let newest = dumbbell.createCycle(with: settings, swaps: ["Pull-up": "Lat Pulldown"])
        let other = template(.greySkull).createCycle(with: settings)
        #expect(ExerciseSwaps.lastUsed(for: dumbbell, in: [old, newest, other], settings: settings) == ["Pull-up": "Lat Pulldown"])
    }

    @Test func newSetsStartFromTheLastWeightUsed() throws {
        let container = try ModelContainer(for: Cycles.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let greyskull = template(.greySkull)

        let older = greyskull.createCycle(with: settings, startDate: .now.addingTimeInterval(-30 * 86_400))
        let newer = greyskull.createCycle(with: settings, startDate: .now.addingTimeInterval(-2 * 86_400))
        context.insert(older)
        context.insert(newer)

        func log(_ cycle: Cycles, day: Int, _ weights: [Double]) {
            let bench = cycle.trainingDays.first { $0.dayIndex == day }!.day.first { $0.name == "Bench Press" }!
            for (set, weight) in zip(bench.orderedSets, weights) {
                set.weight = weight
                set.completionStatus = .completedSuccessfully
            }
        }
        log(older, day: 0, [100, 100, 100])
        log(newer, day: 0, [135, 135, 140])
        try context.save()

        // Bench comes up again on day 2 of the newer cycle.
        let today = newer.trainingDays.first { $0.dayIndex == 2 }!.day.first { $0.name == "Bench Press" }!
        #expect(LastWeight.find(for: today, in: [older, newer], usesKilograms: false) == 140)
        // Different unit: nothing to go on.
        #expect(LastWeight.find(for: today, in: [older, newer], usesKilograms: true) == nil)
    }
}
