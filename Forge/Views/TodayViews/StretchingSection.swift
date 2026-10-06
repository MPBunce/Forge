//
//  StretchingSection.swift
//  Forge
//

import SwiftUI
import SwiftData

struct StretchingSection: View {
    @Environment(\.modelContext) private var context
    @Query private var entries: [StretchEntry]
    /// Chosen routine IDs, newline-separated, in the order they were added.
    @AppStorage(PreferenceKeys.stretchRoutines) private var chosenStorage = ""
    @State private var showingPicker = false
    @State private var openRoutine: StretchRoutine?

    private let day: Date

    init(day: Date) {
        self.day = day
        _entries = Query(filter: #Predicate<StretchEntry> { $0.day == day })
    }

    private var chosen: [StretchRoutine] {
        chosenStorage.split(separator: "\n").compactMap { StretchRoutine.routine(id: String($0)) }
    }

    var body: some View {
        Section {
            if chosen.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pick a stretching routine to do each day and tick it off when you're done.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Choose a Routine") { showingPicker = true }
                }
                .padding(.vertical, 4)
            }
            ForEach(chosen) { routine in
                StretchRoutineRow(
                    routine: routine,
                    isDone: isDone(routine),
                    onToggle: { toggle(routine) },
                    onOpen: { openRoutine = routine }
                )
            }
        } header: {
            HStack {
                Text("Stretching")
                Spacer()
                if !chosen.isEmpty {
                    Button("Edit") { showingPicker = true }
                        .font(.subheadline)
                        .textCase(nil)
                }
            }
            .sheet(isPresented: $showingPicker) {
                StretchRoutinePicker(chosenStorage: $chosenStorage)
            }
            .sheet(item: $openRoutine) { routine in
                StretchRoutineDetail(routine: routine, isDone: isDone(routine)) { toggle(routine) }
            }
        }
    }

    private func isDone(_ routine: StretchRoutine) -> Bool {
        entries.contains { $0.routineID == routine.id }
    }

    private func toggle(_ routine: StretchRoutine) {
        withAnimation {
            if let existing = entries.first(where: { $0.routineID == routine.id }) {
                context.delete(existing)
            } else {
                context.insert(StretchEntry(routineID: routine.id, day: day))
            }
        }
    }
}

private struct StretchRoutineRow: View {
    let routine: StretchRoutine
    let isDone: Bool
    let onToggle: () -> Void
    let onOpen: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isDone ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isDone ? "Mark \(routine.name) not done" : "Mark \(routine.name) done")

            Button(action: onOpen) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(routine.name)
                            .foregroundStyle(.primary)
                        Text("\(routine.stretches.count) stretches · ~\(routine.minutes) min")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

/// The stretches in a routine: tap one for how to do it, or follow along through all of them.
private struct StretchRoutineDetail: View {
    @Environment(\.dismiss) private var dismiss
    let routine: StretchRoutine
    let isDone: Bool
    let onToggle: () -> Void
    @State private var followingAlong = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        followingAlong = true
                    } label: {
                        Label("Follow Along", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                } footer: {
                    Text("Goes through each stretch one at a time, with the steps and a timer.")
                }

                Section {
                    ForEach(Array(routine.stretches.enumerated()), id: \.offset) { index, stretch in
                        NavigationLink {
                            StretchDetailView(stretch: stretch, number: index + 1)
                        } label: {
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .frame(width: 20)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(stretch.name)
                                    Text(stretch.hold + (stretch.sides == 2 && !stretch.hold.contains("each") ? " each side" : ""))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Stretches")
                } footer: {
                    Text(["Tap a stretch to see how to do it.", routine.summary + ". About \(routine.minutes) minutes.", routine.source]
                        .filter { !$0.isEmpty }
                        .joined(separator: "\n\n"))
                }

                Section {
                    Button {
                        onToggle()
                        dismiss()
                    } label: {
                        Label(isDone ? "Mark Not Done" : "Mark Done",
                              systemImage: isDone ? "arrow.uturn.backward" : "checkmark.circle.fill")
                    }
                }
            }
            .navigationTitle(routine.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
            .fullScreenCover(isPresented: $followingAlong) {
                StretchFollowAlong(routine: routine) {
                    if !isDone { onToggle() }
                }
            }
        }
    }
}

/// Choose which routines appear on the Today tab.
private struct StretchRoutinePicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var chosenStorage: String

    private var chosenIDs: [String] {
        chosenStorage.split(separator: "\n").map(String.init)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(StretchRoutine.standalone) { routine in
                        routineRow(routine)
                    }
                }
                Section {
                    ForEach(StartingStretching.levels) { routine in
                        routineRow(routine)
                    }
                } header: {
                    Text("Starting Stretching")
                } footer: {
                    Text("Pick the level that fits you; choosing one replaces the other. Chosen routines show on the Today tab every day.")
                }
            }
            .navigationTitle("Stretching Routines")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func routineRow(_ routine: StretchRoutine) -> some View {
        let isChosen = chosenIDs.contains(routine.id)
        return Button {
            toggle(routine.id)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isChosen ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isChosen ? Color.accentColor : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(routine.name)
                        .foregroundStyle(.primary)
                    Text("\(routine.summary) · ~\(routine.minutes) min")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .tint(.primary)
    }

    private func toggle(_ id: String) {
        var ids = chosenIDs
        if let index = ids.firstIndex(of: id) {
            ids.remove(at: index)
        } else {
            // Only one Starting Stretching level at a time.
            if StartingStretching.isLevel(id) {
                ids.removeAll(where: StartingStretching.isLevel)
            }
            ids.append(id)
        }
        chosenStorage = ids.joined(separator: "\n")
    }
}
