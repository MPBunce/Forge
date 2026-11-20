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

struct DailyWorkSwitchTests {
    @Test func switchingKeepsTheDaysTotal() {
        // 50 reps across the day → 5 sets of 10.
        #expect(DailyWorkMethod.sets.reps(keepingTotalOf: .totalReps, reps: 50, setCount: 5) == 10)
        // And back again.
        #expect(DailyWorkMethod.totalReps.reps(keepingTotalOf: .sets, reps: 10, setCount: 5) == 50)
        // 55 reps as a ladder is 1 to 10.
        #expect(DailyWorkMethod.ladder.reps(keepingTotalOf: .totalReps, reps: 55, setCount: 5) == 10)
        #expect(DailyWorkMethod.totalReps.reps(keepingTotalOf: .ladder, reps: 10, setCount: 5) == 55)
    }
}

struct BodyweightTests {
    @Test func recognisesBodyweightLifts() {
        for name in ["Pull-up", "Pull-ups", "Chin-ups/Pull-ups", "Dips", "Push-ups", "Hanging Leg Raise", "Weighted Pull-up (Mastery)"] {
            #expect(Bodyweight.isBodyweight(name), "\(name)")
        }
        for name in ["Lat Pulldown", "Bench Press", "Dumbbell Fly", "One-Arm Dumbbell Row"] {
            #expect(!Bodyweight.isBodyweight(name), "\(name)")
        }
    }

    @Test func labelsAddedWeight() {
        #expect(Bodyweight.label(added: nil) == "BW")
        #expect(Bodyweight.label(added: 0) == "BW")
        #expect(Bodyweight.label(added: 25) == "BW+25")
    }

    @MainActor @Test func moreRepsAtBodyweightIsAPB() throws {
        let container = try ModelContainer(for: Cycles.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let old = ExerciseSet(setIndex: 0, weight: 0, reps: 6, completionStatus: .completedSuccessfully)
        let new = ExerciseSet(setIndex: 0, weight: 0, reps: 8, completionStatus: .completedSuccessfully)
        let day = TrainingDay(dayIndex: 0, dayName: "Upper", day: [Exercise(exerciseIndex: 0, name: "Pull-up", sets: [old])])
        let today = Exercise(exerciseIndex: 1, name: "Pull-up", sets: [new])
        let cycle = Cycles(startDate: .now, template: "Test", usesKilograms: false, trainingDays: [day])
        context.insert(cycle)
        context.insert(today)
        try context.save()
        let previous = try #require(PersonalBests.best(for: "Pull-up", in: [cycle]))
        #expect(previous.reps == 6)
        #expect(PersonalBests.newBest(among: [new], usesKilograms: false, previous: previous) === new)
    }
}
