//
//  LiftTests.swift
//  ForgeTests
//

import Foundation
import Testing
@testable import Forge

struct PersonalBestTests {
    @Test func moreRepsAtLessWeightCanBeAPB() {
        #expect(PersonalBests.estimatedMax(weight: 225, reps: 5) > PersonalBests.estimatedMax(weight: 235, reps: 1))
        #expect(PersonalBests.estimatedMax(weight: 100, reps: 1) == 100)
    }

    @Test func namesMatchLoosely() {
        #expect(PersonalBests.key("Barbell Rows") == PersonalBests.key("Barbell Row"))
        #expect(PersonalBests.key("Pull-ups") == PersonalBests.key("Pull Ups"))
        #expect(PersonalBests.key("Squat (BBB)") == PersonalBests.key("Squat"))
        #expect(PersonalBests.key("Bench Press") != PersonalBests.key("Incline Bench Press"))
    }

    @Test func firstSessionSetsTheBar() {
        let set = ExerciseSet(setIndex: 0, weight: 200, reps: 5, completionStatus: .completedSuccessfully)
        #expect(PersonalBests.newBest(among: [set], usesKilograms: false, previous: nil) == nil)
        let previous = PersonalBests.Best(estimatedMax: 220, weight: 190, reps: 5, usesKilograms: false, date: nil)
        #expect(PersonalBests.newBest(among: [set], usesKilograms: false, previous: previous) === set)
        let failed = ExerciseSet(setIndex: 1, weight: 300, reps: 5, completionStatus: .failed)
        #expect(PersonalBests.newBest(among: [failed], usesKilograms: false, previous: previous) == nil)
    }
}

struct LiftGuideTests {
    @Test func everyBuiltInLiftHasAHowTo() {
        let settings = UserSettings(from: Settings.defaultSettings)
        var missing: Set<String> = []
        for template in Template.loadTemplates() {
            for exercise in template.createCycle(with: settings).trainingDays.flatMap(\.day) where !exercise.isCheckOff {
                if LiftGuide.guide(for: exercise.name) == nil { missing.insert(exercise.name) }
            }
        }
        #expect(missing.isEmpty, "No how-to for: \(missing.sorted().joined(separator: ", "))")
    }

    @Test func specificGuidesWinOverGeneralOnes() {
        #expect(LiftGuide.guide(for: "Leg Curls")?.steps.first?.contains("pivot") == true)
        #expect(LiftGuide.guide(for: "Incline Dumbbell Curl")?.steps.first?.contains("elbows") == true)
        #expect(LiftGuide.guide(for: "Front Squat")?.steps.first?.contains("front of your shoulders") == true)
        #expect(LiftGuide.guide(for: "Press") != nil)
    }
}

struct ProgramGroupTests {
    @Test func everyProgramHasAGroup() {
        let groups = Set(Template.loadTemplates().map(\.programType.group))
        #expect(groups == Set(ProgramGroup.allCases))
    }
}
