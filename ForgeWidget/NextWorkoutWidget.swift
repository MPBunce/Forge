//
//  NextWorkoutWidget.swift
//  ForgeWidget
//
//  The next lifting day and its exercises; tapping it opens Training.
//

import SwiftUI
import WidgetKit

struct NextWorkoutEntry: TimelineEntry {
    let date: Date
    let workout: NextWorkoutSnapshot?
}

struct NextWorkoutProvider: TimelineProvider {
    private static let sample = NextWorkoutSnapshot(program: "Upper Lower (4 Day)", dayName: "Mon · Upper",
                                                    exercises: ["Bench Press", "Barbell Row", "Lateral Raise", "Curl", "Tricep Pushdown"],
                                                    doneToday: false)

    func placeholder(in context: Context) -> NextWorkoutEntry { NextWorkoutEntry(date: .now, workout: Self.sample) }

    func getSnapshot(in context: Context, completion: @escaping (NextWorkoutEntry) -> Void) {
        completion(NextWorkoutEntry(date: .now, workout: NextWorkoutSnapshot.load() ?? (context.isPreview ? Self.sample : nil)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextWorkoutEntry>) -> Void) {
        // Forge reloads this whenever a day is marked done; midnight clears "done today".
        let midnight = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: .now)) ?? .now
        completion(Timeline(entries: [NextWorkoutEntry(date: .now, workout: NextWorkoutSnapshot.load())],
                            policy: .after(midnight.addingTimeInterval(60))))
    }
}

struct NextWorkoutView: View {
    @Environment(\.widgetFamily) private var family
    let entry: NextWorkoutEntry

    var body: some View {
        Group {
            if let workout = entry.workout {
                content(workout)
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "dumbbell")
                        .font(.title2)
                    Text("Start a program in Forge")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(.background, for: .widget)
        .widgetURL(URL(string: "forge://training"))
    }

    private func content(_ workout: NextWorkoutSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: workout.doneToday ? "checkmark.circle.fill" : "dumbbell.fill")
                    .foregroundStyle(workout.doneToday ? .green : .blue)
                Text(workout.doneToday ? "DONE TODAY · NEXT" : "NEXT WORKOUT")
                    .foregroundStyle(.secondary)
            }
            .font(.caption2.weight(.semibold))
            Text(workout.dayName)
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Text(workout.program)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer(minLength: 4)
            if family == .systemSmall {
                Text("\(workout.exercises.count) exercises")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                let shown = workout.exercises.prefix(family == .systemLarge ? 10 : 4)
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(shown.enumerated()), id: \.offset) { _, name in
                        Text("· \(name)").font(.caption).lineLimit(1)
                    }
                    if workout.exercises.count > shown.count {
                        Text("+ \(workout.exercises.count - shown.count) more")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

struct NextWorkoutWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ForgeNextWorkout", provider: NextWorkoutProvider()) { entry in
            NextWorkoutView(entry: entry)
        }
        .configurationDisplayName("Next Workout")
        .description("Your next lifting day and its exercises. Tap to open Training.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
