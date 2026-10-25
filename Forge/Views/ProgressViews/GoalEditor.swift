//
//  GoalEditor.swift
//  Forge
//
//  Forge Plus: add or edit a goal. A goal can tick itself off when a lift reaches a weight.
//

import SwiftUI
import SwiftData

struct GoalEditor: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var settings: [Settings]

    /// Nil to add a new goal.
    let goal: Goal?
    let nextOrder: Int

    @State private var text = ""
    @State private var tracksLift = false
    @State private var lift = TrackedLifts.defaults[0]
    @State private var target = ""

    private var usesKg: Bool { settings.first?.usesKilograms ?? false }
    private var unit: String { usesKg ? "kg" : "lbs" }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("e.g. 20 strict pull-ups", text: $text, axis: .vertical)
                } header: {
                    Text("Goal")
                }

                Section {
                    Toggle("Track a Lift", isOn: $tracksLift)
                    if tracksLift {
                        Picker("Lift", selection: $lift) {
                            ForEach(TrackedLifts.catalog.map(\.name), id: \.self) { Text($0) }
                            Text("Squat + Bench + Deadlift").tag(Goal.totalLift)
                        }
                        HStack {
                            Text("Target")
                            Spacer()
                            TextField("0", text: $target)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 90)
                            Text(unit).foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    Text(tracksLift
                         ? "Ticks itself off when you log a successful set at the target weight."
                         : "You tick this goal off yourself.")
                }
            }
            .navigationTitle(goal == nil ? "New Goal" : "Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!isValid)
                }
            }
            .onAppear(perform: load)
        }
    }

    private var targetValue: Double? {
        Double(target.replacingOccurrences(of: ",", with: ".")).flatMap { $0 > 0 ? $0 : nil }
    }

    private var isValid: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (!tracksLift || targetValue != nil)
    }

    private func load() {
        guard let goal else { return }
        text = goal.goal
        if let auto = goal.autoLift, let lbs = goal.targetLbs {
            tracksLift = true
            lift = auto
            target = WeightConverter.format(usesKg ? (WeightConverter.lbsToKg(lbs) * 2).rounded() / 2 : lbs)
        }
    }

    private func save() {
        let target = tracksLift ? targetValue.map { usesKg ? WeightConverter.kgToLbs($0) : $0 } : nil
        let edited = goal ?? {
            let new = Goal(goal: "", order: nextOrder)
            context.insert(new)
            return new
        }()
        edited.goal = text.trimmingCharacters(in: .whitespacesAndNewlines)
        edited.autoLift = tracksLift ? lift : nil
        edited.targetLbs = target
        dismiss()
    }
}
