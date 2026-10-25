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

struct NextCycleSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var settings: [Settings]

    let template: Template
    var onStart: () -> Void = {}

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
                            }
                        }
                    } header: {
                        Text("New Training Maxes")
                    } footer: {
                        Text("The standard progression: +\(WeightConverter.format(step)) \(unit) on bench and press, +\(WeightConverter.format(step * 2)) \(unit) on squat and deadlift. If you missed reps on a lift's last set, keep it where it was.")
                    }
                } else {
                    Section {
                        Text("Start a fresh copy of \(template.name). Your weights from this cycle show as \"Last time\" on each exercise.")
                            .foregroundStyle(.secondary)
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
            previous[lift] = current(lift)
            maxes[lift] = current(lift) + (lift.isLower ? step * 2 : step)
        }
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
        context.insert(template.createCycle(with: UserSettings(from: s)))
        try? context.save()
        onStart()
        dismiss()
    }
}

/// Shown at the top of a finished cycle.
struct CycleFinishedBanner: View {
    let template: Template
    var onStart: () -> Void

    @State private var showingNext = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Cycle complete", systemImage: "checkmark.seal.fill")
                .font(.headline)
                .foregroundStyle(.green)
            Text(template.programType.usesTrainingMaxes
                 ? "Raise your training maxes and start the next cycle."
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
            NextCycleSheet(template: template, onStart: onStart)
        }
    }
}
