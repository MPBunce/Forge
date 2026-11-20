//
//  NextCycleSheet.swift
//  Forge
//
//  Starts the next cycle of a finished program. Programs built on training maxes (5/3/1,
//  nSuns) raise them first: 5 lb on bench and press, 10 lb on squat and deadlift.
//

import SwiftUI
import SwiftData

extension ProgramType {
    var usesTrainingMaxes: Bool {
        switch self {
        case .fiveThreeOneBasicProgram, .fiveThreeOneBBBProgram,
             .nSuns4Days, .nSuns5Days, .nSuns6DaysSquat, .nSuns6DaysDeadlift: true
        default: false
        }
    }
}

extension Template {
    /// The built-in program a cycle was started from, if it still exists.
    static func named(_ name: String) -> Template? {
        loadTemplates().first { $0.name == name }
    }
}

/// How much to raise a training max, from the finished cycle's AMRAP sets.
/// 5/3/1: the standard increase if you got the reps on the + sets, otherwise hold.
/// nSuns: by reps on the heaviest + set: 0–1 hold, 2–3 a little, 4–5 more, 6+ the most.
enum TrainingMaxSuggestion {
    struct Suggestion: Equatable {
        let increase: Double
        let reason: String
    }

    /// Names each lift goes by in the programs (normalised).
    static func keys(for lift: NextCycleSheet.Lift) -> Set<String> {
        switch lift {
        case .squat: ["squat"]
        case .bench: ["benchpress", "bench"]
        case .deadlift: ["deadlift"]
        case .press: ["overheadpress", "press", "ohp"]
        }
    }

    static func suggest(for lift: NextCycleSheet.Lift, cycle: Cycles?, program: ProgramType, step: Double) -> Suggestion {
        let small = step
        let large = lift.isLower ? step * 2 : step
        let standard = Suggestion(increase: large, reason: "Standard increase")
        guard let cycle else { return standard }
        let keys = keys(for: lift)
        // The training-max sets for this lift: + sets with reps logged.
        let plusSets = cycle.trainingDays.flatMap(\.day)
            .filter { !$0.canAlterSets && keys.contains(PersonalBests.key($0.name)) }
            .flatMap(\.sets)
            .filter { $0.isAmrap && $0.amrapTargetReps != nil && $0.completionStatus != .notStarted && $0.reps != nil }
        guard let top = plusSets.max(by: { ($0.weight ?? 0, $0.reps ?? 0) < ($1.weight ?? 0, $1.reps ?? 0) }),
              let reps = top.reps, let target = top.amrapTargetReps else {
            return Suggestion(increase: large, reason: "No + sets logged, so the standard increase")
        }
        let at = top.weight.map { " at \(WeightConverter.format($0))" } ?? ""
        let done = "\(reps) reps on the \(target)+ set\(at)"
        switch program {
        case .nSuns4Days, .nSuns5Days, .nSuns6DaysSquat, .nSuns6DaysDeadlift:
            if reps <= 1 { return Suggestion(increase: 0, reason: "\(done): hold") }
            if reps <= 3 { return Suggestion(increase: small, reason: done) }
            if reps <= 5 { return Suggestion(increase: large, reason: done) }
            return Suggestion(increase: lift.isLower ? step * 3 : step * 2, reason: done)
        default:
            if reps < target { return Suggestion(increase: 0, reason: "\(done): missed, so hold") }
            return Suggestion(increase: large, reason: done)
        }
    }
}

struct NextCycleSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var settings: [Settings]
    @Query private var cycles: [Cycles]

    let template: Template
    /// The finished cycle, to base the increases on.
    var cycle: Cycles? = nil
    var onStart: () -> Void = {}
    @State private var reasons: [Lift: String] = [:]

    /// New training maxes in the lifter's unit, keyed by lift.
    @State private var maxes: [Lift: Double] = [:]
    /// The maxes before this sheet changed them, captured once so they don't jump on save.
    @State private var previous: [Lift: Double] = [:]

    enum Lift: String, CaseIterable, Identifiable {
        case squat = "Squat", bench = "Bench Press", deadlift = "Deadlift", press = "Overhead Press"
        var id: Self { self }
        var isLower: Bool { self == .squat || self == .deadlift }
    }

    private var userSettings: Settings? { settings.first }
    private var usesKg: Bool { userSettings?.usesKilograms ?? false }
    private var unit: String { usesKg ? "kg" : "lbs" }
    private var step: Double { usesKg ? 2.5 : 5 }

    var body: some View {
        NavigationStack {
            List {
                if template.programType.usesTrainingMaxes {
                    Section {
                        ForEach(Lift.allCases) { lift in
                            Stepper(value: binding(for: lift), in: 0...2000, step: step) {
                                VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(lift.rawValue)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    Spacer(minLength: 4)
                                    Text("\(WeightConverter.format(previous[lift] ?? 0)) → ")
                                        .foregroundStyle(.secondary)
                                    + Text("\(WeightConverter.format(maxes[lift] ?? 0)) \(unit)")
                                        .fontWeight(.semibold)
                                }
                                .monospacedDigit()
                                .lineLimit(1)
                                if let reason = reasons[lift] {
                                    Text(reason)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                }
                            }
                        }
                    } header: {
                        Text("New Training Maxes")
                    } footer: {
                        Text("Suggested from your + sets this cycle. Adjust any of them before you start.")
                    }
                } else {
                    Section {
                        Text("Start a fresh copy of \(template.name). Each exercise starts from the weight you used last.")
                            .foregroundStyle(.secondary)
                    }
                }
                if !carriedSwaps.isEmpty {
                    Section {
                        ForEach(carriedSwaps.sorted(by: { $0.key < $1.key }), id: \.key) { was, now in
                            LabeledContent(now) {
                                Text("instead of \(was)").foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        Text("Your swaps carry over")
                    }
                }
            }
            .navigationTitle("Next Cycle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") { start() }.fontWeight(.semibold)
                }
            }
            .onAppear(perform: load)
        }
        .presentationDetents([.medium, .large])
    }

    private func current(_ lift: Lift) -> Double {
        guard let s = userSettings else { return 0 }
        let lbs: Double = switch lift {
        case .squat: s.squatMax
        case .bench: s.benchPressMax
        case .deadlift: s.deadliftMax
        case .press: s.overheadPressMax
        }
        return usesKg ? (WeightConverter.lbsToKg(lbs) * 2).rounded() / 2 : lbs
    }

    private func binding(for lift: Lift) -> Binding<Double> {
        Binding(get: { maxes[lift] ?? 0 }, set: { maxes[lift] = $0 })
    }

    private func load() {
        guard maxes.isEmpty else { return }
        for lift in Lift.allCases {
            let suggestion = TrainingMaxSuggestion.suggest(for: lift, cycle: cycle, program: template.programType, step: step)
            previous[lift] = current(lift)
            maxes[lift] = current(lift) + suggestion.increase
            reasons[lift] = suggestion.reason
        }
    }

    private var carriedSwaps: [String: String] {
        guard let s = userSettings else { return [:] }
        return ExerciseSwaps.lastUsed(for: template, in: cycles, settings: UserSettings(from: s))
    }

    private func start() {
        let s = userSettings ?? {
            let new = Settings.defaultSettings
            context.insert(new)
            return new
        }()
        if template.programType.usesTrainingMaxes {
            let toLbs: (Double) -> Double = usesKg ? WeightConverter.kgToLbs : { $0 }
            s.squatMax = toLbs(maxes[.squat] ?? 0)
            s.benchPressMax = toLbs(maxes[.bench] ?? 0)
            s.deadliftMax = toLbs(maxes[.deadlift] ?? 0)
            s.overheadPressMax = toLbs(maxes[.press] ?? 0)
        }
        // Swaps come from the cycle as it stood, before the maxes above changed.
        let swaps = carriedSwaps
        context.insert(template.createCycle(with: UserSettings(from: s), swaps: swaps))
        try? context.save()
        onStart()
        dismiss()
    }
}

/// Shown at the top of a finished cycle.
struct CycleFinishedBanner: View {
    let template: Template
    var cycle: Cycles? = nil
    var onStart: () -> Void

    @State private var showingNext = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Cycle complete", systemImage: "checkmark.seal.fill")
                .font(.headline)
                .foregroundStyle(.green)
            Text(template.programType.usesTrainingMaxes
                 ? "See how much to raise each training max, then start the next cycle."
                 : "Start the next round of \(template.name).")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                showingNext = true
            } label: {
                Text("Start Next Cycle")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
        }
        .padding(.vertical, 6)
        .sheet(isPresented: $showingNext) {
            NextCycleSheet(template: template, cycle: cycle, onStart: onStart)
        }
    }
}
