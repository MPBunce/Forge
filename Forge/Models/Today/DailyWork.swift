//
//  DailyWork.swift
//  Forge
//
//  Bodyweight work done every day, outside of the lifting cycle
//  (same three methods as the GSLP program builder).
//

import Foundation
import SwiftData

enum DailyWorkMethod: String, Codable, CaseIterable, Identifiable {
    /// Hit a total number of reps, spread across the day.
    case totalReps
    /// Climb 1, 2, 3 ... up to a peak rung.
    case ladder
    /// A fixed number of sets of a fixed number of reps.
    case sets

    var id: Self { self }

    /// The reps to show after switching from `old` to this method, keeping roughly the same
    /// day's total: 50 total reps becomes 5 × 10 as sets, or a ladder to 10 (55 reps).
    func reps(keepingTotalOf old: DailyWorkMethod, reps: Int, setCount: Int) -> Int {
        let total: Int = switch old {
        case .totalReps: reps
        case .ladder: reps * (reps + 1) / 2
        case .sets: reps * setCount
        }
        switch self {
        case .totalReps:
            return max(1, total)
        case .sets:
            return max(1, Int((Double(total) / Double(max(1, setCount))).rounded()))
        case .ladder:
            // The top rung whose ladder (1 + 2 + … + n) comes closest to the total.
            let top = ((8 * Double(total) + 1).squareRoot() - 1) / 2
            return max(1, Int(top.rounded()))
        }
    }

    var title: String {
        switch self {
        case .totalReps: return "Total reps"
        case .ladder: return "Ladder"
        case .sets: return "Sets"
        }
    }
}

@Model
class DailyWorkItem {
    var id: UUID = UUID()
    var name: String = ""
    var methodRaw: String = DailyWorkMethod.totalReps.rawValue
    /// Total reps for `.totalReps`, the peak rung for `.ladder`, reps per set for `.sets`.
    var reps: Int = 50
    /// Only used by `.sets`.
    var setCount: Int = 5
    var order: Int = 0
    var createdAt: Date = Date()

    init(name: String, method: DailyWorkMethod, reps: Int, setCount: Int = 5, order: Int = 0) {
        self.id = UUID()
        self.name = name
        self.methodRaw = method.rawValue
        self.reps = reps
        self.setCount = setCount
        self.order = order
        self.createdAt = Date()
    }

    var method: DailyWorkMethod {
        get { DailyWorkMethod(rawValue: methodRaw) ?? .totalReps }
        set { methodRaw = newValue.rawValue }
    }

    /// Reps needed to call the day done.
    var dailyTarget: Int {
        switch method {
        case .totalReps: return reps
        case .ladder: return reps * (reps + 1) / 2
        case .sets: return reps * setCount
        }
    }

    var prescription: String {
        switch method {
        case .totalReps: return "\(reps) reps across the day"
        case .ladder: return "Ladder 1 to \(reps) (\(dailyTarget) reps)"
        case .sets: return "\(setCount) × \(reps)"
        }
    }

    /// Reps added by the quick-log button: one set, or a chunk of the daily total.
    var quickAddAmount: Int {
        switch method {
        case .totalReps: return max(1, min(10, reps / 5))
        case .ladder: return reps
        case .sets: return reps
        }
    }

    static let presets: [(name: String, method: DailyWorkMethod, reps: Int)] = [
        ("Chin-ups/Pull-ups", .totalReps, 25),
        // For lifters who can't do a full chin-up yet: jump to the top, lower slowly (3-5 sec).
        ("Chin-up Negatives", .totalReps, 10),
        ("Push-ups", .totalReps, 50),
        ("Dips", .totalReps, 30),
        ("Bodyweight Squats", .totalReps, 50),
        ("Sit-ups", .totalReps, 50)
    ]
}

/// Reps logged for one daily-work item on one calendar day.
@Model
class DailyWorkEntry {
    var itemID: UUID = UUID()
    /// Start of the day the reps belong to.
    var day: Date = Date()
    var reps: Int = 0

    init(itemID: UUID, day: Date, reps: Int) {
        self.itemID = itemID
        self.day = Calendar.current.startOfDay(for: day)
        self.reps = reps
    }
}
