//
//  ExerciseDetailView.swift
//  Forge
//
//  Created by Matthew Bunce on 2025-06-10.
//

import SwiftUI
import SwiftData

/// What was lifted the last time this exercise came up, to aim to beat it.
struct LastSession {
    let sets: [ExerciseSet]
    let when: String

    var topWeight: Double? { sets.compactMap(\.weight).max() }
}

/// Forge Plus: a note on a lift, shown every time it comes up.
private struct NoteEditor: View {
    @Environment(\.dismiss) private var dismiss
    let name: String
    @State var text: String
    let onSave: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Seat at 4, left shoulder: go light…", text: $text, axis: .vertical)
                        .lineLimit(3...8)
                } footer: {
                    Text("Shows every time \(name) comes up, in any cycle.")
                }
            }
            .navigationTitle("Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(text); dismiss() }.fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Main Exercise Detail View
// Changes are written straight to the model as they happen, like the set status taps,
// so there is no separate Save step that could be skipped or half-applied.
struct ExerciseDetailView: View {
    let cycle: Cycles
    let dayIndex: Int
    let exerciseIndex: Int

    @Environment(\.modelContext) private var context
    @State private var weightStep: Double = 5
    @State private var weightStart: Double = 45
    @State private var restSeconds = RestTimer.defaultSeconds
    @State private var bar: Double = 45
    @State private var smallestPlate: Double = 2.5
    @State private var showingAddSetSheet = false
    @State private var editingSet: ExerciseSet? = nil
    @State private var lastTime: LastSession? = nil
    /// The weight last logged for this lift, anywhere.
    @State private var lastWeight: Double?
    /// Last time every set reached the top of its range, so the weight has gone up.
    @State private var movedUpFrom: Double?
    @State private var note: String?
    @State private var editingNote = false
    @State private var showingPlus = false
    private var plus = ForgePlus.shared
    /// The best this lift had been before today's sets, to spot a new PB.
    @State private var previousBest: PersonalBests.Best?

    private var exercise: Exercise? {
        cycle.trainingDays
            .first(where: { $0.dayIndex == dayIndex })?
            .day.first(where: { $0.exerciseIndex == exerciseIndex })
    }

    var body: some View {
        let sets = exercise?.orderedSets ?? []
        let canAlterSets = exercise?.canAlterSets ?? false

        ScrollView {
            LazyVStack(spacing: 0) {
                if let note {
                    Button { editingNote = true } label: {
                        Label(note, systemImage: "note.text")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    .padding(.bottom, 6)
                }
                if let line = progressionLine(sets) {
                    Label(line, systemImage: "arrow.up.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.bottom, 6)
                }
                if plus.isActive, let steps = warmUp(sets), !steps.isEmpty {
                    Text("Warm-up  " + steps.map { "\(WeightConverter.format($0.weight))×\($0.reps)" }.joined(separator: " · "))
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.bottom, 4)
                        .accessibilityLabel("Warm-up sets: " + steps.map { "\(WeightConverter.format($0.weight)) for \($0.reps)" }.joined(separator: ", "))
                }
                ExerciseSetsSection(
                    sets: sets,
                    pbSetID: pbSet(in: sets)?.persistentModelID,
                    showingAddSetSheet: $showingAddSetSheet,
                    canAlterSets: canAlterSets,
                    onDeleteSet: { set in deleteSet(set) },
                    onEditSet: { set in editingSet = set }
                )
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(exercise?.name ?? "")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if plus.isActive { editingNote = true } else { showingPlus = true }
                } label: {
                    Image(systemName: note == nil ? "note.text.badge.plus" : "note.text")
                }
                .accessibilityLabel(note == nil ? "Add a note" : "Edit note")
            }
        }
        .sheet(isPresented: $editingNote) {
            NoteEditor(name: exercise?.name ?? "", text: note ?? "") { saved in
                ExerciseNotes.setNote(saved, for: exercise?.name ?? "")
                note = ExerciseNotes.note(for: exercise?.name ?? "")
            }
        }
        .sheet(isPresented: $showingPlus) {
            NavigationStack { ForgePlusView() }
        }
        .onAppear(perform: loadWeightStep)
        .sheet(isPresented: $showingAddSetSheet) {
            AddSetView { weight, reps in
                addSet(weight: weight, reps: reps)
            }
        }
        .sheet(item: $editingSet) { set in
            EditSetSheetView(
                set: set,
                onUpdateAmrap: { reps, weight in updateAmrapSet(set, reps: reps, weight: weight) },
                onUpdateRegular: { weight, reps in
                    set.weight = weight
                    set.reps = reps
                    editingSet = nil
                },
                onCancel: { editingSet = nil }
            )
        }
        // After the sheets, so the set editor sees these too.
        .environment(\.weightUnit, cycle.weightUnit)
        .environment(\.weightStep, weightStep)
        .environment(\.weightStart, weightStart)
        .environment(\.lastWeight, currentLastWeight)
        .environment(\.isBodyweight, isBodyweight)
        .environment(\.showsRepRanges, progressionMode == .ranges)
        .environment(\.restSeconds, restSeconds)
        .environment(\.barWeight, bar)
        .environment(\.smallestPlate, smallestPlate)
        .safeAreaInset(edge: .bottom) { RestTimerBar() }
    }

    private var isBodyweight: Bool { Bodyweight.isBodyweight(exercise?.name ?? "") }
    private var usesRepRanges: Bool { Progression.usesRepRanges(cycle) }

    private var progressionMode: Progression.Mode? { Progression.mode(for: exercise, in: cycle) }

    /// Progression news: going up today, or earned it with today's sets.
    private func progressionLine(_ sets: [ExerciseSet]) -> String? {
        guard let mode = progressionMode else { return nil }
        if Progression.earnedIncrease(sets, mode: mode) {
            return mode == .ranges ? "Top of the range on every set. Go up next time."
                                   : "Every set done. Go up next time."
        }
        if let from = movedUpFrom, !sets.contains(where: { $0.completionStatus != .notStarted }) {
            return isBodyweight
                ? "You hit the top of the range last time, so add a little weight today."
                : "Up from \(WeightConverter.format(from)) \(cycle.weightUnit): you got every rep last time."
        }
        return nil
    }

    /// Plus: ramp-up sets before the working weight, on the day's main lifts.
    private func warmUp(_ sets: [ExerciseSet]) -> [WarmUp.Step]? {
        guard let exercise, !isBodyweight, exercise.exerciseIndex <= 1 else { return nil }
        let working = sets.compactMap(\.weight).max() ?? currentLastWeight ?? 0
        guard working > 0 else { return nil }
        return WarmUp.steps(to: working, bar: bar, smallest: smallestPlate, isBarbell: WarmUp.isBarbell(exercise.name))
    }

    /// The last weight logged for this lift: earlier in today's sets, or in an earlier session.
    private var currentLastWeight: Double? {
        let doneToday = (exercise?.orderedSets ?? []).filter { $0.completionStatus != .notStarted }
        return doneToday.compactMap(\.weight).last ?? lastWeight
    }

    /// The set in this session that beats the lift's previous best, if one does.
    private func pbSet(in sets: [ExerciseSet]) -> ExerciseSet? {
        PersonalBests.newBest(among: sets, usesKilograms: cycle.usesKilograms, previous: previousBest)
    }

    /// A pair of the smallest plates, in the cycle's unit. Read once when the screen opens.
    private func loadWeightStep() {
        let settings = (try? context.fetch(FetchDescriptor<Settings>()))?.first
        let plate = cycle.usesKilograms ? (settings?.smallestPlateKg ?? 1.25) : (settings?.smallestPlateLbs ?? 2.5)
        weightStep = plate * 2
        smallestPlate = plate
        RestTimer.migrateDefault(settings)
        restSeconds = settings?.defaultRestTime ?? RestTimer.defaultSeconds
        let bar = cycle.usesKilograms ? (settings?.barbellKg ?? 20) : (settings?.barbellLbs ?? 45)
        self.bar = bar
        lastTime = findLastSession()
        if let exercise {
            let all = (try? context.fetch(FetchDescriptor<Cycles>())) ?? []
            previousBest = PersonalBests.best(for: exercise.name, in: all,
                                              excluding: Set(exercise.sets.map(\.persistentModelID)))
            note = ExerciseNotes.note(for: exercise.name)
            if let last = LastWeight.lastSession(for: exercise, in: all, usesKilograms: cycle.usesKilograms) {
                lastWeight = last.weight
                // Double progression: every set at the top of its range last time, so go up a step.
                // Judged by the rules of the cycle that session was in, so a 5/3/1 AMRAP
                // never counts as topping out a rep range.
                if progressionMode != nil,
                   let lastMode = Progression.mode(for: last.sets.first?.exercise, in: last.cycle),
                   Progression.earnedIncrease(last.sets, mode: lastMode) {
                    movedUpFrom = last.weight
                    lastWeight = last.weight + weightStep
                }
            }
        }
        // Bodyweight lifts start at no added weight, not an empty bar.
        weightStart = currentLastWeight ?? exercise?.orderedSets.compactMap(\.weight).last ?? lastTime?.topWeight
            ?? (isBodyweight ? 0 : bar)
    }

    /// The most recent earlier time this exercise was logged: earlier days in this cycle,
    /// then earlier cycles in the same unit, so a new cycle picks up where the last one left off.
    private func findLastSession() -> LastSession? {
        guard let name = exercise?.name else { return nil }
        let logged: (Exercise) -> [ExerciseSet] = { $0.orderedSets.filter { $0.weight != nil && $0.reps != nil } }

        let earlierDays = cycle.trainingDays
            .filter { $0.dayIndex < dayIndex }
            .sorted { $0.dayIndex > $1.dayIndex }
        for day in earlierDays {
            if let match = day.day.first(where: { $0.name == name }), !logged(match).isEmpty {
                return LastSession(sets: logged(match), when: day.completedDate.map(Self.short) ?? day.dayName)
            }
        }

        let start = cycle.startDate
        let descriptor = FetchDescriptor<Cycles>(
            predicate: #Predicate { $0.startDate < start },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        let earlier = (try? context.fetch(descriptor)) ?? []
        for past in earlier where past.usesKilograms == cycle.usesKilograms {
            for day in past.trainingDays.sorted(by: { $0.dayIndex > $1.dayIndex }) {
                if let match = day.day.first(where: { $0.name == name }), !logged(match).isEmpty {
                    return LastSession(sets: logged(match), when: Self.short(day.completedDate ?? past.startDate))
                }
            }
        }
        return nil
    }

    private static func short(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day())
    }

    private func addSet(weight: Double?, reps: Int?) {
        guard let exercise, exercise.canAlterSets else { return }

        let nextIndex = (exercise.sets.map { $0.setIndex }.max() ?? -1) + 1
        let newSet = ExerciseSet(
            setIndex: nextIndex,
            weight: weight,
            reps: reps,
            isEditable: true,
            completionStatus: .notStarted
        )
        withAnimation(.spring()) {
            exercise.sets.append(newSet)
        }
    }

    private func deleteSet(_ set: ExerciseSet) {
        guard let exercise, exercise.canAlterSets else { return }

        withAnimation(.spring()) {
            exercise.sets.removeAll { $0 === set }
            context.delete(set)
            for (i, remaining) in exercise.orderedSets.enumerated() {
                remaining.setIndex = i
            }
        }
    }

    private func updateAmrapSet(_ set: ExerciseSet, reps: Int?, weight: Double?) {
        set.reps = reps
        set.weight = weight
        // Hitting the target counts as a success; falling short is a fail.
        if let reps {
            if let target = set.amrapTargetReps, reps < target {
                set.completionStatus = .failed
            } else {
                set.completionStatus = .completedSuccessfully
            }
            RestTimer.shared.startIfEnabled(seconds: restSeconds)
        } else {
            set.completionStatus = .notStarted
        }
        editingSet = nil
    }
}
