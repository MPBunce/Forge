//
//  ExerciseDetailView.swift
//  Forge
//
//  Created by Matthew Bunce on 2025-06-10.
//

import SwiftUI
import SwiftData

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
    @State private var showingAddSetSheet = false
    @State private var editingSet: ExerciseSet? = nil

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
                ExerciseSetsSection(
                    sets: sets,
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
        .environment(\.weightUnit, cycle.weightUnit)
        .environment(\.weightStep, weightStep)
        .environment(\.weightStart, weightStart)
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
    }

    /// A pair of the smallest plates, in the cycle's unit. Read once when the screen opens.
    private func loadWeightStep() {
        let settings = (try? context.fetch(FetchDescriptor<Settings>()))?.first
        let plate = cycle.usesKilograms ? (settings?.smallestPlateKg ?? 1.25) : (settings?.smallestPlateLbs ?? 2.5)
        weightStep = plate * 2
        let bar = cycle.usesKilograms ? (settings?.barbellKg ?? 20) : (settings?.barbellLbs ?? 45)
        weightStart = exercise?.orderedSets.compactMap(\.weight).last ?? lastUsedWeight() ?? bar
    }

    /// The most recent weight logged for this exercise in this cycle.
    private func lastUsedWeight() -> Double? {
        guard let name = exercise?.name else { return nil }
        return cycle.trainingDays
            .sorted { $0.dayIndex > $1.dayIndex }
            .lazy
            .compactMap { day in day.day.first { $0.name == name }?.orderedSets.compactMap(\.weight).last }
            .first
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
        } else {
            set.completionStatus = .notStarted
        }
        editingSet = nil
    }
}
