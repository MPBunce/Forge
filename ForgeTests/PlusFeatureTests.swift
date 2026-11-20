//
//  PlusFeatureTests.swift
//  ForgeTests
//

import Foundation
import Testing
@testable import Forge

struct ProgressionTests {
    @Test func rangesFromTargets() {
        #expect(Progression.rangeText(forTarget: 5) == "5–8")
        #expect(Progression.rangeText(forTarget: 8) == "8–12")
        #expect(Progression.rangeText(forTarget: 12) == "12–20")
    }

    @Test func goesUpOnlyWhenEverySetHitsTheTop() {
        let top = ExerciseSet(setIndex: 0, weight: 40, reps: 8, isAmrap: true, amrapTargetReps: 5, completionStatus: .completedSuccessfully)
        let alsoTop = ExerciseSet(setIndex: 1, weight: 40, reps: 9, isAmrap: true, amrapTargetReps: 5, completionStatus: .completedSuccessfully)
        let short = ExerciseSet(setIndex: 1, weight: 40, reps: 7, isAmrap: true, amrapTargetReps: 5, completionStatus: .completedSuccessfully)
        #expect(Progression.earnedIncrease([top, alsoTop]))
        #expect(!Progression.earnedIncrease([top, short]))
        #expect(!Progression.earnedIncrease([]))
    }

    @Test func trainingMaxAndLinearProgramsAreLeftAlone() {
        let settings = UserSettings(from: Settings.defaultSettings)
        func cycle(_ type: ProgramType) -> Cycles {
            Template.loadTemplates().first { $0.programType == type }!.createCycle(with: settings)
        }
        #expect(!Progression.usesRepRanges(cycle(.fiveThreeOneBasicProgram)))
        #expect(!Progression.usesRepRanges(cycle(.nSuns4Days)))
        #expect(!Progression.usesRepRanges(cycle(.greySkull)))
        #expect(Progression.usesRepRanges(cycle(.dumbbellUpperLower)))
        #expect(Progression.usesRepRanges(cycle(.hybridUpperLower)))
    }
}

struct WarmUpTests {
    @Test func barbellRampsFromTheBar() {
        let steps = WarmUp.steps(to: 225, bar: 45, smallest: 2.5, isBarbell: true)
        #expect(steps.first == .init(weight: 45, reps: 5))
        #expect(steps.map(\.weight) == [45, 90, 135, 180])
        #expect(steps.allSatisfy { $0.weight < 225 })
    }

    @Test func lightOrDumbbellWork() {
        #expect(WarmUp.steps(to: 55, bar: 45, smallest: 2.5, isBarbell: true).isEmpty)
        let dumbbell = WarmUp.steps(to: 50, bar: 45, smallest: 2.5, isBarbell: false)
        #expect(dumbbell.first?.weight == 20)
        #expect(!WarmUp.isBarbell("Dumbbell Bench Press"))
        #expect(WarmUp.isBarbell("Bench Press"))
    }
}

struct ExportAndLogTests {
    @Test func csvQuotesAndLists() {
        let set = ExerciseSet(setIndex: 0, weight: 135, reps: 5, completionStatus: .completedSuccessfully)
        let skipped = ExerciseSet(setIndex: 1, weight: 135, reps: 5)
        let day = TrainingDay(dayIndex: 0, dayName: "Mon, Upper", day: [Exercise(exerciseIndex: 0, name: "Bench Press", sets: [set, skipped])])
        let cycle = Cycles(startDate: Date(timeIntervalSince1970: 1_790_000_000), template: "Test", usesKilograms: false, trainingDays: [day])
        let lines = WorkoutExport.csv([cycle]).split(separator: "\n")
        #expect(lines.first.map(String.init) == WorkoutExport.header)
        #expect(lines.count == 2)   // the set not done is left out
        #expect(lines[1].contains("\"Mon, Upper\",Bench Press,1,135,lbs,5,Done"))
    }

    @Test func weighInsKeepOnePerDay() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now).addingTimeInterval(9 * 3600)
        let entries = [
            WeighIn(date: calendar.date(byAdding: .day, value: -8, to: today)!, pounds: 184),
            WeighIn(date: calendar.date(byAdding: .day, value: -1, to: today)!, pounds: 182.5),
            WeighIn(date: today, pounds: 182),
        ]
        #expect(BodyweightLog.weekChange(entries) == -2)
        #expect(BodyweightLog.weekChange(Array(entries.suffix(2))) == nil)
    }

    @Test func notesFollowTheLift() {
        ExerciseNotes.setNote("Seat at 4", for: "Lat Pulldowns")
        #expect(ExerciseNotes.note(for: "Lat Pulldown") == "Seat at 4")
        ExerciseNotes.setNote("  ", for: "Lat Pulldown")
        #expect(ExerciseNotes.note(for: "Lat Pulldown") == nil)
    }
}
