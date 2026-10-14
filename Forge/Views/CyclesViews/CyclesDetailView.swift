import SwiftUI
import SwiftData

struct CyclesDetailView: View {
    @Environment(\.modelContext) var context
    @Query(sort: \Cycles.startDate, order: .reverse)
    private var cycles: [Cycles]

    let cycleId: UUID
    @State private var selectedDayIndex: Int = -1
    @State private var addingExercise = false
    @State private var showingPlus = false
    private var plus = ForgePlus.shared

    private var selectedCycle: Cycles? {
        cycles.first { $0.id == cycleId }
    }

    private var validSelectedDayIndex: Int {
        guard let cycle = selectedCycle, !cycle.trainingDays.isEmpty else { return 0 }
        let sortedDays = cycle.trainingDays.sorted(by: { $0.dayIndex < $1.dayIndex })
        
        // If selectedDayIndex doesn't exist in the training days, use the first day's index
        if cycle.trainingDays.contains(where: { $0.dayIndex == selectedDayIndex }) {
            return selectedDayIndex
        } else {
            return sortedDays.first?.dayIndex ?? 0
        }
    }

    init(cycleId: UUID) {
        self.cycleId = cycleId
        let predicate = #Predicate<Cycles> { cycle in
            cycle.id == cycleId
        }
        self._cycles = Query(filter: predicate)
    }

    var body: some View {
        let cycle = selectedCycle

        return Group {
            if let cycle = cycle {
                VStack(spacing: 0) {
                    if cycle.trainingDays.isEmpty {
                        emptyStateView
                    } else {
                        DayStrip(days: sortedTrainingDays(for: cycle), selected: validSelectedDayIndex) {
                            selectedDayIndex = $0
                        }
                        exercisesList(for: cycle)
                    }
                }
            } else {
                cycleNotFoundView
            }
        }
        .environment(\.weightUnit, cycle?.weightUnit ?? "lbs")
        .navigationTitle(cycle?.template ?? "Cycle Detail")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showingPlus) { ForgePlusView() }
        .onAppear {
            // Open on the next day to do.
            if selectedDayIndex < 0, let cycle {
                let days = sortedTrainingDays(for: cycle)
                selectedDayIndex = (days.first { $0.completedDate == nil } ?? days.last)?.dayIndex ?? 0
            }
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            label: {
                Label("No Training Days", systemImage: "calendar.badge.exclamationmark")
            },
            description: {
                Text("This cycle has no training days.")
            }
        )
    }

    private var cycleNotFoundView: some View {
        ContentUnavailableView(
            label: {
                Label("Cycle Not Found", systemImage: "exclamationmark.triangle")
            },
            description: {
                Text("The requested cycle could not be found.")
            }
        )
    }

    private func exercisesList(for cycle: Cycles) -> some View {
        List {
            if let selectedDay = cycle.trainingDays.first(where: { $0.dayIndex == validSelectedDayIndex }) {
                Section(header:
                    HStack(alignment: .firstTextBaseline) {
                        Text(DayStrip.title(for: selectedDay))
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .textCase(nil)
                            .lineLimit(2)
                        Spacer()
                        Button {
                            toggleDayCompletion(selectedDay)
                        } label: {
                            Label(selectedDay.completedDate != nil ? "Done" : "Mark Done",
                                  systemImage: selectedDay.completedDate != nil ? "checkmark.circle.fill" : "circle")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(selectedDay.completedDate != nil ? Color.green : Color.accentColor)
                        }
                        .buttonStyle(.plain)
                        .textCase(nil)
                    }
                ) {
                    ForEach(sortedExercises(for: selectedDay), id: \.exerciseIndex) { exercise in
                        NavigationLink(destination: ExerciseDetailView(
                            cycle: cycle,
                            dayIndex: selectedDay.dayIndex,
                            exerciseIndex: exercise.exerciseIndex
                        )) {
                            ExerciseRowView(exercise: exercise)
                        }
                        .deleteDisabled(!plus.isActive)
                    }
                    .onDelete { offsets in
                        let exercises = sortedExercises(for: selectedDay)
                        let removed = Set(offsets.map { exercises[$0].exerciseIndex })
                        selectedDay.day.removeAll { removed.contains($0.exerciseIndex) }
                    }
                }

                Section {
                    Button {
                        if plus.isActive { addingExercise = true } else { showingPlus = true }
                    } label: {
                        HStack {
                            Label("Add Exercise", systemImage: plus.isActive ? "plus" : "lock")
                            if !plus.isActive {
                                Spacer()
                                PlusBadge()
                            }
                        }
                    }
                } footer: {
                    if plus.isActive {
                        Text("Adds to this day only. Swipe an exercise to remove it. Open an exercise to add sets.")
                    }
                }
                .sheet(isPresented: $addingExercise) {
                    NavigationStack {
                        AddExerciseView { name, sets, reps in
                            let next = (selectedDay.day.map(\.exerciseIndex).max() ?? -1) + 1
                            selectedDay.day.append(Exercise(exerciseIndex: next, name: name, sets: SetScheme.straight(sets, reps: reps)))
                        }
                    }
                    .presentationDetents([.medium, .large])
                }
            }
        }
    }
    
    // MARK: - Exercise Row View
    struct ExerciseRowView: View {
        let exercise: Exercise
        @Environment(\.weightUnit) private var unit
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                // Exercise header with name and completion status
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    // Completion indicator
                    if !exercise.sets.isEmpty {
                        let completedSets = exercise.sets.filter { $0.isCompleted }.count
                        let totalSets = exercise.sets.count
                        
                        HStack(spacing: 4) {
                            Text("\(completedSets)/\(totalSets)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Image(systemName: completedSets == totalSets ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(completedSets == totalSets ? .green : .secondary)
                                .font(.caption)
                        }
                    }
                }
                
                // Preview of the first few sets, in set order
                if !exercise.sets.isEmpty {
                    let orderedSets = exercise.orderedSets
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(orderedSets.prefix(3).enumerated()), id: \.offset) { index, set in
                            HStack(spacing: 8) {
                                Text("Set \(index + 1)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 40, alignment: .leading)
                                
                                Text(CyclesDetailView.setSummary(set, unit: unit))
                                    .font(.caption)
                                    .monospacedDigit()
                                    .foregroundColor(set.reps == nil && set.weight == nil ? .secondary : .primary)
                                
                                Spacer()
                                
                                if set.isCompleted {
                                    Image(systemName: set.wasSuccessful ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(set.wasSuccessful ? .green : .red)
                                        .font(.caption)
                                }
                            }
                        }
                        
                        if orderedSets.count > 3 {
                            Text("+ \(orderedSets.count - 3) more")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.leading, 8)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Helper Methods
    private static func setSummary(_ set: ExerciseSet, unit: String) -> String {
        let reps = set.reps.map { "\($0)\(set.isAmrap ? "+" : "") reps" }
        let weight = set.weight.map { "\(WeightConverter.format($0)) \(unit)" }
        switch (reps, weight) {
        case let (r?, w?): return "\(r) @ \(w)"
        case let (r?, nil): return r
        case let (nil, w?): return w
        default: return "Not set"
        }
    }

    private func toggleDayCompletion(_ trainingDay: TrainingDay) {
        if trainingDay.completedDate != nil {
            trainingDay.completedDate = nil
        } else {
            trainingDay.completedDate = Date()
        }
    }
    
    /// "Day 2: Upper A", or just "Day 2" when the day has no name of its own.
    private func dayLabel(_ day: TrainingDay) -> String {
        let number = "Day \(day.dayIndex + 1)"
        return day.dayName == number ? number : "\(number): \(day.dayName)"
    }

    private func sortedTrainingDays(for cycle: Cycles) -> [TrainingDay] {
        cycle.trainingDays.sorted(by: { $0.dayIndex < $1.dayIndex })
    }

    private func sortedExercises(for day: TrainingDay) -> [Exercise] {
        day.day.sorted(by: { $0.exerciseIndex < $1.exerciseIndex })
    }
}

/// Forge Plus: add an exercise to one training day of a running cycle.
private struct AddExerciseView: View {
    let onAdd: (_ name: String, _ sets: Int, _ reps: Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var sets = 3
    @State private var reps = 10

    var body: some View {
        Form {
            Section {
                TextField("Exercise name", text: $name)
                Stepper(value: $sets, in: 1...10) {
                    LabeledContent("Sets", value: "\(sets)")
                }
                Stepper(value: $reps, in: 1...50) {
                    LabeledContent("Reps", value: "\(reps)")
                }
            } footer: {
                Text("Enter the weight on each set when you log it.")
            }
        }
        .navigationTitle("Add Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") {
                    onAdd(name.trimmingCharacters(in: .whitespaces), sets, reps)
                    dismiss()
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }
}

/// Training days as a row of numbered buttons, grouped by week when the program has weeks,
/// with a tick on finished days.
private struct DayStrip: View {
    let days: [TrainingDay]
    let selected: Int
    let onSelect: (Int) -> Void

    private struct Group: Identifiable {
        let id: Int
        let title: String?
        let days: [TrainingDay]
    }

    /// The week number in names like "Week 2 - Bench" or "Week 1 · Day 3: …".
    static func week(of day: TrainingDay) -> Int? {
        guard let range = day.dayName.range(of: #"^Week (\d+)"#, options: .regularExpression) else { return nil }
        return Int(day.dayName[range].dropFirst(5))
    }

    /// The day's name without the week/day prefix the strip already shows.
    static func title(for day: TrainingDay) -> String {
        var name = day.dayName
        for pattern in [#"^Week \d+\s*[·\-–]\s*Day \d+\s*[:\-–]?\s*"#, #"^Week \d+\s*[·\-–:]\s*"#] {
            if let r = name.range(of: pattern, options: .regularExpression) { name.removeSubrange(r) }
        }
        let number = "Day \(day.dayIndex + 1)"
        if name.isEmpty || name == number { return number }
        return "\(number) · \(name)"
    }

    private var groups: [Group] {
        let hasWeeks = days.contains { Self.week(of: $0) != nil }
        guard hasWeeks else { return [Group(id: 0, title: nil, days: days)] }
        var result: [Group] = []
        for day in days {
            let week = Self.week(of: day) ?? 0
            if let last = result.last, last.id == week {
                result[result.count - 1] = Group(id: week, title: last.title, days: last.days + [day])
            } else {
                result.append(Group(id: week, title: "Week \(week)", days: [day]))
            }
        }
        return result
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 18) {
                    ForEach(groups) { group in
                        VStack(alignment: .leading, spacing: 6) {
                            if let title = group.title {
                                Text(title)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                            HStack(spacing: 8) {
                                ForEach(group.days, id: \.dayIndex) { day in
                                    chip(day).id(day.dayIndex)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .task(id: selected) { proxy.scrollTo(selected, anchor: .center) }
        }
        .background(Color(.systemBackground))
        .overlay(alignment: .bottom) {
            Rectangle().frame(height: 0.5).foregroundStyle(Color(.separator))
        }
    }

    private func chip(_ day: TrainingDay) -> some View {
        let isSelected = day.dayIndex == selected
        let isDone = day.completedDate != nil
        return Button {
            onSelect(day.dayIndex)
        } label: {
            VStack(spacing: 3) {
                Text("\(day.dayIndex + 1)")
                    .font(.headline.monospacedDigit())
                Image(systemName: isDone ? "checkmark" : "circle.fill")
                    .font(.system(size: isDone ? 10 : 4, weight: .bold))
                    .opacity(isDone ? 1 : 0.35)
            }
            .foregroundStyle(isSelected ? Color.white : (isDone ? Color.green : Color.primary))
            .frame(width: 46, height: 52)
            .background(RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.accentColor : Color(.secondarySystemBackground)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(Self.title(for: day))\(isDone ? ", done" : "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
