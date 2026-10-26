//
//  ExerciseDetailComponents.swift
//  Forge
//
//  Created by Matthew Bunce on 2025-06-10.
//

import SwiftUI
import Foundation
import SwiftData

// MARK: - Stats Header Component
struct ExerciseStatsHeader: View {
    let editingSets: [ExerciseSet]
    
    var body: some View {
        VStack(spacing: 16) {
            ExerciseStatsCards(editingSets: editingSets)
            
            if !editingSets.isEmpty {
                ExerciseProgressIndicator(editingSets: editingSets)
            }
        }
        .padding()
    }
}

// MARK: - Stats Cards Component
struct ExerciseStatsCards: View {
    let editingSets: [ExerciseSet]
    
    var body: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Total Sets",
                value: "\(editingSets.count)",
                color: .blue,
                icon: "list.number"
            )
            
            StatCard(
                title: "Completed",
                value: "\(editingSets.filter { $0.wasSuccessful }.count)",
                color: .green,
                icon: "checkmark.circle.fill"
            )
            
            StatCard(
                title: "Failed",
                value: "\(editingSets.filter { $0.completionStatus == .failed }.count)",
                color: .red,
                icon: "xmark.circle.fill"
            )
        }
    }
}

// MARK: - Progress Indicator Component
struct ExerciseProgressIndicator: View {
    let editingSets: [ExerciseSet]
    
    private var progress: Double {
        let completedCount = editingSets.filter { $0.isCompleted }.count
        return Double(completedCount) / Double(editingSets.count)
    }
    
    private var completedCount: Int {
        editingSets.filter { $0.isCompleted }.count
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Progress")
                    .font(.headline)
                Spacer()
                Text("\(completedCount)/\(editingSets.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            CustomProgressBar(progress: progress)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Custom Progress Bar Component
struct CustomProgressBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 8)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: geometry.size.width * progress, height: 8)
                    .cornerRadius(4)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Sets Section Component
struct ExerciseSetsSection: View {
    let sets: [ExerciseSet]
    var pbSetID: PersistentIdentifier? = nil
    @Binding var showingAddSetSheet: Bool
    let canAlterSets: Bool
    let onDeleteSet: (ExerciseSet) -> Void
    let onEditSet: (ExerciseSet) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            SetsSectionHeader(
                showingAddSetSheet: $showingAddSetSheet,
                canAddSets: canAlterSets
            )
            if sets.isEmpty {
                Text(canAlterSets ? "No sets yet. Tap Add Set to log one." : "No sets for this exercise.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else {
                SetsList(
                    sets: sets,
                    pbSetID: pbSetID,
                    canAlterSets: canAlterSets,
                    onDeleteSet: onDeleteSet,
                    onEditSet: onEditSet
                )
            }
        }
    }
}

// MARK: - Sets Section Header Component
struct SetsSectionHeader: View {
    @Binding var showingAddSetSheet: Bool
    let canAddSets: Bool
    
    var body: some View {
        HStack {
            Text("Sets")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            if canAddSets {
                Button(action: { showingAddSetSheet = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add Set")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Sets List Component
struct SetsList: View {
    let sets: [ExerciseSet]
    var pbSetID: PersistentIdentifier? = nil
    let canAlterSets: Bool
    let onDeleteSet: (ExerciseSet) -> Void
    let onEditSet: (ExerciseSet) -> Void
    
    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(sets.enumerated()), id: \.element.persistentModelID) { index, set in
                ModernSetRowView(
                    set: set,
                    number: index + 1,
                    isPB: set.persistentModelID == pbSetID,
                    canDelete: canAlterSets,
                    onDelete: { onDeleteSet(set) },
                    onEdit: { onEditSet(set) }
                )
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Modern Set Row Component
struct ModernSetRowView: View {
    @Environment(\.restSeconds) private var restSeconds
    let set: ExerciseSet
    let number: Int
    var isPB = false
    let canDelete: Bool
    let onDelete: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            SetStatusButton(set: set)
            
            Text("\(number)")
                .font(.caption)
                .foregroundColor(.secondary)
                .monospacedDigit()
                .frame(width: 16)
            
            // Tap the numbers to change them.
            if set.isEditable || set.isAmrap {
                Button(action: onEdit) {
                    HStack(spacing: 6) {
                        SetDisplayValues(set: set)
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(.tertiarySystemFill)))
                }
                .buttonStyle(.plain)
                .accessibilityHint("Edit weight and reps")
            } else {
                SetDisplayValues(set: set)
            }

            if isPB {
                Label("PB", systemImage: "trophy.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(.yellow))
                    .accessibilityLabel("Personal best")
            }

            Spacer(minLength: 0)
            
            SetActionsMenu(
                set: set,
                canDelete: canDelete,
                canEdit: set.isEditable || set.isAmrap,
                onDelete: onDelete,
                onEdit: onEdit,
                onReset: { withAnimation(.spring(response: 0.3)) { set.reset() } }
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(set.isCompleted ? Color.gray.opacity(0.05) : Color.clear)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .bottom
        )
        .contentShape(Rectangle())
        .onTapGesture {
            // AMRAP sets are logged by entering reps, so tapping the row opens that sheet instead.
            if set.isAmrap {
                onEdit()
            } else {
                withAnimation(.spring(response: 0.3)) { set.cycleStatus() }
                if set.completionStatus == .completedSuccessfully {
                    RestTimer.shared.startIfEnabled(seconds: restSeconds)
                }
            }
        }
    }
}

// MARK: - Set Status Button Component
struct SetStatusButton: View {
    let set: ExerciseSet
    
    private var statusColor: Color {
        switch set.completionStatus {
        case .notStarted: return .secondary
        case .completedSuccessfully: return .green
        case .failed: return .red
        }
    }
    
    private var statusIcon: String {
        if set.isAmrap && set.completionStatus == .notStarted {
            return "circle.dashed"
        }
        
        switch set.completionStatus {
        case .notStarted: return "circle"
        case .completedSuccessfully: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
    
    var body: some View {
        Image(systemName: statusIcon)
            .font(.title2)
            .foregroundColor(statusColor)
            .accessibilityLabel(set.completionStatus == .notStarted ? "Not done" : set.wasSuccessful ? "Done" : "Failed")
    }
}

// MARK: - Set Display Values Component
struct SetDisplayValues: View {
    let set: ExerciseSet
    
    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                Text(set.weight.map { WeightConverter.format($0) } ?? "—")
                    .fontWeight(.medium)
                    .foregroundColor(set.weight != nil ? .primary : .secondary)
                
                Text("×")
                    .foregroundColor(.secondary)
                
                Text(set.reps.map { "\($0)" } ?? "—")
                    .fontWeight(.medium)
                    .foregroundColor(set.reps != nil ? .primary : .secondary)
            }
            .font(.body)
            .monospacedDigit()

            if set.isAmrap {
                Text(set.amrapTargetReps.map { "AMRAP \($0)+" } ?? "AMRAP")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(4)
            }
        }
    }
}

// MARK: - Set Actions Menu Component
struct SetActionsMenu: View {
    let set: ExerciseSet
    let canDelete: Bool
    let canEdit: Bool
    let onDelete: () -> Void
    let onEdit: () -> Void
    let onReset: () -> Void
    
    var body: some View {
        Menu {
            if canEdit {
                Button(set.isAmrap ? "Log Reps" : "Edit", action: onEdit)
            }
            
            if set.isCompleted {
                Button("Reset", action: onReset)
            }
            
            if canDelete {
                Button("Delete", role: .destructive, action: onDelete)
            }
        } label: {
            Image(systemName: "ellipsis")
                .foregroundColor(.secondary)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .disabled(!canEdit && !canDelete && !set.isCompleted)
    }
}

// MARK: - Set editor
// Weight and reps as big numbers with − and + buttons (weight steps by a pair of the
// smallest plates), so logging a set is a couple of taps. Tap a number to type it instead.

private struct SetEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.weightUnit) private var unit
    @Environment(\.weightStep) private var step
    @Environment(\.weightStart) private var start
    @Environment(\.barWeight) private var bar
    @Environment(\.smallestPlate) private var smallestPlate
    @AppStorage(PreferenceKeys.showPlates) private var showPlates = true
    private var plus = ForgePlus.shared

    let title: String
    let confirmTitle: String
    var weightEditable = true
    var repsEditable = true
    var repsLabel = "Reps"
    var targetReps: Int? = nil
    var note: String? = nil
    @State var weight: Double?
    @State var reps: Int?
    let onSave: (Double?, Int?) -> Void
    var onCancel: (() -> Void)? = nil

    @State private var weightText = ""
    @State private var repsText = ""
    @FocusState private var focused: Field?
    enum Field { case weight, reps }

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                if let note {
                    Label(note, systemImage: "lock.fill")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                stepperRow(label: "Weight (\(unit))", text: $weightText, field: .weight, editable: weightEditable,
                           keyboard: .decimalPad,
                           minus: { adjustWeight(-step) }, plus: { adjustWeight(step) })
                if plus.isActive, weightEditable {
                    platesRow
                }
                stepperRow(label: repsLabel, text: $repsText, field: .reps, editable: repsEditable,
                           keyboard: .numberPad,
                           minus: { adjustReps(-1) }, plus: { adjustReps(1) })
                if let target = targetReps {
                    let done = Int(repsText)
                    Label(done == nil ? "Target \(target)+ reps" : (done! >= target ? "Target reached" : "Below the \(target)+ target"),
                          systemImage: done == nil ? "target" : (done! >= target ? "checkmark.circle.fill" : "xmark.circle.fill"))
                        .font(.subheadline)
                        .foregroundStyle(done == nil ? Color.secondary : (done! >= target ? Color.green : Color.red))
                }
                Spacer(minLength: 0)
                Button {
                    save()
                } label: {
                    Text(confirmTitle)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .disabled(!isValid)
            }
            .padding(20)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel?() ?? dismiss() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focused = nil }.fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.height(targetReps == nil ? 340 : 380), .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            weightText = weight.map { WeightConverter.format($0) } ?? ""
            repsText = reps.map(String.init) ?? ""
        }
        .onChange(of: focused) { _, field in
            // Select the number so typing replaces it instead of adding digits in front.
            guard field != nil else { return }
            DispatchQueue.main.async {
                UIApplication.shared.sendAction(#selector(UIResponder.selectAll(_:)), to: nil, from: nil, for: nil)
            }
        }
    }

    /// Forge Plus: what to load on each side of the bar. Tap to hide or show it.
    @ViewBuilder
    private var platesRow: some View {
        if let weight = Double(weightText),
           let result = PlateCalculator.plates(for: weight, bar: bar, smallest: smallestPlate, kilograms: unit == "kg") {
            Button {
                showPlates.toggle()
            } label: {
                Label(showPlates
                      ? "Per side: \(PlateCalculator.describe(result.plates))\(result.remainder > 0 ? " (+\(WeightConverter.format(result.remainder)) short)" : "")"
                      : "Show plates",
                      systemImage: "circle.grid.cross")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Shows or hides the plates for each side of the bar")
        }
    }

    private var isValid: Bool {
        (weightText.isEmpty || Double(weightText) != nil) && (repsText.isEmpty || Int(repsText) != nil)
            && (targetReps == nil || Int(repsText) != nil)
    }

    private func save() {
        onSave(Double(weightText), Int(repsText))
        if onCancel == nil { dismiss() }
    }

    private func adjustWeight(_ delta: Double) {
        // A blank weight jumps straight to a sensible starting point instead of 0.
        guard let current = Double(weightText) else {
            weightText = WeightConverter.format(start)
            return
        }
        let next = max(0, ((current + delta) * 100).rounded() / 100)
        weightText = WeightConverter.format(next)
    }

    private func adjustReps(_ delta: Int) {
        repsText = String(max(0, (Int(repsText) ?? 0) + delta))
    }

    private func stepperRow(label: String, text: Binding<String>, field: Field, editable: Bool,
                            keyboard: UIKeyboardType, minus: @escaping () -> Void, plus: @escaping () -> Void) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack(spacing: 16) {
                roundButton("minus", action: minus).disabled(!editable)
                TextField("—", text: text)
                    .font(.system(size: 40, weight: .semibold, design: .rounded).monospacedDigit())
                    .multilineTextAlignment(.center)
                    .keyboardType(keyboard)
                    .focused($focused, equals: field)
                    .disabled(!editable)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel(label)
                roundButton("plus", action: plus).disabled(!editable)
            }
        }
        .opacity(editable ? 1 : 0.5)
    }

    private func roundButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title2.weight(.semibold))
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color(.tertiarySystemFill)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(symbol == "plus" ? "Increase" : "Decrease")
    }
}

// MARK: - Add Set View
struct AddSetView: View {
    let onAdd: (Double?, Int?) -> Void

    var body: some View {
        SetEditor(title: "Add Set", confirmTitle: "Add Set", weight: nil, reps: nil, onSave: onAdd)
    }
}

// MARK: - Regular Set Edit View
struct EditRegularSetView: View {
    let initialWeight: Double?
    let initialReps: Int?
    let isEditable: Bool
    let onSave: (Double?, Int?) -> Void
    let onCancel: () -> Void

    init(initialWeight: Double?, initialReps: Int?, isEditable: Bool, onSave: @escaping (Double?, Int?) -> Void, onCancel: @escaping () -> Void) {
        self.initialWeight = initialWeight
        self.initialReps = initialReps
        self.isEditable = isEditable
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        SetEditor(title: "Edit Set", confirmTitle: "Save",
                  weightEditable: isEditable, repsEditable: isEditable,
                  note: isEditable ? nil : "Set by the program",
                  weight: initialWeight, reps: initialReps,
                  onSave: onSave, onCancel: onCancel)
    }
}

// MARK: - Edit Set Sheet View
struct EditSetSheetView: View {
    let set: ExerciseSet
    let onUpdateAmrap: (Int?, Double?) -> Void
    let onUpdateRegular: (Double?, Int?) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        if set.isAmrap {
            EditAmrapSetView(
                initialReps: set.reps,
                weight: set.weight,
                isWeightEditable: set.isEditable,
                targetReps: set.amrapTargetReps,
                onSave: onUpdateAmrap,
                onCancel: onCancel
            )
        } else {
            EditRegularSetView(
                initialWeight: set.weight,
                initialReps: set.reps,
                isEditable: set.isEditable,
                onSave: onUpdateRegular,
                onCancel: onCancel
            )
        }
    }
}

// MARK: - AMRAP Set Edit View
struct EditAmrapSetView: View {
    let initialReps: Int?
    let weight: Double?
    let isWeightEditable: Bool
    let targetReps: Int?
    let onSave: (Int?, Double?) -> Void
    let onCancel: () -> Void

    init(initialReps: Int?, weight: Double?, isWeightEditable: Bool, targetReps: Int?, onSave: @escaping (Int?, Double?) -> Void, onCancel: @escaping () -> Void) {
        self.initialReps = initialReps
        self.weight = weight
        self.isWeightEditable = isWeightEditable
        self.targetReps = targetReps
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        SetEditor(title: "As Many Reps As Possible", confirmTitle: "Save",
                  weightEditable: isWeightEditable, repsLabel: "Reps done", targetReps: targetReps,
                  weight: weight, reps: initialReps ?? targetReps,
                  onSave: { w, r in onSave(r, isWeightEditable ? w : weight) }, onCancel: onCancel)
    }
}
