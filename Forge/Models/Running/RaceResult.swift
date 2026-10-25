//
//  RaceResult.swift
//  Forge
//
//  Logged race results (5K, 10K, half and full marathon) and the time goals for each.
//

import Foundation
import SwiftData

enum RaceDistance: String, Codable, CaseIterable, Identifiable {
    case fiveK, tenK, half, marathon

    var id: Self { self }

    var name: String {
        switch self {
        case .fiveK: return "5K"
        case .tenK: return "10K"
        case .half: return "Half Marathon"
        case .marathon: return "Marathon"
        }
    }

    var kilometres: Double {
        switch self {
        case .fiveK: return 5
        case .tenK: return 10
        case .half: return 21.0975
        case .marathon: return 42.195
        }
    }

    /// Rough top-5% finish time across all finishers in large public races: the fixed goal time.
    var defaultTopFivePercentSeconds: Int {
        switch self {
        case .fiveK: return 21 * 60
        case .tenK: return 44 * 60
        case .half: return 96 * 60
        case .marathon: return 200 * 60
        }
    }
}

@Model
class RaceResult {
    var distanceRaw: String = RaceDistance.fiveK.rawValue
    var seconds: Int = 0
    var date: Date = Date()
    var name: String = ""

    init(distance: RaceDistance, seconds: Int, date: Date, name: String = "") {
        self.distanceRaw = distance.rawValue
        self.seconds = seconds
        self.date = date
        self.name = name
    }

    var distance: RaceDistance {
        get { RaceDistance(rawValue: distanceRaw) ?? .fiveK }
        set { distanceRaw = newValue.rawValue }
    }

    /// Minutes and seconds per kilometre, e.g. "5:12 /km".
    var pace: String {
        let perKm = Double(seconds) / distance.kilometres
        let total = Int(perKm.rounded())
        return String(format: "%d:%02d /km", total / 60, total % 60)
    }
}

/// A one-off run outside any plan.
@Model
class LoggedRun {
    var date: Date = Date()
    var kilometres: Double = 0
    /// Optional finish time.
    var seconds: Int? = nil
    /// The Apple Health workout this run was imported from, if any.
    var healthID: String? = nil

    init(date: Date, kilometres: Double, seconds: Int?) {
        self.date = date
        self.kilometres = kilometres
        self.seconds = seconds
    }
}

enum RaceTime {
    /// Parses "25:30" or "1:05:30" (or plain minutes, "45") into seconds.
    static func parse(_ text: String) -> Int? {
        let parts = text.split(separator: ":").map { Int($0.trimmingCharacters(in: .whitespaces)) }
        guard !parts.isEmpty, parts.allSatisfy({ $0 != nil }) else { return nil }
        let values = parts.compactMap { $0 }
        switch values.count {
        case 1: return values[0] * 60
        case 2: return values[1] < 60 ? values[0] * 60 + values[1] : nil
        case 3: return values[1] < 60 && values[2] < 60 ? values[0] * 3600 + values[1] * 60 + values[2] : nil
        default: return nil
        }
    }

    /// "5:12 /km" for a time over a distance.
    static func pace(seconds: Int, kilometres: Double) -> String? {
        guard kilometres > 0, seconds > 0 else { return nil }
        let perKm = Int((Double(seconds) / kilometres).rounded())
        return String(format: "%d:%02d /km", perKm / 60, perKm % 60)
    }

    /// "21:30" or "1:36:00".
    static func format(_ seconds: Int) -> String {
        let h = seconds / 3600, m = (seconds % 3600) / 60, s = seconds % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }
}
