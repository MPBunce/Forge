//
//  TrainingSection.swift
//  Forge
//
//  Today's lift and run: the next day of the current strength cycle and the next run of
//  the current running plan, or what was finished today.
//

import SwiftUI
import SwiftData

struct TrainingSection: View {
    @Query(sort: \Cycles.startDate, order: .reverse) private var cycles: [Cycles]
    @Query(sort: \RunPlan.startDate, order: .reverse) private var plans: [RunPlan]

    let day: Date

    /// The newest cycle that isn't finished, or one finished today.
    private var cycle: Cycles? {
        cycles.first { !$0.isCompleted || doneToday($0) != nil }
    }

    private var plan: RunPlan? {
        plans.first { !$0.isCompleted || runDoneToday($0) != nil }
    }

    var body: some View {
        if cycle != nil || plan != nil {
            Section("Training") {
                if let cycle { liftRow(cycle) }
                if let plan { runRow(plan) }
            }
        }
    }

    private func liftRow(_ cycle: Cycles) -> some View {
        let finished = doneToday(cycle)
        let shown = finished ?? cycle.nextDay
        return NavigationLink {
            CyclesDetailView(cycleId: cycle.id)
        } label: {
            TrainingRow(icon: "dumbbell.fill", tint: .blue,
                        title: shown?.dayName ?? cycle.template,
                        detail: "\(cycle.template) · \(shown?.day.count ?? 0) exercises",
                        isDone: finished != nil)
        }
    }

    private func runRow(_ plan: RunPlan) -> some View {
        let finished = runDoneToday(plan)
        let shown = finished ?? plan.nextSession
        return NavigationLink {
            RunPlanDetailView(plan: plan)
        } label: {
            TrainingRow(icon: "figure.run", tint: .orange,
                        title: shown?.title ?? plan.name,
                        detail: [plan.name, shown?.summary].compactMap { $0 }.joined(separator: " · "),
                        isDone: finished != nil)
        }
    }

    private func doneToday(_ cycle: Cycles) -> TrainingDay? {
        cycle.trainingDays.first { $0.completedDate.map { Calendar.current.isDate($0, inSameDayAs: day) } ?? false }
    }

    private func runDoneToday(_ plan: RunPlan) -> RunSession? {
        plan.sessions.first { $0.completedDate.map { Calendar.current.isDate($0, inSameDayAs: day) } ?? false }
    }
}

private struct TrainingRow: View {
    let icon: String
    let tint: Color
    let title: String
    let detail: String
    let isDone: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isDone ? "checkmark.circle.fill" : icon)
                .font(.title3)
                .foregroundStyle(isDone ? .green : tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(isDone ? "Done today" : "Up next")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(isDone ? .green : tint)
                    .textCase(.uppercase)
                Text(title)
                    .font(.body.weight(.medium))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}
