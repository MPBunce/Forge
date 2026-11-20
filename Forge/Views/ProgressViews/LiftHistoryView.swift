//
//  LiftHistoryView.swift
//  Forge
//
//  Every session of one lift, newest first, from every cycle: the date, the program and
//  day, each logged set, and a trophy on sessions that set a new best.
//

import SwiftUI
import SwiftData

struct LiftHistoryView: View {
    let lift: String
    @Query(sort: \Cycles.startDate) private var cycles: [Cycles]

    struct Session: Identifiable {
        let id: PersistentIdentifier
        let date: Date
        let program: String
        let day: String
        let sets: [ExerciseSet]
        let unit: String
        let isBodyweight: Bool
        var isPB = false
    }

    private var sessions: [Session] {
        let key = PersonalBests.key(lift)
        var found: [Session] = []
        for cycle in cycles {
            for day in cycle.trainingDays {
                for exercise in day.day where PersonalBests.key(exercise.name) == key {
                    let logged = exercise.orderedSets.filter { $0.completionStatus != .notStarted }
                    guard !logged.isEmpty else { continue }
                    found.append(Session(id: exercise.persistentModelID,
                                         date: day.completedDate ?? cycle.startDate.addingTimeInterval(Double(day.dayIndex) * 60),
                                         program: cycle.template, day: day.dayName, sets: logged,
                                         unit: cycle.weightUnit, isBodyweight: Bodyweight.isBodyweight(exercise.name)))
                }
            }
        }
        found.sort { $0.date < $1.date }
        // Oldest first, so each session is compared with the best before it.
        var best = 0.0
        for index in found.indices {
            let top = found[index].sets
                .filter { $0.completionStatus == .completedSuccessfully }
                .compactMap { set -> Double? in
                    guard let reps = set.reps, reps > 0 else { return nil }
                    let weight = (set.weight ?? 0) + (found[index].isBodyweight ? Bodyweight.referencePounds : 0)
                    return weight > 0 ? PersonalBests.estimatedMax(weight: weight, reps: reps) : nil
                }
                .max() ?? 0
            if top > best + 0.01 {
                found[index].isPB = best > 0
                best = top
            }
        }
        return found.reversed()
    }

    var body: some View {
        let all = sessions
        List {
            if all.isEmpty {
                ContentUnavailableView("No \(lift) yet", systemImage: "list.bullet",
                                       description: Text("Tick off your \(lift) sets and they'll show here."))
            }
            ForEach(all) { session in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(session.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                            .font(.headline)
                        if session.isPB {
                            Label("PB", systemImage: "trophy.fill")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(.yellow))
                        }
                        Spacer()
                        Text(session.program)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(session.sets.map { set in
                        let weight = session.isBodyweight ? Bodyweight.label(added: set.weight) : set.weight.map { WeightConverter.format($0) } ?? "—"
                        let missed = set.completionStatus == .failed ? "✕" : ""
                        return "\(weight)×\(set.reps.map(String.init) ?? "—")\(missed)"
                    }.joined(separator: "   "))
                    .font(.subheadline.monospacedDigit())
                    Text("\(session.day) · \(session.unit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
        }
        .navigationTitle(lift)
        .navigationBarTitleDisplayMode(.inline)
    }
}
