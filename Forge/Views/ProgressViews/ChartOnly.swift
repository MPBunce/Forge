//
//  ChartOnly.swift
//  Forge
//
//  Created by Matthew Bunce on 2025-06-12.
//

import SwiftUI
import SwiftData
import Charts

struct ChartOnly: View {
    @Environment(\.modelContext) var context
    @Query(sort: \Cycles.startDate, order: .forward) var cycles: [Cycles]
    @Query var settings: [Settings]
    
    /// Charts use the app's current unit; cycles logged in the other unit are converted.
    private var showKilograms: Bool { settings.first?.usesKilograms ?? false }
    private var unit: String { showKilograms ? "kg" : "lbs" }

    @AppStorage(PreferenceKeys.trackedLifts) private var trackedLiftsStorage = TrackedLifts.defaultStorage
    @State private var showingLiftPicker = false

    private var targetLifts: [String] { TrackedLifts.decode(trackedLiftsStorage) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if targetLifts.isEmpty {
                    ContentUnavailableView {
                        Label("No Lifts Chosen", systemImage: "chart.xyaxis.line")
                    } description: {
                        Text("Pick the lifts you want to track.")
                    } actions: {
                        Button("Choose Lifts") { showingLiftPicker = true }
                    }
                }
                ForEach(targetLifts, id: \.self) { lift in
                    liftProgressionChart(for: lift)
                }
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Lifts", systemImage: "slider.horizontal.3") { showingLiftPicker = true }
            }
        }
        .sheet(isPresented: $showingLiftPicker) {
            LiftPickerSheet(selected: Binding(
                get: { targetLifts },
                set: { trackedLiftsStorage = TrackedLifts.encode($0) }
            ), available: allExerciseNames)
        }
    }

    /// Only the Greyskull LP exercise-index lifts can be charted.
    private var allExerciseNames: [String] {
        TrackedLifts.catalog.map(\.name)
    }

    // MARK: - 1RM Progression Chart for each lift
    @ViewBuilder
    private func liftProgressionChart(for lift: String) -> some View {
        let progressionData = get1RMProgression(for: lift)
        
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(lift)
                    .font(.title2)
                    .bold()
                Spacer()
                NavigationLink {
                    LiftHistoryView(lift: lift)
                } label: {
                    Label("History", systemImage: "list.bullet")
                        .font(.subheadline.weight(.medium))
                }
            }
            
            if progressionData.isEmpty {
                Text("Tick off your \(lift) sets and mark the training day complete to start tracking.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 32)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(progressionData) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("1RM", dataPoint.oneRM)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    PointMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("1RM", dataPoint.oneRM)
                    )
                    .foregroundStyle(.blue)
                    .symbolSize(25) // Slightly smaller since we might have more points
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let weight = value.as(Double.self) {
                                Text("\(Int(weight)) \(unit)")
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .chartXScale(domain: .automatic) // Let SwiftUI handle the domain automatically
                .chartYScale(domain: .automatic)
                
                // Show current max from most recent workout
                if let mostRecentWorkout = progressionData.last {
                    HStack {
                        Text("Latest Projected 1RM:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(mostRecentWorkout.oneRM, specifier: "%.1f") \(unit)")
                            .font(.caption)
                            .bold()
                    }
                }
                
                // Show overall personal best
                if let personalBest = progressionData.max(by: { $0.oneRM < $1.oneRM }),
                   personalBest.oneRM != progressionData.last?.oneRM {
                    HStack {
                        Text("Highest Projected 1RM:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(personalBest.oneRM, specifier: "%.1f") \(unit)")
                            .font(.caption)
                            .bold()
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Data Structure for 1RM Progression
    struct OneRMDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let oneRM: Double
    }

    // MARK: - 1RM Calculation and Data Extraction
    private func get1RMProgression(for lift: String) -> [OneRMDataPoint] {
        var dataPoints: [OneRMDataPoint] = []
        
        // Process all cycles in chronological order
        for cycle in cycles {
            // Get all completed training days and sort them by completion date
            let completedTrainingDays = cycle.trainingDays
                .compactMap { trainingDay -> (trainingDay: TrainingDay, completedDate: Date)? in
                    guard let completedDate = trainingDay.completedDate else { return nil }
                    return (trainingDay: trainingDay, completedDate: completedDate)
                }
                .sorted { $0.completedDate < $1.completedDate }
            
            // Process each completed training day
            for (trainingDay, completedDate) in completedTrainingDays {
                var maxOneRMForWorkout: Double = 0
                
                // Find all exercises for this lift in this workout
                for exercise in trainingDay.day {
                    if TrackedLifts.lift(named: lift)?.matches(exercise.name) ?? (exercise.name == lift) {
                        // Only sets actually completed count; the planned numbers on skipped
                        // or failed sets would otherwise show progress that never happened.
                        for set in exercise.sets where set.wasSuccessful {
                            if let loggedWeight = set.weight, let reps = set.reps, loggedWeight > 0, reps > 0 {
                                let weight = convert(loggedWeight, fromKilograms: cycle.usesKilograms)
                                let oneRM = calculate1RM(weight: weight, reps: reps)
                                maxOneRMForWorkout = max(maxOneRMForWorkout, oneRM)
                            }
                        }
                    }
                }
                
                // Only add data point if we found a valid 1RM for this workout
                if maxOneRMForWorkout > 0 {
                    dataPoints.append(OneRMDataPoint(date: completedDate, oneRM: maxOneRMForWorkout))
                }
            }
        }
        
        // Sort all data points by date (oldest first) to ensure chronological order
        dataPoints.sort { $0.date < $1.date }
        
        return dataPoints
    }
    
    private func convert(_ weight: Double, fromKilograms: Bool) -> Double {
        if fromKilograms == showKilograms { return weight }
        return showKilograms ? WeightConverter.lbsToKg(weight) : WeightConverter.kgToLbs(weight)
    }
    
    // MARK: - 1RM Calculation using Epley Formula
    private func calculate1RM(weight: Double, reps: Int) -> Double {
        // Epley formula: 1RM = weight × (1 + reps/30)
        // For 1 rep, this returns the weight itself
        return weight * (1.0 + Double(reps) / 30.0)
    }
}

// MARK: - Lift picker
/// Choose and order the lifts charted on the Progress tab.
private struct LiftPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selected: [String]
    let available: [String]
    @State private var search = ""

    private var unselected: [String] {
        available.filter { !selected.contains($0) }
            .filter { search.isEmpty || $0.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if selected.isEmpty {
                        Text("No lifts selected.").foregroundStyle(.secondary)
                    }
                    ForEach(selected, id: \.self) { lift in
                        Button {
                            selected.removeAll { $0 == lift }
                        } label: {
                            Label(lift, systemImage: "checkmark.circle.fill")
                        }
                        .tint(.primary)
                    }
                    .onMove { selected.move(fromOffsets: $0, toOffset: $1) }
                } header: {
                    Text("Charted")
                } footer: {
                    Text("Tap to remove. Use Edit to reorder.")
                }

                Section {
                    ForEach(unselected, id: \.self) { lift in
                        Button {
                            selected.append(lift)
                        } label: {
                            Label(lift, systemImage: "circle")
                        }
                        .tint(.primary)
                    }
                    if unselected.isEmpty && !search.isEmpty {
                        Text("No matching lifts.").foregroundStyle(.secondary)
                    } else if unselected.isEmpty {
                        Text("Every lift is already charted.")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Add a lift")
                } footer: {
                    Text("Lifts from the Greyskull LP exercise index.")
                }
            }
            .searchable(text: $search, prompt: "Search exercises")
            .navigationTitle("Progress Lifts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { EditButton() }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }
}
