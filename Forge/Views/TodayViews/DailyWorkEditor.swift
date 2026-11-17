//
//  DailyWorkEditor.swift
//  Forge
//

import SwiftUI
import SwiftData

/// Add, edit, reorder and remove daily-work items.
struct DailyWorkEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \DailyWorkItem.order) private var items: [DailyWorkItem]
    @Query private var allEntries: [DailyWorkEntry]
    @State private var addingCustom = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if items.isEmpty {
                        Text("Nothing yet. Add a preset or your own exercise below.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(items) { item in
                        NavigationLink {
                            DailyWorkItemForm(item: item)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                Text(item.prescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: delete)
                    .onMove(perform: move)
                } header: {
                    Text("Your Daily Work")
                }

                Section {
                    ForEach(availablePresets, id: \.name) { preset in
                        Button {
                            add(name: preset.name, method: preset.method, reps: preset.reps)
                        } label: {
                            Label {
                                LabeledContent(preset.name, value: "\(preset.reps) reps/day")
                            } icon: {
                                Image(systemName: "plus.circle.fill")
                            }
                        }
                    }
                    Button {
                        addingCustom = true
                    } label: {
                        Label("Custom Exercise…", systemImage: "square.and.pencil")
                    }
                } header: {
                    Text("Add")
                } footer: {
                    Text("Tap an exercise above to change its method or target.")
                }
            }
            .navigationTitle("Daily Work")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $addingCustom) {
                DailyWorkItemForm(item: nil, nextOrder: items.count)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    EditButton()
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }

    private var availablePresets: [(name: String, method: DailyWorkMethod, reps: Int)] {
        DailyWorkItem.presets.filter { preset in !items.contains { $0.name == preset.name } }
    }

    private func add(name: String, method: DailyWorkMethod, reps: Int) {
        context.insert(DailyWorkItem(name: name, method: method, reps: reps, order: items.count))
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let item = items[index]
            for entry in allEntries where entry.itemID == item.id {
                context.delete(entry)
            }
            context.delete(item)
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        var reordered = items
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, item) in reordered.enumerated() {
            item.order = index
        }
    }
}

/// Edits an existing item, or creates one when `item` is nil.
struct DailyWorkItemForm: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let item: DailyWorkItem?
    var nextOrder: Int = 0

    @State private var name = ""
    @State private var method: DailyWorkMethod = .totalReps
    @State private var reps = 50
    @State private var setCount = 5

    var body: some View {
        Form {
            Section {
                TextField("Exercise name", text: $name)
                Picker("Method", selection: Binding(get: { method }, set: { new in
                    // Keep the day's total when switching, so 50 reps becomes 5 × 10, not 5 × 50.
                    reps = new.reps(keepingTotalOf: method, reps: reps, setCount: setCount)
                    method = new
                })) {
                    ForEach(DailyWorkMethod.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
            } footer: {
                Text(methodHelp)
            }

            Section {
                Stepper(value: $reps, in: 1...1000) {
                    LabeledContent(repsLabel, value: "\(reps)")
                }
                if method == .sets {
                    Stepper(value: $setCount, in: 1...50) {
                        LabeledContent("Sets", value: "\(setCount)")
                    }
                }
            }
        }
        .navigationTitle(item == nil ? "New Exercise" : "Edit Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear {
            guard let item else { return }
            name = item.name
            method = item.method
            reps = item.reps
            setCount = item.setCount
        }
    }

    private var repsLabel: String {
        switch method {
        case .totalReps: return "Reps per day"
        case .ladder: return "Peak rung"
        case .sets: return "Reps per set"
        }
    }

    private var methodHelp: String {
        switch method {
        case .totalReps: return "Hit a total number of reps, spread through the day however you like."
        case .ladder: return "Do 1 rep, then 2, then 3, up to the peak rung."
        case .sets: return "A fixed number of sets, spread through the day."
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let item {
            item.name = trimmed
            item.method = method
            item.reps = reps
            item.setCount = setCount
        } else {
            context.insert(DailyWorkItem(name: trimmed, method: method, reps: reps, setCount: setCount, order: nextOrder))
        }
        dismiss()
    }
}
