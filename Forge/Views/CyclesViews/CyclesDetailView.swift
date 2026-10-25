import SwiftUI
import SwiftData

struct CyclesDetailView: View {
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) private var dismiss
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
        
        // Until a day is picked, open on the next day to do.
        if cycle.trainingDays.contains(where: { $0.dayIndex == selectedDayIndex }) {
            return selectedDayIndex
        } else {
            return cycle.nextDay?.dayIndex ?? sortedDays.first?.dayIndex ?? 0
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
                        DayPager(days: sortedTrainingDays(for: cycle), selected: validSelectedDayIndex) {
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
        .safeAreaInset(edge: .bottom) { RestTimerBar() }
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
            if cycle.isCompleted, let template = Template.named(cycle.template) {
                Section {
                    CycleFinishedBanner(template: template) { dismiss() }
                }
            }
            if let selectedDay = cycle.trainingDays.first(where: { $0.dayIndex == validSelectedDayIndex }) {
                Section(header:
                    HStack(alignment: .firstTextBaseline) {
                        Text(DayPager.title(for: selectedDay, in: sortedTrainingDays(for: cycle)))
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
                        if exercise.isCheckOff {
                            // A run or other session with nothing to log: tick it off right here.
                            CheckOffRow(exercise: exercise) { toggleCheckOff(exercise, on: selectedDay) }
                                .deleteDisabled(!plus.isActive)
                        } else {
                            NavigationLink(destination: ExerciseDetailView(
                                cycle: cycle,
                                dayIndex: selectedDay.dayIndex,
                                exerciseIndex: exercise.exerciseIndex
                            )) {
                                ExerciseRowView(exercise: exercise)
                            }
                            .deleteDisabled(!plus.isActive)
                        }
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

    /// Ticks a session off, and completes the day when everything on it is a finished session.
    private func toggleCheckOff(_ exercise: Exercise, on day: TrainingDay) {
        guard let set = exercise.orderedSets.first else { return }
        withAnimation {
            set.completionStatus = set.isCompleted ? .notStarted : .completedSuccessfully
            let allSessions = day.day.allSatisfy(\.isCheckOff)
            if allSessions {
                day.completedDate = day.day.allSatisfy { $0.sets.allSatisfy(\.isCompleted) } ? (day.completedDate ?? Date()) : nil
            }
        }
        try? context.save()
    }

    private func toggleDayCompletion(_ trainingDay: TrainingDay) {
        if trainingDay.completedDate != nil {
            trainingDay.completedDate = nil
        } else {
            trainingDay.completedDate = Date()
        }
        // Save now so the Training list and Today pick it up straight away, not at the next autosave.
        try? context.save()
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

/// Every cycle's days, the same way: one week at a time (programs without weeks are one
/// page, or pages of 7), a row of equal-sized day buttons that always fits, and a header with
/// the week and how much of the cycle is done.
struct DayPager: View {
    let days: [TrainingDay]
    let selected: Int
    let onSelect: (Int) -> Void

    @State private var page = 0

    /// Days grouped into pages: by "Week N" in their names, else 7 at a time.
    static func pages(_ days: [TrainingDay]) -> [[TrainingDay]] {
        if days.contains(where: { week(of: $0) != nil }) {
            var result: [[TrainingDay]] = []
            var current: Int?
            for day in days {
                let w = week(of: day) ?? current ?? 0
                if w == current { result[result.count - 1].append(day) } else { result.append([day]); current = w }
            }
            return result
        }
        return stride(from: 0, to: days.count, by: 7).map { Array(days[$0..<min($0 + 7, days.count)]) }
    }

    /// The week number in names like "Week 2 - Bench" or "Week 1 · Day 3: …".
    static func week(of day: TrainingDay) -> Int? {
        guard let range = day.dayName.range(of: #"^Week (\d+)"#, options: .regularExpression) else { return nil }
        return Int(day.dayName[range].dropFirst(5))
    }

    /// "Mon" from names like "Mon · Lower A".
    static func weekday(of day: TrainingDay) -> String? {
        let symbols = Calendar.current.shortWeekdaySymbols
        let prefix = String(day.dayName.prefix(3))
        return symbols.contains(prefix) ? prefix : nil
    }

    /// The day's name without the week, day number or weekday prefixes the pager already shows.
    static func shortName(_ day: TrainingDay) -> String {
        var name = day.dayName
        for pattern in [#"^Week \d+\s*[·\-–]\s*Day \d+\s*[:\-–]?\s*"#, #"^Week \d+\s*[·\-–:]\s*"#,
                        #"^(Mon|Tue|Wed|Thu|Fri|Sat|Sun)\s*·\s*"#] {
            if let r = name.range(of: pattern, options: .regularExpression) { name.removeSubrange(r) }
        }
        return name == "Day \(day.dayIndex + 1)" ? "" : name
    }

    /// The title above the exercises: "Week 2 · Day 3 · Bench Press", "Mon · Lower A", "Day 2 · Pull".
    static func title(for day: TrainingDay, in days: [TrainingDay]) -> String {
        let pages = pages(days)
        guard let p = pages.firstIndex(where: { $0.contains { $0.dayIndex == day.dayIndex } }),
              let d = pages[p].firstIndex(where: { $0.dayIndex == day.dayIndex }) else { return day.dayName }
        var parts: [String] = []
        if pages.count > 1 { parts.append("Week \(p + 1)") }
        parts.append(weekday(of: day) ?? "Day \(d + 1)")
        let name = shortName(day)
        if !name.isEmpty { parts.append(name) }
        return parts.joined(separator: " · ")
    }

    private var pages: [[TrainingDay]] { Self.pages(days) }
    private var doneCount: Int { days.filter { $0.completedDate != nil }.count }

    private func pageOf(_ dayIndex: Int) -> Int {
        pages.firstIndex { $0.contains { $0.dayIndex == dayIndex } } ?? 0
    }

    var body: some View {
        let pages = pages
        let current = pages.isEmpty ? [] : pages[min(page, pages.count - 1)]
        VStack(spacing: 10) {
            HStack {
                if pages.count > 1 {
                    Button { page -= 1 } label: { Image(systemName: "chevron.left").frame(width: 32, height: 32) }
                        .disabled(page == 0)
                        .accessibilityLabel("Previous week")
                    Text("Week \(page + 1) of \(pages.count)")
                        .font(.subheadline.weight(.semibold))
                    Button { page += 1 } label: { Image(systemName: "chevron.right").frame(width: 32, height: 32) }
                        .disabled(page >= pages.count - 1)
                        .accessibilityLabel("Next week")
                } else {
                    Text("Training days")
                        .font(.subheadline.weight(.semibold))
                        .frame(height: 32)
                }
                Spacer()
                Text("\(doneCount) of \(days.count) done")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                ForEach(Array(current.enumerated()), id: \.element.dayIndex) { offset, day in
                    chip(day, number: offset + 1)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .overlay(alignment: .bottom) {
            Rectangle().frame(height: 0.5).foregroundStyle(Color(.separator))
        }
        .onAppear { page = pageOf(selected) }
        .onChange(of: selected) { _, new in page = pageOf(new) }
        .gesture(DragGesture(minimumDistance: 30).onEnded { value in
            if value.translation.width < -40, page < pages.count - 1 { page += 1 }
            if value.translation.width > 40, page > 0 { page -= 1 }
        })
        .animation(.snappy, value: page)
    }

    private func chip(_ day: TrainingDay, number: Int) -> some View {
        let isSelected = day.dayIndex == selected
        let isDone = day.completedDate != nil
        let weekday = Self.weekday(of: day)
        return Button {
            onSelect(day.dayIndex)
        } label: {
            VStack(spacing: 3) {
                Text(weekday ?? "\(number)")
                    .font(weekday == nil ? .headline.monospacedDigit() : .subheadline.weight(.semibold))
                Image(systemName: isDone ? "checkmark" : "circle.fill")
                    .font(.system(size: isDone ? 10 : 4, weight: .bold))
                    .opacity(isDone ? 1 : 0.35)
            }
            .foregroundStyle(isSelected ? Color.white : (isDone ? Color.green : Color.primary))
            .frame(maxWidth: 64)
            .frame(height: 52)
            .background(RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.accentColor : Color(.secondarySystemBackground)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(Self.title(for: day, in: days))\(isDone ? ", done" : "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

extension Exercise {
    /// A single item with nothing to log (a run, a session): ticked off rather than opened.
    var isCheckOff: Bool {
        sets.count == 1 && sets[0].reps == nil && sets[0].weight == nil && !sets[0].isAmrap
    }
}

/// A run or session on a training day: its description and a big tick.
private struct CheckOffRow: View {
    let exercise: Exercise
    let onToggle: () -> Void

    var body: some View {
        let done = exercise.sets.first?.isCompleted ?? false
        Button(action: onToggle) {
            HStack(spacing: 14) {
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .font(.title)
                    .foregroundStyle(done ? Color.green : Color.secondary)
                    .contentTransition(.symbolEffect(.replace))
                VStack(alignment: .leading, spacing: 3) {
                    let parts = exercise.name.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
                    Text(parts.first ?? exercise.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if parts.count > 1 {
                        Text(parts[1].prefix(1).uppercased() + parts[1].dropFirst())
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Text(done ? "Done" : "Tap to tick off. Log distance in Running if you like.")
                        .font(.caption)
                        .foregroundStyle(done ? Color.green : Color.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(done ? "Done" : "Not done")
    }
}
