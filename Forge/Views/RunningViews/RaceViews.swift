//
//  RaceViews.swift
//  Forge
//
//  Logging race results and listing them in the Running tab.
//

import SwiftUI
import SwiftData

/// "Races" section shown at the top of the Running list.
struct RacesSection: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \RaceResult.date, order: .reverse) private var races: [RaceResult]
    @State private var showingLog = false

    var body: some View {
        Section {
            Button {
                showingLog = true
            } label: {
                Label("Log a Race", systemImage: "flag.checkered")
            }
            ForEach(races) { race in
                RaceRow(race: race, isBest: isPersonalBest(race))
            }
            .onDelete { offsets in
                for index in offsets { context.delete(races[index]) }
            }
        } header: {
            Text("Races")
        } footer: {
            if !races.isEmpty {
                Text("Races count as runs and towards your distance badges.")
            }
        }
        .sheet(isPresented: $showingLog) {
            LogRaceSheet()
        }
    }

    private func isPersonalBest(_ race: RaceResult) -> Bool {
        let best = races.filter { $0.distance == race.distance }.min { $0.seconds < $1.seconds }
        return best?.persistentModelID == race.persistentModelID
    }
}

private struct RaceRow: View {
    let race: RaceResult
    let isBest: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(race.name.isEmpty ? race.distance.name : race.name)
                        .font(.headline)
                    if isBest {
                        Text("PB")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.15), in: Capsule())
                    }
                }
                Text("\(race.distance.name) · \(race.date.formatted(.dateTime.month(.abbreviated).day().year()))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(RaceTime.format(race.seconds))
                    .font(.headline.monospacedDigit())
                Text(race.pace)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

/// Enter a race: distance, date, finish time and an optional name.
struct LogRaceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    var initialDistance: RaceDistance = .fiveK
    @State private var distance: RaceDistance = .fiveK
    @State private var date = Date()
    @State private var name = ""
    @State private var hours = 0
    @State private var minutes = 25
    @State private var seconds = 0
    @State private var loaded = false

    private var totalSeconds: Int { hours * 3600 + minutes * 60 + seconds }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Distance", selection: $distance) {
                        ForEach(RaceDistance.allCases) { Text($0.name).tag($0) }
                    }
                    DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)
                    TextField("Race name (optional)", text: $name)
                }

                Section {
                    HStack(spacing: 0) {
                        timePicker(value: $hours, range: 0..<10, unit: "h")
                        timePicker(value: $minutes, range: 0..<60, unit: "m")
                        timePicker(value: $seconds, range: 0..<60, unit: "s")
                    }
                    .frame(height: 150)
                } header: {
                    Text("Finish time")
                } footer: {
                    if totalSeconds > 0 {
                        let perKm = Int((Double(totalSeconds) / distance.kilometres).rounded())
                        Text("\(RaceTime.format(totalSeconds)) · \(String(format: "%d:%02d", perKm / 60, perKm % 60)) per km")
                    }
                }
            }
            .navigationTitle("Log a Race")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        context.insert(RaceResult(distance: distance, seconds: totalSeconds, date: date,
                                                  name: name.trimmingCharacters(in: .whitespaces)))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(totalSeconds == 0)
                }
            }
            .onAppear {
                guard !loaded else { return }
                loaded = true
                distance = initialDistance
                // Start the wheels near a typical finish so there's less scrolling.
                let typical = distance.defaultTopFivePercentSeconds * 5 / 4
                hours = typical / 3600
                minutes = (typical % 3600) / 60
                seconds = 0
            }
            .onChange(of: distance) { _, newDistance in
                let typical = newDistance.defaultTopFivePercentSeconds * 5 / 4
                hours = typical / 3600
                minutes = (typical % 3600) / 60
                seconds = 0
            }
        }
    }

    private func timePicker(value: Binding<Int>, range: Range<Int>, unit: String) -> some View {
        Picker(unit, selection: value) {
            ForEach(range, id: \.self) { Text("\($0) \(unit)").tag($0) }
        }
        .pickerStyle(.wheel)
        .frame(maxWidth: .infinity)
        .clipped()
    }
}

// MARK: - Single runs

/// One-off runs outside a plan.
struct SingleRunsSection: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \LoggedRun.date, order: .reverse) private var runs: [LoggedRun]
    @State private var showingLog = false

    var body: some View {
        Section {
            Button {
                showingLog = true
            } label: {
                Label("Log a Run", systemImage: "figure.run")
            }
            ForEach(runs) { run in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(RunSegment.formatKm(run.kilometres))
                            .font(.headline)
                        HStack(spacing: 4) {
                            Text(run.date.formatted(.dateTime.month(.abbreviated).day().year()))
                            if run.healthID != nil {
                                Image(systemName: "heart.fill")
                                    .foregroundStyle(.pink)
                                    .accessibilityLabel("From Apple Health")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if let seconds = run.seconds {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(RaceTime.format(seconds))
                                .font(.headline.monospacedDigit())
                            if let pace = RaceTime.pace(seconds: seconds, kilometres: run.kilometres) {
                                Text(pace)
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .onDelete { offsets in
                for index in offsets { context.delete(runs[index]) }
            }
        } header: {
            Text("Runs")
        } footer: {
            Text("Log any run outside a plan. It counts on the Ran grid and towards your distance badges. Runs from Apple Health (marked with a heart) come in automatically when it's turned on in Settings.")
        }
        .sheet(isPresented: $showingLog) {
            LogRunSheet()
        }
        .task { await HealthRunImporter.importNewRuns(into: context) }
    }
}

private struct LogRunSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var date = Date()
    @State private var distanceText = ""
    @State private var timeText = ""

    private var kilometres: Double? {
        Double(distanceText.replacingOccurrences(of: ",", with: ".")).flatMap { $0 > 0 ? $0 : nil }
    }
    private var seconds: Int? { timeText.isEmpty ? nil : RaceTime.parse(timeText) }
    private var isValid: Bool { kilometres != nil && (timeText.isEmpty || seconds != nil) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)
                    LabeledContent("Distance") {
                        HStack(spacing: 4) {
                            TextField("0", text: $distanceText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(minWidth: 120)
                            Text("km").foregroundStyle(.secondary)
                        }
                    }
                    LabeledContent("Time") {
                        TextField("Optional, h:mm:ss", text: $timeText)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                            .frame(minWidth: 160)
                    }
                } footer: {
                    if let kilometres, let seconds, let pace = RaceTime.pace(seconds: seconds, kilometres: kilometres) {
                        Text("Pace \(pace)")
                    } else if !timeText.isEmpty && seconds == nil {
                        Text("Enter time as minutes:seconds or hours:minutes:seconds, e.g. 28:45.")
                    }
                }
            }
            .navigationTitle("Log a Run")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let kilometres {
                            context.insert(LoggedRun(date: date, kilometres: kilometres, seconds: seconds))
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
