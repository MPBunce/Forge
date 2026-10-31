import Foundation
import SwiftData


// MARK: - Program Protocol
protocol ProgramProtocol {
    func copyTrainingDays() -> [TrainingDay]
    func generateDays(with settings: UserSettings) -> [TrainingDay]
}

// MARK: - Default Implementation
extension ProgramProtocol {
    func generateDays(with settings: UserSettings) -> [TrainingDay] {
        // Default implementation just returns copied days
        // Override this method in programs that need to use training maxes
        return copyTrainingDays()
    }
}

// MARK: - Training Maxes
struct UserSettings {
    let squat: Double
    let bench: Double
    let deadlift: Double
    let press: Double
    let useKilograms: Bool
    let rounding: WeightRounding

    /// Training maxes are stored in lbs; programs get them in the lifter's own unit
    /// so percentages are taken and rounded once, in the unit they'll load.
    init(from settings: Settings) {
        let unit: (Double) -> Double = settings.usesKilograms ? WeightConverter.lbsToKg : { $0 }
        self.squat = unit(settings.squatMax)
        self.bench = unit(settings.benchPressMax)
        self.deadlift = unit(settings.deadliftMax)
        self.press = unit(settings.overheadPressMax)
        self.useKilograms = settings.usesKilograms
        self.rounding = settings.weightRounding
    }
}

// MARK: - Template Structure
struct Template: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let duration: String
    let programType: ProgramType
    
    /// `swaps` renames lifts for this cycle (Forge Plus), keyed by the program's name for each lift.
    func createCycle(with settings: UserSettings, startDate: Date = Date(), swaps: [String: String] = [:]) -> Cycles {
        let program = programType.createProgram(with: settings)
        let trainingDays = program.generateDays(with: settings)
        ExerciseSwaps.apply(swaps, to: trainingDays)
        
        // Programs return exact percentages of the training max; round them to loadable weights.
        for set in trainingDays.flatMap({ $0.day }).flatMap({ $0.sets }) {
            if let weight = set.weight {
                set.weight = settings.rounding.round(weight)
            }
        }
        
        return Cycles(
            startDate: startDate,
            template: name,
            usesKilograms: settings.useKilograms,
            trainingDays: trainingDays
        )
    }
}

// MARK: - Program Types
enum ProgramType {

    case fiveThreeOneBBBProgram
    case fiveThreeOneBasicProgram
    
    case arnoldProgram
    case greySkull
    case menzer

    case nSuns4Days
    case nSuns5Days
    case nSuns6DaysSquat
    case nSuns6DaysDeadlift

    case pushPullLegs
    case upperLowerFourDay
    case upperLowerFiveDay
    case hybridUpperLower
    case dumbbellUpperLower
    case dumbbellFullBody

    func createProgram(with settings: UserSettings) -> ProgramProtocol {
        switch self {
        case .menzer:
            return MenzerProgram()
        case .pushPullLegs:
            return PPLProgram()
        case .upperLowerFourDay:
            return UpperLowerProgram()
        case .upperLowerFiveDay:
            return FiveDayUpperLowerProgram()
        case .hybridUpperLower:
            return HybridUpperLowerProgram()
        case .dumbbellUpperLower:
            return DumbbellUpperLowerProgram()
        case .dumbbellFullBody:
            return DumbbellFullBodyProgram()
        case .nSuns4Days:
            return nSunsFourDayProgram(benchTM: settings.bench, squatTM: settings.squat, deadliftTM: settings.deadlift, ohpTM: settings.press)
        case .nSuns5Days:
            return nSunsFiveDayProgram(benchTM: settings.bench, squatTM: settings.squat, deadliftTM: settings.deadlift, ohpTM: settings.press)
        case .nSuns6DaysSquat:
            return nSunsSixDaySquatProgram(benchTM: settings.bench, squatTM: settings.squat, deadliftTM: settings.deadlift, ohpTM: settings.press)
        case .nSuns6DaysDeadlift:
            return nSunsSixDayDeadliftProgram(benchTM: settings.bench, squatTM: settings.squat, deadliftTM: settings.deadlift, ohpTM: settings.press)
        case .fiveThreeOneBBBProgram:
            return FiveThreeOneBBBProgram(benchTM: settings.bench, squatTM: settings.squat, deadliftTM: settings.deadlift, ohpTM: settings.press)
        case .fiveThreeOneBasicProgram:
            return FiveThreeOneBasicProgram(benchTM: settings.bench, squatTM: settings.squat, deadliftTM: settings.deadlift, ohpTM: settings.press)
        case .greySkull:
            return GreyskullLPProgram()
        case .arnoldProgram:
            return ArnoldSplit()

        }
    }
}

// MARK: - Template Loading
extension Template {
    static func loadTemplates() -> [Template] {
        return [
            // 5/3/1 Programs
            Template(
                id: "FiveThreeOneBasicProgram",
                name: "5/3/1",
                description: "Slow, steady strength on the big four lifts",
                duration: "4 weeks",
                programType: .fiveThreeOneBasicProgram
            ),
            Template(
                id: "FiveThreeOneBBBProgram",
                name: "5/3/1 Big But Boring",
                description: "5/3/1 plus five sets of ten, for size",
                duration: "4 weeks",
                programType: .fiveThreeOneBBBProgram
            ),
            
            // Individual Programs
            Template(
                id: "ArnoldProgram",
                name: "Arnold Split",
                description: "Chest and back, shoulders and arms, legs, each twice a week",
                duration: "6 days",
                programType: .arnoldProgram
            ),
            Template(
                id: "GreySkull",
                name: "Greyskull LP",
                description: "Add weight every session on a few big lifts",
                duration: "2 weeks",
                programType: .greySkull
            ),
            Template(
                id: "classic-menzer",
                name: "Classic Menzer Cycle",
                description: "One all-out set per exercise, with lots of rest",
                duration: "4 days",
                programType: .menzer
            ),

            // nSuns Programs
            Template(
                id: "nSuns4Day",
                name: "nSuns 4 Day",
                description: "High-volume strength, built on 5/3/1",
                duration: "4 days",
                programType: .nSuns4Days
            ),
            Template(
                id: "nSuns5Day",
                name: "nSuns 5 Day",
                description: "nSuns with a fifth day",
                duration: "5 days",
                programType: .nSuns5Days
            ),
            Template(
                id: "nSuns6DaySquat",
                name: "nSuns 6 Day Squat",
                description: "Six days, with extra squat volume",
                duration: "6 days",
                programType: .nSuns6DaysSquat
            ),
            Template(
                id: "nSuns6DayDeadlift",
                name: "nSuns 6 Day Deadlift",
                description: "Six days, with extra deadlift volume",
                duration: "6 days",
                programType: .nSuns6DaysDeadlift
            ),

            // Split Programs
            Template(
                id: "ppl",
                name: "Push Pull Legs",
                description: "A push day, a pull day and a leg day",
                duration: "3 days",
                programType: .pushPullLegs
            ),
            Template(
                id: "upper_lower_four",
                name: "Upper Lower (4 Day)",
                description: "Each muscle twice a week; the main lift alternates",
                duration: "4 days",
                programType: .upperLowerFourDay
            ),
            Template(
                id: "upper_lower_five",
                name: "Upper Lower (5 Day)",
                description: "Upper Lower plus an arms and shoulders day",
                duration: "5 days",
                programType: .upperLowerFiveDay
            ),
            Template(
                id: "dumbbell_upper_lower",
                name: "Dumbbell Upper Lower",
                description: "Home gym upper/lower: PR and Mastery days",
                duration: "4 days",
                programType: .dumbbellUpperLower
            ),
            Template(
                id: "dumbbell_full_body",
                name: "Dumbbell Full Body",
                description: "Home gym full body: three workouts, PR and Mastery",
                duration: "6 days",
                programType: .dumbbellFullBody
            ),
            Template(
                id: "hybrid_upper_lower",
                name: "Hybrid Upper Lower",
                description: "Low-volume lifting to failure, for runners",
                duration: "4 days",
                programType: .hybridUpperLower
            )
        ]
    }
}
