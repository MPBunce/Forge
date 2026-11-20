//
//  WorkoutExport.swift
//  Forge
//
//  Forge Plus: every logged set as a CSV file, to keep a backup or open in a spreadsheet.
//

import Foundation

enum WorkoutExport {
    static let header = "Date,Program,Day,Exercise,Set,Weight,Unit,Reps,Result"

    static func csv(_ cycles: [Cycles]) -> String {
        var rows = [header]
        let dateFormat = Date.ISO8601FormatStyle().year().month().day()
        for cycle in cycles.sorted(by: { $0.startDate < $1.startDate }) {
            let unit = cycle.usesKilograms ? "kg" : "lbs"
            for day in cycle.trainingDays.sorted(by: { $0.dayIndex < $1.dayIndex }) {
                for exercise in day.day.sorted(by: { $0.exerciseIndex < $1.exerciseIndex }) {
                    let bodyweight = Bodyweight.isBodyweight(exercise.name)
                    for set in exercise.orderedSets where set.completionStatus != .notStarted {
                        let weight = bodyweight ? Bodyweight.label(added: set.weight) : set.weight.map { WeightConverter.format($0) } ?? ""
                        let result = set.completionStatus == .completedSuccessfully ? "Done" : "Missed"
                        rows.append([
                            (day.completedDate ?? cycle.startDate).formatted(dateFormat),
                            cycle.template, day.dayName, exercise.name,
                            String(set.setIndex + 1), weight, unit, set.reps.map(String.init) ?? "", result,
                        ].map(field).joined(separator: ","))
                    }
                }
            }
        }
        return rows.joined(separator: "\n") + "\n"
    }

    /// Quotes a field if it has a comma, quote or line break.
    private static func field(_ value: String) -> String {
        guard value.contains(where: { $0 == "," || $0 == "\"" || $0.isNewline }) else { return value }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    /// Writes the file for sharing and returns where it is.
    static func file(_ cycles: [Cycles]) throws -> URL {
        let stamp = Date.now.formatted(Date.ISO8601FormatStyle().year().month().day())
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Forge Workouts \(stamp).csv")
        try csv(cycles).write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
