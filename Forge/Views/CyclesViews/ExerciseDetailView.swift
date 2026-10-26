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

struct LastSessionCard: View {
    let session: LastSession?
    let unit: String
    var best: PersonalBests.Best? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let session {
                Text("Last time · \(session.when)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(session.sets.map { "\(WeightConverter.format($0.weight ?? 0)) × \($0.reps ?? 0)" }.joined(separator: "   "))
                    .font(.body.monospacedDigit())
                + Text("  \(unit)").font(.footnote).foregroundStyle(.secondary)
            }
            if let best {
                Label {
                    Text("PB \(WeightConverter.format(best.weight)) × \(best.reps) \(best.usesKilograms ? "kg" : "lbs")")
                    + Text(best.date.map { " · \($0.formatted(.dateTime.month(.abbreviated).day()))" } ?? "")
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "trophy.fill").foregroundStyle(.yellow)
                }
                .font(.subheadline.monospacedDigit())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground)))
        .padding(.horizontal)
        .padding(.bottom, 8)
        .accessibilityElement(children: .combine)
    }
}

/// How to do the lift: one slim row until it's wanted, then short steps in small type.
struct HowToCard: View {
    let name: String
    let guide: LiftGuide
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Button {
                    withAnimation(.snappy) { isExpanded.toggle() }
                } label: {
                    HStack(spacing: 6) {
                        Text("How to")
                            .font(.footnote.weight(.semibold))
                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.semibold))
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(.secondary)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if let url = LiftGuide.videoURL(for: name) {
                    Link(destination: url) {
                        Label("Video", systemImage: "play.fill")
                            .font(.footnote.weight(.medium))
                    }
                }
            }

            if isExpanded {
                ForEach(Array(guide.steps.enumerated()), id: \.offset) { index, step in
                    Text("\(index + 1). \(step)")
                        .font(.footnote)
                }
                Text("Avoid: \(guide.mistake)")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemGroupedBackground)))
        .padding(.horizontal)
        .padding(.bottom, 8)
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
    /// The best this lift had been before today's sets, to spot a new PB.
    @State private var previousBest: PersonalBests.Best?
    @State private var announcedPB: PersistentIdentifier?
    @State private var pbBanner: String?
    @State private var showingHowTo = false

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
                if let lastTime {
                    LastSessionCard(session: lastTime, unit: cycle.weightUnit, best: previousBest)
                } else if let previousBest {
                    LastSessionCard(session: nil, unit: cycle.weightUnit, best: previousBest)
                }
                if let name = exercise?.name, let guide = LiftGuide.guide(for: name) {
                    HowToCard(name: name, guide: guide, isExpanded: $showingHowTo)
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
        .onAppear(perform: loadWeightStep)
        .onChange(of: pbSet(in: sets)?.persistentModelID) { _, id in
            guard let id, id != announcedPB, let set = sets.first(where: { $0.persistentModelID == id }) else { return }
            announcedPB = id
            withAnimation(.spring) {
                pbBanner = "New PB · \(WeightConverter.format(set.weight ?? 0)) × \(set.reps ?? 0) \(cycle.weightUnit)"
            }
            Task {
                try? await Task.sleep(for: .seconds(3))
                withAnimation { pbBanner = nil }
            }
        }
        .overlay(alignment: .top) {
            if let pbBanner {
                Label(pbBanner, systemImage: "trophy.fill")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(.yellow))
                    .shadow(radius: 8, y: 4)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .sensoryFeedback(.success, trigger: pbBanner)
                    .accessibilityAddTraits(.isStaticText)
            }
        }
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
        .environment(\.restSeconds, restSeconds)
        .environment(\.barWeight, bar)
        .environment(\.smallestPlate, smallestPlate)
        .safeAreaInset(edge: .bottom) { RestTimerBar() }
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
            // A PB already logged on this screen earlier isn't announced again.
            announcedPB = pbSet(in: exercise.orderedSets)?.persistentModelID
        }
        weightStart = exercise?.orderedSets.compactMap(\.weight).last ?? lastTime?.topWeight ?? bar
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
