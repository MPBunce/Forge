//
//  RunPlan.swift
//  Forge
//
//  Running plans, kept separate from strength cycles. A plan is a list of
//  sessions; each session is a list of timed or distance segments.
//

import Foundation
import SwiftData

struct RunSegment: Codable, Hashable {
    enum Kind: String, Codable {
        case warmUp, run, walk, coolDown, tempo

        var title: String {
            switch self {
            case .warmUp: return "Warm-up walk"
            case .run: return "Run"
            case .walk: return "Walk"
            case .coolDown: return "Cool-down walk"
            case .tempo: return "Tempo run"
            }
        }

        var isRunning: Bool { self == .run || self == .tempo }
    }

    var kind: Kind
    /// Timed segments use seconds; distance segments use kilometres.
    var seconds: Int? = nil
    var kilometres: Double? = nil

    static func run(_ seconds: Int) -> RunSegment { RunSegment(kind: .run, seconds: seconds) }
    static func walk(_ seconds: Int) -> RunSegment { RunSegment(kind: .walk, seconds: seconds) }
    static func runKm(_ km: Double) -> RunSegment { RunSegment(kind: .run, kilometres: km) }
    static func tempo(_ seconds: Int) -> RunSegment { RunSegment(kind: .tempo, seconds: seconds) }
    static let warmUp = RunSegment(kind: .warmUp, seconds: 300)
    static let coolDown = RunSegment(kind: .coolDown, seconds: 300)

    var label: String {
        if let km = kilometres { return "\(kind.title) \(RunSegment.formatKm(km))" }
        return "\(kind.title) \(RunSegment.formatDuration(seconds ?? 0))"
    }

    static func formatDuration(_ seconds: Int) -> String {
        // Short intervals read better in seconds: "90 sec" rather than "1:30 min".
        if seconds < 120 { return "\(seconds) sec" }
        if seconds % 60 == 0 { return "\(seconds / 60) min" }
        return "\(seconds / 60):\(String(format: "%02d", seconds % 60)) min"
    }

    static func formatKm(_ km: Double) -> String {
        km.formatted(.number.precision(.fractionLength(0...1))) + " km"
    }
}

struct RunSession: Codable, Hashable, Identifiable {
    var id = UUID()
    var week: Int
    var number: Int
    var title: String
    var segments: [RunSegment]
    var completedDate: Date? = nil
    /// Distance actually run, entered by the user. Optional so older saved plans still decode.
    var loggedKilometres: Double? = nil
    /// Finish time for distance runs, entered by the user.
    var loggedSeconds: Int? = nil

    var isCompleted: Bool { completedDate != nil }

    /// Plan sessions that are a race, so their sheet can log the result.
    var raceDistance: RaceDistance? {
        if title.contains("Half Marathon") { return .half }
        if title.contains("10K Run") { return .tenK }
        return nil
    }

    /// Distance credited when the run is done: what was logged, else the planned distance.
    var coveredKilometres: Double {
        guard isCompleted else { return 0 }
        return loggedKilometres ?? runningKilometres
    }

    /// Can be followed with the guided timer (every segment is timed).
    var isTimed: Bool { segments.allSatisfy { $0.seconds != nil } }

    var totalSeconds: Int { segments.compactMap(\.seconds).reduce(0, +) }

    var runningKilometres: Double {
        segments.filter { $0.kind.isRunning }.compactMap(\.kilometres).reduce(0, +)
    }

    /// One-line description, e.g. "Run 60 sec / walk 90 sec × 8" or "Run 10 km".
    var summary: String {
        if !isTimed { return "Run \(RunSegment.formatKm(runningKilometres))" }
        let core = segments.filter { $0.kind == .run || $0.kind == .walk || $0.kind == .tempo }
        // Spot a repeating run/walk pair.
        if core.count >= 4, core.count % 2 == 0 {
            let pair = Array(core.prefix(2))
            let repeats = core.count / 2
            if (0..<repeats).allSatisfy({ Array(core[($0 * 2)..<($0 * 2 + 2)]) == pair }) {
                return "\(pair[0].label.lowercased().capitalizedFirst) / \(pair[1].label.lowercased()) × \(repeats)"
            }
        }
        if core.count == 1 { return core[0].label }
        return core.map { $0.label.lowercased() }.joined(separator: ", ").capitalizedFirst
    }
}

private extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}

@Model
class RunPlan {
    var id: UUID = UUID()
    var name: String = ""
    var startDate: Date = Date()
    var sessions: [RunSession] = []

    init(name: String, sessions: [RunSession], startDate: Date = Date()) {
        self.id = UUID()
        self.name = name
        self.startDate = startDate
        self.sessions = sessions
    }

    var orderedSessions: [RunSession] {
        sessions.sorted { ($0.week, $0.number) < ($1.week, $1.number) }
    }

    var nextSession: RunSession? { orderedSessions.first { !$0.isCompleted } }
    var completedCount: Int { sessions.filter(\.isCompleted).count }
    var isCompleted: Bool { !sessions.isEmpty && sessions.allSatisfy(\.isCompleted) }
    var weekCount: Int { sessions.map(\.week).max() ?? 0 }

    func setCompleted(_ sessionID: UUID, on date: Date?) {
        guard let index = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
        sessions[index].completedDate = date
    }

    func setTime(_ sessionID: UUID, seconds: Int?) {
        guard let index = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
        sessions[index].loggedSeconds = seconds
    }

    func setDistance(_ sessionID: UUID, kilometres: Double?) {
        guard let index = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
        sessions[index].loggedKilometres = kilometres
    }

    var coveredKilometres: Double { sessions.reduce(0) { $0 + $1.coveredKilometres } }
}

// MARK: - Built-in plans

struct RunPlanTemplate: Identifiable {
    let id: String
    let name: String
    let summary: String
    let duration: String
    let makeSessions: () -> [RunSession]

    func createPlan() -> RunPlan {
        RunPlan(name: name, sessions: makeSessions())
    }

    static let all: [RunPlanTemplate] = [couchTo5K, fiveToTenK, halfMarathon, hybridRuns]

    /// The NHS Couch to 5K: 9 weeks, 3 runs a week, each with a 5 minute warm-up and cool-down walk.
    static let couchTo5K = RunPlanTemplate(
        id: "couch-to-5k",
        name: "Couch to 5K",
        summary: "From no running to 30 minutes non-stop",
        duration: "9 weeks · 3 runs a week"
    ) {
        func repeated(_ pattern: [RunSegment], _ times: Int) -> [RunSegment] {
            Array(repeating: pattern, count: times).flatMap { $0 }
        }
        let min = 60
        let weeks: [[[RunSegment]]] = [
            Array(repeating: repeated([.run(60), .walk(90)], 8), count: 3),
            Array(repeating: repeated([.run(90), .walk(120)], 6), count: 3),
            Array(repeating: repeated([.run(90), .walk(90), .run(3 * min), .walk(3 * min)], 2), count: 3),
            Array(repeating: [.run(5 * min), .walk(150), .run(5 * min), .walk(150), .run(5 * min)], count: 3),
            [[.run(5 * min), .walk(3 * min), .run(5 * min), .walk(3 * min), .run(5 * min)],
             [.run(8 * min), .walk(5 * min), .run(8 * min)],
             [.run(20 * min)]],
            [[.run(5 * min), .walk(3 * min), .run(8 * min), .walk(3 * min), .run(5 * min)],
             [.run(10 * min), .walk(3 * min), .run(10 * min)],
             [.run(25 * min)]],
            Array(repeating: [.run(25 * min)], count: 3),
            Array(repeating: [.run(28 * min)], count: 3),
            Array(repeating: [.run(30 * min)], count: 3)
        ]
        return weeks.enumerated().flatMap { weekIndex, runs in
            runs.enumerated().map { runIndex, core in
                RunSession(week: weekIndex + 1, number: runIndex + 1,
                           title: "Week \(weekIndex + 1) · Run \(runIndex + 1)",
                           segments: [.warmUp] + core + [.coolDown])
            }
        }
    }

    /// Easy time-based runs building from a 30-minute 5K to a 10K-length run.
    static let fiveToTenK = RunPlanTemplate(
        id: "5k-to-10k",
        name: "5K to 10K",
        summary: "Build from 30 minutes to a 10K",
        duration: "6 weeks · 3 runs a week"
    ) {
        let minutes: [[Int]] = [[30, 30, 35], [30, 35, 40], [35, 35, 45], [35, 40, 50], [40, 40, 55], [40, 30, 65]]
        return minutes.enumerated().flatMap { weekIndex, runs in
            runs.enumerated().map { runIndex, length in
                let isLong = runIndex == runs.count - 1
                let isRace = weekIndex == minutes.count - 1 && isLong
                return RunSession(week: weekIndex + 1, number: runIndex + 1,
                                  title: isRace ? "Week 6 · 10K Run" : "Week \(weekIndex + 1) · \(isLong ? "Long" : "Easy") Run",
                                  segments: [.warmUp, .run(length * 60), .coolDown])
            }
        }
    }

    /// Two easy runs and a long run each week, tapering into race week.
    static let halfMarathon = RunPlanTemplate(
        id: "half-marathon",
        name: "Half Marathon",
        summary: "Beginner plan for 21.1 km",
        duration: "12 weeks · 3 runs a week"
    ) {
        let long: [Double] = [6, 7, 8, 9, 10, 8, 12, 13, 14, 16, 12, 21.1]
        let easy: [Double] = [4, 4, 5, 5, 5, 5, 6, 6, 6, 7, 6, 5]
        return (0..<long.count).flatMap { index -> [RunSession] in
            let week = index + 1
            let isRaceWeek = week == long.count
            return [
                RunSession(week: week, number: 1, title: "Week \(week) · Easy Run", segments: [.runKm(easy[index])]),
                RunSession(week: week, number: 2, title: "Week \(week) · Easy Run", segments: [.runKm(isRaceWeek ? 3 : easy[index])]),
                RunSession(week: week, number: 3, title: isRaceWeek ? "Race Day · Half Marathon" : "Week \(week) · Long Run",
                           segments: [.runKm(long[index])])
            ]
        }
    }

    /// The running half of Hybrid Upper Lower: an easy run Tuesday, a tempo run Thursday and a
    /// long run Saturday, building over 7 weeks with an easier 8th week to recover.
    static let hybridRuns = RunPlanTemplate(
        id: "hybrid-runs",
        name: "Hybrid Runs",
        summary: "Easy, tempo and long runs alongside lifting",
        duration: "8 weeks · 3 runs a week"
    ) {
        let easy = [35, 35, 40, 40, 40, 45, 45, 35]
        let tempo = [15, 15, 18, 18, 20, 20, 22, 15]
        let long = [60, 65, 70, 75, 80, 85, 90, 60]
        return (0..<easy.count).flatMap { index -> [RunSession] in
            let week = index + 1
            return [
                RunSession(week: week, number: 1, title: "Week \(week) · Tue · Easy Run",
                           segments: [.run(easy[index] * 60)]),
                RunSession(week: week, number: 2, title: "Week \(week) · Thu · Tempo Run",
                           segments: [.run(10 * 60), .tempo(tempo[index] * 60), .run(10 * 60)]),
                RunSession(week: week, number: 3, title: "Week \(week) · Sat · Long Run",
                           segments: [.run(long[index] * 60)]),
            ]
        }
    }
}
