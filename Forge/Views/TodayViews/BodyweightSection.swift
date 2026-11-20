//
//  BodyweightSection.swift
//  Forge
//
//  A quick weigh-in on the Today tab: the latest number, the change over a week, and the
//  last few weeks as a small line.
//

import SwiftUI
import SwiftData
import Charts

struct BodyweightSection: View {
    @Query private var settings: [Settings]
    @State private var entries = BodyweightLog.load()
    @State private var logging = false

    private var usesKg: Bool { settings.first?.usesKilograms ?? false }
    private var unit: String { usesKg ? "kg" : "lbs" }

    private func display(_ pounds: Double) -> Double {
        let value = usesKg ? WeightConverter.lbsToKg(pounds) : pounds
        return (value * 10).rounded() / 10
    }

    var body: some View {
        Section {
            if let latest = entries.last {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(display(latest.pounds), format: .number.precision(.fractionLength(0...1)))
                                .font(.system(.title, design: .rounded, weight: .bold))
                                .monospacedDigit()
                            Text(unit).foregroundStyle(.secondary)
                        }
                        Text(subtitle(latest))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if entries.count >= 2 { trend.frame(width: 110, height: 40) }
                }
                .padding(.vertical, 2)
            } else {
                Text("Weigh in once a week or so to see the trend.")
                    .foregroundStyle(.secondary)
            }
        } header: {
            HStack {
                Text("Bodyweight")
                Spacer()
                Button {
                    logging = true
                } label: {
                    Label("Log", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                        .textCase(nil)
                }
            }
            // On the header, like Daily Work: a sheet on a List section doesn't present.
            .sheet(isPresented: $logging) {
                WeighInSheet(unit: unit, start: entries.last.map { display($0.pounds) }) { value in
                    BodyweightLog.log(pounds: usesKg ? WeightConverter.kgToLbs(value) : value)
                    entries = BodyweightLog.load()
                }
            }
        }
        .onAppear { entries = BodyweightLog.load() }
    }

    private func subtitle(_ latest: WeighIn) -> String {
        let when = Calendar.current.isDateInToday(latest.date) ? "Today" : latest.date.formatted(.dateTime.month(.abbreviated).day())
        guard let change = BodyweightLog.weekChange(entries) else { return when }
        let amount = abs(display(change))
        guard amount >= 0.1 else { return "\(when) · steady this week" }
        return "\(when) · \(change < 0 ? "down" : "up") \(amount.formatted(.number.precision(.fractionLength(0...1)))) \(unit) this week"
    }

    private var trend: some View {
        let recent = Array(entries.suffix(12))
        let values = recent.map { display($0.pounds) }
        let low = (values.min() ?? 0) - 1
        let high = (values.max() ?? 0) + 1
        return Chart(recent) { entry in
            LineMark(x: .value("Date", entry.date), y: .value("Weight", display(entry.pounds)))
                .interpolationMethod(.catmullRom)
            PointMark(x: .value("Date", entry.date), y: .value("Weight", display(entry.pounds)))
                .symbolSize(12)
        }
        .chartYScale(domain: low...high)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .foregroundStyle(.blue)
        .accessibilityLabel("Bodyweight trend over the last \(recent.count) weigh-ins")
    }
}

private struct WeighInSheet: View {
    @Environment(\.dismiss) private var dismiss
    let unit: String
    let start: Double?
    let onSave: (Double) -> Void

    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                Text("Weight (\(unit))").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                TextField("—", text: $text)
                    .font(.system(size: 44, weight: .semibold, design: .rounded).monospacedDigit())
                    .multilineTextAlignment(.center)
                    .keyboardType(.decimalPad)
                    .focused($focused)
                Text("One a day: logging again today replaces it.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.top, 24)
            .navigationTitle("Weigh In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let value = Double(text.replacingOccurrences(of: ",", with: ".")), value > 0 {
                            onSave(value)
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(Double(text.replacingOccurrences(of: ",", with: ".")) == nil)
                }
            }
            .onAppear {
                text = start.map { WeightConverter.format($0) } ?? ""
                focused = true
            }
        }
        .presentationDetents([.height(260)])
    }
}
