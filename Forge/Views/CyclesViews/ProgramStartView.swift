//
//  ProgramStartView.swift
//  Forge
//
//  Shown after picking a built-in program: what's in it, and (Forge Plus) swapping
//  any lift for a variation before the cycle starts.
//

import SwiftUI

struct ProgramStartView: View {
    let template: Template
    let settings: UserSettings
    /// Called with the chosen swaps, keyed by the program's name for each lift.
    let onStart: ([String: String]) -> Void

    @State private var swaps: [String: String] = [:]
    @State private var showingPlus = false
    @State private var alsoStartRuns = true
    @Environment(\.modelContext) private var context
    private var plus = ForgePlus.shared

    init(template: Template, settings: UserSettings, onStart: @escaping ([String: String]) -> Void) {
        self.template = template
        self.settings = settings
        self.onStart = onStart
    }

    /// The program's lifts, in the order they first appear.
    private var lifts: [String] {
        ExerciseSwaps.lifts(in: template.programType.createProgram(with: settings).generateDays(with: settings))
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label(template.programType.frequency, systemImage: "calendar")
                        .font(.subheadline.weight(.semibold))
                    Text(template.programType.about)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }

            Section {
                ForEach(lifts, id: \.self) { lift in
                    if plus.isActive {
                        NavigationLink {
                            ExerciseSwapPicker(lift: lift, choice: binding(for: lift))
                        } label: {
                            liftRow(lift)
                        }
                    } else {
                        liftRow(lift)
                    }
                }
            } header: {
                Text("Exercises")
            } footer: {
                if plus.isActive {
                    Text(swaps.isEmpty
                         ? "Tap a lift to swap it for a variation. Sets, reps and weights stay as the program sets them."
                         : "Sets, reps and weights stay as the program sets them, so check the weights on swapped lifts.")
                }
            }

            if template.programType == .hybridUpperLower {
                Section {
                    Toggle("Also start Hybrid Runs", isOn: $alsoStartRuns)
                } footer: {
                    Text("Adds the matching running plan to Training › Running: an easy run Tuesday, a tempo run Thursday and a long run Saturday.")
                }
            }

            if !plus.isActive {
                Section {
                    Button {
                        showingPlus = true
                    } label: {
                        HStack {
                            Label("Swap exercises", systemImage: "lock")
                            Spacer()
                            PlusBadge()
                        }
                    }
                } footer: {
                    Text("With Forge Plus, swap any lift for a variation, like Squat for Front Squat.")
                }
            }
        }
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                if template.programType == .hybridUpperLower && alsoStartRuns {
                    context.insert(RunPlanTemplate.hybridRuns.createPlan())
                }
                onStart(swaps)
            } label: {
                Text("Start Cycle")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .navigationDestination(isPresented: $showingPlus) {
            ForgePlusView()
        }
    }

    private func liftRow(_ lift: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(swaps[lift] ?? lift)
            if let swapped = swaps[lift] {
                Text("Instead of \(lift)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("\(swapped), instead of \(lift)")
            }
        }
    }

    private func binding(for lift: String) -> Binding<String> {
        Binding(
            get: { swaps[lift] ?? lift },
            set: { swaps[lift] = $0 == lift ? nil : $0 }
        )
    }
}

/// Pick a variation for one lift: keep it, choose a suggestion, or type any exercise.
private struct ExerciseSwapPicker: View {
    let lift: String
    @Binding var choice: String
    @Environment(\.dismiss) private var dismiss
    @State private var custom = ""

    var body: some View {
        List {
            Section {
                row(lift, detail: "As written in the program")
            }

            let options = ExerciseSwaps.alternatives(for: lift)
            if !options.isEmpty {
                Section("Variations") {
                    ForEach(options, id: \.self) { row($0) }
                }
            }

            Section {
                HStack {
                    TextField("Another exercise", text: $custom)
                        .submitLabel(.done)
                        .onSubmit(useCustom)
                    Button("Use", action: useCustom)
                        .disabled(custom.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            } header: {
                Text("Custom")
            }
        }
        .navigationTitle("Swap \(lift)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            let isOffered = choice == lift || ExerciseSwaps.alternatives(for: lift).contains(choice)
            if !isOffered { custom = choice }
        }
    }

    private func row(_ name: String, detail: String? = nil) -> some View {
        Button {
            choice = name
            dismiss()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name).foregroundStyle(.primary)
                    if let detail {
                        Text(detail).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if choice == name {
                    Image(systemName: "checkmark").foregroundStyle(.tint)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func useCustom() {
        let name = custom.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        choice = name
        dismiss()
    }
}
