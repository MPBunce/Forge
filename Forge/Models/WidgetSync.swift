//
//  WidgetSync.swift
//  Forge
//
//  Keeps the streak widgets up to date: saves each habit's completed days to the
//  App Group when the app opens and when it goes to the background.
//

import SwiftUI
import SwiftData
import WidgetKit

private struct WidgetSyncModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(PreferenceKeys.hasSeenSplash) private var hasSeenSplash = false

    @Query private var cycles: [Cycles]
    @Query private var runPlans: [RunPlan]
    @Query private var races: [RaceResult]
    @Query private var singleRuns: [LoggedRun]
    @Query private var dailyItems: [DailyWorkItem]
    @Query private var dailyEntries: [DailyWorkEntry]
    @Query private var stretchEntries: [StretchEntry]
    @Query private var settings: [Settings]

    @State private var stepsByDay: [Date: Int] = [:]
    @State private var stepCounter = StepCounter()

    func body(content: Content) -> some View {
        content
            // Steps need Health access, so wait until the first-launch quote has gone.
            .task(id: hasSeenSplash) {
                guard hasSeenSplash else { return }
                await loadSteps()
                save()
            }
            // Mark Done anywhere updates the Next Workout widget straight away.
            .onChange(of: nextWorkout) { _, workout in
                if NextWorkoutSnapshot.save(workout) {
                    WidgetCenter.shared.reloadTimelines(ofKind: "ForgeNextWorkout")
                }
            }
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .background, .inactive:
                    save()
                case .active:
                    guard hasSeenSplash else { return }
                    Task {
                        await loadSteps()
                        save()
                    }
                @unknown default:
                    break
                }
            }
    }

    private func loadSteps() async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let start = calendar.date(byAdding: .day, value: -ActivitySnapshot.historyDays, to: today),
              let end = calendar.date(byAdding: .day, value: 1, to: today) else { return }
        stepsByDay = await stepCounter.dailySteps(from: start, to: end)
    }

    /// The next lifting day of the newest unfinished cycle (or the one finished today).
    private var nextWorkout: NextWorkoutSnapshot? {
        let calendar = Calendar.current
        let sorted = cycles.sorted { $0.startDate > $1.startDate }
        func doneToday(_ cycle: Cycles) -> Bool {
            cycle.trainingDays.contains { $0.completedDate.map(calendar.isDateInToday) ?? false }
        }
        guard let cycle = sorted.first(where: { !$0.isCompleted || doneToday($0) }) else { return nil }
        guard let day = cycle.nextDay else {
            // Finished today: nothing left in this cycle.
            return NextWorkoutSnapshot(program: cycle.template, dayName: "Cycle complete", exercises: [], doneToday: true)
        }
        return NextWorkoutSnapshot(program: cycle.template, dayName: day.dayName,
                                   exercises: day.day.sorted { $0.exerciseIndex < $1.exerciseIndex }.map(\.name),
                                   doneToday: doneToday(cycle))
    }

    private func save() {
        if NextWorkoutSnapshot.save(nextWorkout) {
            WidgetCenter.shared.reloadTimelines(ofKind: "ForgeNextWorkout")
        }
        let records = ActivityRecords(cycles: cycles, runPlans: runPlans, races: races, singleRuns: singleRuns,
                                      dailyItems: dailyItems, dailyEntries: dailyEntries,
                                      stretchEntries: stretchEntries, stepsByDay: stepsByDay,
                                      stepGoal: settings.first?.dailyStepGoal ?? 10000)
        let cutoff = Calendar.current.date(byAdding: .day, value: -ActivitySnapshot.historyDays, to: Date()) ?? .distantPast
        var snapshot = ActivitySnapshot()
        for metric in ActivityMetric.allCases {
            snapshot.days[metric] = records.completedDays(for: metric).filter { $0 >= cutoff }.sorted()
        }
        if snapshot.save() {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}

extension View {
    /// Saves habit history for the streak widgets.
    func syncsActivityWidgets() -> some View {
        modifier(WidgetSyncModifier())
    }
}
