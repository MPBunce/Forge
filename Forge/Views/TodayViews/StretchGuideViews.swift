//
//  StretchGuideViews.swift
//  Forge
//
//  How to do each stretch, and a follow-along mode that walks through a routine one
//  stretch at a time with a hold timer.
//

import SwiftUI

/// One stretch: steps, where to feel it, a tip, and a link to watch it done.
struct StretchDetailView: View {
    let stretch: Stretch
    var number: Int? = nil

    var body: some View {
        List {
            Section {
                HStack(spacing: 10) {
                    Label(stretch.hold, systemImage: "timer")
                    if stretch.sides == 2 && !stretch.hold.contains("each") {
                        Text("· each side").foregroundStyle(.secondary)
                    }
                }
                .font(.subheadline)
            }
            StretchInstructions(stretch: stretch)
        }
        .navigationTitle(stretch.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// The steps, feel, tip and video link, shared by the detail page and follow-along.
private struct StretchInstructions: View {
    let stretch: Stretch

    var body: some View {
        Section("How to do it") {
            ForEach(Array(stretch.instructions.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 18)
                    Text(step)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 2)
            }
        }
        if !stretch.feel.isEmpty || !stretch.tip.isEmpty {
            Section {
                if !stretch.feel.isEmpty {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Where you'll feel it").font(.caption).foregroundStyle(.secondary)
                            Text(stretch.feel)
                        }
                    } icon: {
                        Image(systemName: "scope")
                    }
                }
                if !stretch.tip.isEmpty {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Tip").font(.caption).foregroundStyle(.secondary)
                            Text(stretch.tip)
                        }
                    } icon: {
                        Image(systemName: "lightbulb")
                    }
                }
            }
        }
        if let url = stretch.videoSearchURL {
            Section {
                Link(destination: url) {
                    Label("Watch how it's done", systemImage: "play.rectangle")
                }
            } footer: {
                Text("Searches YouTube for this stretch.")
            }
        }
    }
}

/// Walks through a routine one stretch at a time, with a hold timer for timed stretches.
struct StretchFollowAlong: View {
    @Environment(\.dismiss) private var dismiss
    let routine: StretchRoutine
    let onFinish: () -> Void

    @State private var index = 0
    @State private var side = 1
    @State private var remaining: Int?
    @State private var timer: Timer?

    private var stretch: Stretch { routine.stretches[index] }
    private var isLast: Bool { index == routine.stretches.count - 1 && side >= stretch.sides }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Stretch \(index + 1) of \(routine.stretches.count)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(stretch.name)
                            .font(.title2.weight(.bold))
                        HStack {
                            Text(stretch.hold)
                            if stretch.sides == 2 {
                                Text("· \(side == 1 ? "first" : "second") side")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        ProgressView(value: Double(index), total: Double(routine.stretches.count))
                    }
                    .padding(.vertical, 4)

                    if let seconds = stretch.seconds {
                        timerControl(seconds: seconds)
                    }
                }

                StretchInstructions(stretch: stretch)
            }
            .navigationTitle(routine.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { stop(); dismiss() }
                }
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Button {
                            back()
                        } label: {
                            Label("Back", systemImage: "chevron.left")
                        }
                        .disabled(index == 0 && side == 1)
                        Spacer()
                        Button {
                            next()
                        } label: {
                            Text(isLast ? "Finish" : (stretch.sides == 2 && side == 1 ? "Other Side" : "Next"))
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .onDisappear(perform: stop)
        }
    }

    private func timerControl(seconds: Int) -> some View {
        HStack {
            Text(format(remaining ?? seconds))
                .font(.system(size: 44, weight: .light).monospacedDigit())
                .contentTransition(.numericText(countsDown: true))
            Spacer()
            if timer != nil {
                Button("Pause") { stop() }
                    .buttonStyle(.bordered)
            } else {
                Button(remaining == 0 ? "Again" : "Start") { start(seconds: seconds) }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(.vertical, 4)
    }

    private func format(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private func start(seconds: Int) {
        if remaining == nil || remaining == 0 { remaining = seconds }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                guard let left = remaining, left > 0 else { return }
                withAnimation { remaining = left - 1 }
                if left - 1 == 0 {
                    stop()
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
        }
    }

    private func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func next() {
        stop()
        remaining = nil
        if stretch.sides == 2 && side == 1 {
            side = 2
        } else if index < routine.stretches.count - 1 {
            index += 1
            side = 1
        } else {
            onFinish()
            dismiss()
        }
    }

    private func back() {
        stop()
        remaining = nil
        if side == 2 {
            side = 1
        } else if index > 0 {
            index -= 1
            side = routine.stretches[index].sides
        }
    }
}
