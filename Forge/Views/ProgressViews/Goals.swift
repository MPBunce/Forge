import SwiftUI
import SwiftData

struct GoalsView: View {
    @Environment(\.modelContext) var context
    @Query(sort: \Goal.order) var goals: [Goal]
    @Query private var cycles: [Cycles]
    @State private var editing: Goal?
    @State private var adding = false
    @State private var showingPlus = false
    private var plus = ForgePlus.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Strength Goals")
                        .font(.title2)
                        .bold()
                    Text("Lift goals tick themselves off when you log a set at the target weight. Tick the rest off yourself.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)
                
                // Goals List
                LazyVStack(spacing: 12) {
                    ForEach(goals) { goal in
                        goalRow(for: goal)
                            .contextMenu {
                                if plus.isActive {
                                    Button("Edit", systemImage: "pencil") { editing = goal }
                                    Button("Delete", systemImage: "trash", role: .destructive) {
                                        context.delete(goal)
                                    }
                                }
                            }
                    }
                    addGoalButton
                }

                RunningGoalsSection()
            }
            .padding()
        }
        .onAppear {
            initializeDefaultGoalsIfNeeded()
            removeDuplicateGoals()
            checkAutoGoals()
        }
        .sheet(isPresented: $adding) {
            GoalEditor(goal: nil, nextOrder: (goals.map(\.order).max() ?? -1) + 1)
        }
        .sheet(item: $editing) { goal in
            GoalEditor(goal: goal, nextOrder: goal.order)
        }
        .sheet(isPresented: $showingPlus) {
            NavigationStack { ForgePlusView() }
        }
    }

    /// Forge Plus: add your own goal. Long-press a goal to edit or delete it.
    private var addGoalButton: some View {
        Button {
            if plus.isActive { adding = true } else { showingPlus = true }
        } label: {
            HStack {
                Label("Add Goal", systemImage: plus.isActive ? "plus" : "lock")
                Spacer()
                if !plus.isActive { PlusBadge() }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    /// Two devices can each create the default goals before iCloud syncs them together.
    /// Keep one of each, preferring the one that's ticked off.
    private func removeDuplicateGoals() {
        var kept: [String: Goal] = [:]
        for goal in goals {
            guard let other = kept[goal.goal] else { kept[goal.goal] = goal; continue }
            let keep = goal.isCompleted && !other.isCompleted ? goal : other
            context.delete(keep === goal ? other : goal)
            kept[goal.goal] = keep
        }
    }
    
    // MARK: - Goal Row View
    @ViewBuilder
    private func goalRow(for goal: Goal) -> some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: {
                toggleGoalCompletion(goal)
            }) {
                Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(goal.isCompleted ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Goal text
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.goal)
                    .font(.body)
                    .strikethrough(goal.isCompleted)
                    .foregroundColor(goal.isCompleted ? .secondary : .primary)
                
                if goal.isCompleted, let completionDate = goal.completionDate {
                    Text("Completed on \(completionDate, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(.green)
                } else if goal.isAutoTracked, let target = goal.targetLbs {
                    let best = bestLbs(for: goal)?.lbs ?? 0
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Best: \(WeightConverter.format(best.rounded())) / \(WeightConverter.format(target)) lbs",
                              systemImage: "bolt.horizontal.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        SwiftUI.ProgressView(value: min(best / target, 1))
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.2), value: goal.isCompleted)
    }
    
    // MARK: - Auto-tracked goals

    /// Heaviest successful set (any reps) for one lift, in lbs, and the day it was logged.
    private func bestSet(for liftName: String) -> (lbs: Double, date: Date?)? {
        guard let lift = TrackedLifts.lift(named: liftName) else { return nil }
        var best: (lbs: Double, date: Date?)?
        for cycle in cycles {
            for day in cycle.trainingDays {
                for exercise in day.day where lift.matches(exercise.name) {
                    for set in exercise.sets where set.wasSuccessful && (set.reps ?? 0) > 0 {
                        guard let weight = set.weight, weight > 0 else { continue }
                        let lbs = cycle.usesKilograms ? WeightConverter.kgToLbs(weight) : weight
                        if lbs > (best?.lbs ?? 0) { best = (lbs, day.completedDate) }
                    }
                }
            }
        }
        return best
    }

    /// Best progress toward a goal: a single lift, or the sum of the three for the total.
    private func bestLbs(for goal: Goal) -> (lbs: Double, date: Date?)? {
        guard let lift = goal.autoLift else { return nil }
        guard lift == Goal.totalLift else { return bestSet(for: lift) }
        let bests = Goal.totalLifts.compactMap { bestSet(for: $0) }
        guard !bests.isEmpty else { return nil }
        // The total counts from the day its last lift was hit.
        return (bests.reduce(0) { $0 + $1.lbs }, bests.compactMap(\.date).max())
    }

    /// Ticks off goals the logged sets have reached. Never unticks: that stays the user's call.
    private func checkAutoGoals() {
        for goal in goals {
            goal.backfillAutoTarget()
            guard !goal.isCompleted, let target = goal.targetLbs, let best = bestLbs(for: goal) else { continue }
            let needsAllLifts = goal.autoLift == Goal.totalLift
            let hasAllLifts = Goal.totalLifts.allSatisfy { bestSet(for: $0) != nil }
            if best.lbs >= target && (!needsAllLifts || hasAllLifts) {
                goal.isCompleted = true
                goal.completionDate = best.date ?? Date()
            }
        }
    }

    // MARK: - Goal Management Functions
    private func initializeDefaultGoalsIfNeeded() {
        // Only initialize if no goals exist
        if goals.isEmpty {
            for defaultGoal in Goal.defaultGoals {
                context.insert(defaultGoal)
            }
            
            do {
                try context.save()
            } catch {
                print("Failed to save default goals: \(error)")
            }
        }
    }
    
    private func toggleGoalCompletion(_ goal: Goal) {
        withAnimation(.easeInOut(duration: 0.2)) {
            goal.isCompleted.toggle()
            
            if goal.isCompleted {
                goal.completionDate = Date()
            } else {
                goal.completionDate = nil
            }
            
            do {
                try context.save()
            } catch {
                print("Failed to save goal update: \(error)")
            }
        }
    }
    
    // MARK: - Date Formatter
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}


#Preview {
    GoalsView()
        .modelContainer(for: Goal.self, inMemory: true)
}
