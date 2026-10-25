//
//  RunPlansView.swift
//  Forge
//
//  The Running side of the Cycles tab: running plans, kept apart from strength cycles.
//

import SwiftUI
import SwiftData

/// List of running plans; lives inside the Cycles tab's navigation stack.
struct RunPlansList: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \RunPlan.startDate, order: .reverse) private var plans: [RunPlan]
    @Binding var showingAddPlan: Bool

    var body: some View {
        List {
            // Plans first: the next run to do matters more than the log of past ones.
            Section("Plans") {
                if plans.isEmpty {
                    Button {
                        showingAddPlan = true
                    } label: {
                        Label("Add a Running Plan", systemImage: "figure.run")
                    }
                }
                ForEach(plans) { plan in
                    NavigationLink {
                        RunPlanDetailView(plan: plan)
                    } label: {
                        RunPlanRow(plan: plan)
                    }
                }
                .onDelete { offsets in
                    for index in offsets { context.delete(plans[index]) }
                }
            }

            SingleRunsSection()
            RacesSection()
        }
        .sheet(isPresented: $showingAddPlan) {
            RunPlanSelectionSheet()
        }
    }
}

private struct RunPlanRow: View {
    let plan: RunPlan

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(plan.name)
                    .font(.headline)
                Text("Started \(plan.startDate.formatted(.dateTime.month(.abbreviated).day()))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TrainingProgress(done: plan.completedCount, total: plan.sessions.count, unit: "runs",
                                 next: plan.nextSession?.title, tint: .orange)
            }
            Spacer()
            if plan.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title2)
            }
        }
        .padding(.vertical, 8)
    }
}

private struct RunPlanSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \CustomRunPlan.createdAt) private var customPlans: [CustomRunPlan]
    @State private var creating = false
    @State private var editing: CustomRunPlan?
    @State private var showingPlus = false
    private var plus = ForgePlus.shared

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(customPlans) { custom in
                        planRow(name: custom.name,
                                summary: custom.details.isEmpty ? nil : custom.details,
                                duration: "\(custom.weekCount) \(custom.weekCount == 1 ? "week" : "weeks") · \(custom.runsPerWeek) runs a week") {
                            context.insert(custom.createPlan())
                            dismiss()
                        }
                        .swipeActions {
                            Button("Delete", role: .destructive) { context.delete(custom) }
                            Button("Edit") {
                                if plus.isActive { editing = custom } else { showingPlus = true }
                            }
                            .tint(.blue)
                        }
                    }
                    Button {
                        if plus.isActive { creating = true } else { showingPlus = true }
                    } label: {
                        HStack {
                            Label("Create Running Plan", systemImage: plus.isActive ? "plus" : "lock")
                            if !plus.isActive {
                                Spacer()
                                PlusBadge()
                            }
                        }
                    }
                } header: {
                    Text("My Plans")
                } footer: {
                    if !customPlans.isEmpty {
                        Text("Swipe a plan to edit or delete it.")
                    }
                }

                Section("Plans") {
                    ForEach(RunPlanTemplate.all) { template in
                        planRow(name: template.name, summary: template.summary, duration: template.duration) {
                            context.insert(template.createPlan())
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Select a Running Plan")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $creating) {
                RunPlanEditorView(plan: nil)
            }
            .navigationDestination(item: $editing) { custom in
                RunPlanEditorView(plan: custom)
            }
            .navigationDestination(isPresented: $showingPlus) {
                ForgePlusView()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func planRow(name: String, summary: String?, duration: String, onSelect: @escaping () -> Void) -> some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                if let summary {
                    Text(summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(duration)
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Plan detail

struct RunPlanDetailView: View {
    @Bindable var plan: RunPlan
    @State private var openSession: RunSession?

    private var weeks: [(week: Int, sessions: [RunSession])] {
        Dictionary(grouping: plan.orderedSessions, by: \.week)
            .sorted { $0.key < $1.key }
            .map { ($0.key, $0.value) }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(plan.completedCount) of \(plan.sessions.count) runs done")
                        .font(.subheadline.weight(.semibold))
                    SwiftUI.ProgressView(value: Double(plan.completedCount), total: Double(max(plan.sessions.count, 1)))
                        .tint(.orange)
                }
                .padding(.vertical, 4)
            }

            ForEach(weeks, id: \.week) { week in
                Section("Week \(week.week)") {
                    ForEach(week.sessions) { session in
                        RunSessionRow(session: session,
                                      isNext: session.id == plan.nextSession?.id,
                                      onToggle: { toggle(session) },
                                      onOpen: { openSession = session })
                    }
                }
            }
        }
        .navigationTitle(plan.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $openSession) { session in
            RunSessionSheet(plan: plan, sessionID: session.id)
        }
    }

    private func toggle(_ session: RunSession) {
        withAnimation {
            plan.setCompleted(session.id, on: session.isCompleted ? nil : Date())
        }
    }
}

struct RunSessionRow: View {
    let session: RunSession
    var isNext: Bool = false
    let onToggle: () -> Void
    let onOpen: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: session.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(session.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(session.isCompleted ? "Mark not done" : "Mark done")

            Button(action: onOpen) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("Run \(session.number)")
                                .foregroundStyle(.primary)
                            if isNext {
                                Text("NEXT")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.orange)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.15), in: Capsule())
                            }
                        }
                        Text(session.summary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let date = session.completedDate {
                            Text("Done \(date.formatted(.dateTime.month(.abbreviated).day()))")
                                .font(.caption2)
                                .foregroundStyle(.green)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Session sheet

/// A session's segments, with the guided timer for timed runs and a manual tick-off.
struct RunSessionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var plan: RunPlan
    let sessionID: UUID
    @State private var guiding = false
    @State private var loggingRace = false
    @State private var distanceText = ""
    @State private var timeText = ""
    @FocusState private var distanceFocused: Bool

    private var session: RunSession? { plan.sessions.first { $0.id == sessionID } }

    var body: some View {
        NavigationStack {
            if let session {
                List {
                    Section {
                        if session.isTimed {
                            Button {
                                guiding = true
                            } label: {
                                Label("Start Guided Run", systemImage: "play.circle.fill")
                            }
                        }
                        if let race = session.raceDistance {
                            Button {
                                loggingRace = true
                            } label: {
                                Label("Log \(race.name) Result", systemImage: "flag.checkered")
                            }
                            .sheet(isPresented: $loggingRace) {
                                LogRaceSheet(initialDistance: race)
                            }
                        }
                        if session.isCompleted {
                            LabeledContent {
                                HStack(spacing: 4) {
                                    TextField(session.isTimed ? "Enter" : session.runningKilometres.formatted(.number.precision(.fractionLength(0...1))),
                                              text: $distanceText)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .focused($distanceFocused)
                                        .frame(maxWidth: 90)
                                    Text("km").foregroundStyle(.secondary)
                                }
                            } label: {
                                Label("Distance", systemImage: "ruler")
                            }
                            if !session.isTimed {
                                LabeledContent {
                                    TextField("h:mm:ss", text: $timeText)
                                        .keyboardType(.numbersAndPunctuation)
                                        .multilineTextAlignment(.trailing)
                                        .frame(maxWidth: 110)
                                } label: {
                                    Label("Time", systemImage: "stopwatch")
                                }
                                if let seconds = session.loggedSeconds,
                                   let pace = RaceTime.pace(seconds: seconds, kilometres: session.loggedKilometres ?? session.runningKilometres) {
                                    LabeledContent("Pace", value: pace)
                                }
                            }
                        }
                        Button {
                            plan.setCompleted(session.id, on: session.isCompleted ? nil : Date())
                            if session.isTimed && !session.isCompleted {
                                // Stay open so the distance can be entered.
                                distanceFocused = true
                            } else {
                                dismiss()
                            }
                        } label: {
                            Label(session.isCompleted ? "Mark Not Done" : "Mark Done",
                                  systemImage: session.isCompleted ? "arrow.uturn.backward" : "checkmark.circle")
                        }
                    } footer: {
                        if session.isCompleted && session.isTimed && session.loggedKilometres == nil {
                            Text("Add how far you ran so it counts towards your distance badges.")
                        }
                    }

                    Section {
                        ForEach(Array(session.segments.enumerated()), id: \.offset) { index, segment in
                            SegmentRow(index: index, segment: segment)
                        }
                    } footer: {
                        if session.isTimed {
                            Text("About \(session.totalSeconds / 60) minutes including warm-up and cool-down.")
                        } else {
                            Text("Run at an easy, conversational pace unless it's race day.")
                        }
                    }
                }
                .navigationTitle(session.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }.fontWeight(.semibold)
                    }
                }
                .fullScreenCover(isPresented: $guiding) {
                    GuidedRunView(session: session) {
                        plan.setCompleted(session.id, on: Date())
                        // Back on this sheet, ready for the distance.
                        distanceFocused = true
                    }
                }
                .onAppear {
                    distanceText = session.loggedKilometres.map { RunSegment.formatKm($0).replacingOccurrences(of: " km", with: "") } ?? ""
                    timeText = session.loggedSeconds.map(RaceTime.format) ?? ""
                }
                .onChange(of: timeText) { _, text in
                    plan.setTime(session.id, seconds: text.isEmpty ? nil : RaceTime.parse(text))
                }
                .onChange(of: distanceText) { _, text in
                    let value = Double(text.replacingOccurrences(of: ",", with: "."))
                    plan.setDistance(session.id, kilometres: text.isEmpty ? nil : value)
                }
            }
        }
    }
}

private struct SegmentRow: View {
    let index: Int
    let segment: RunSegment

    var body: some View {
        HStack(spacing: 12) {
            Text("\(index + 1)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Image(systemName: segment.kind.isRunning ? "figure.run" : "figure.walk")
                .foregroundStyle(segment.kind.isRunning ? .orange : .green)
                .frame(width: 24)
            Text(segment.label)
        }
    }
}
