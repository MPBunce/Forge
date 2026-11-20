//
//  RestLiveActivity.swift
//  ForgeWidget
//
//  The rest countdown on the Lock Screen and in the Dynamic Island.
//

import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

struct RestLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestActivityAttributes.self) { context in
            HStack(spacing: 14) {
                Image(systemName: "timer")
                    .font(.title2)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rest").font(.caption).foregroundStyle(.white.opacity(0.7))
                    Text(timerInterval: context.state.startDate...context.state.endDate, countsDown: true)
                        .font(.system(.title, design: .rounded, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
                Spacer()
                Button(intent: AddRestTimeIntent()) {
                    Text("+30s").font(.subheadline.weight(.semibold))
                }
                .tint(.blue)
                Button(intent: SkipRestIntent()) {
                    Text("Skip").font(.subheadline.weight(.semibold))
                }
                .tint(.orange)
            }
            .padding(16)
            .activityBackgroundTint(Color.black.opacity(0.85))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("Rest", systemImage: "timer")
                        .foregroundStyle(.orange)
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: context.state.startDate...context.state.endDate, countsDown: true)
                        .font(.system(.title2, design: .rounded, weight: .semibold))
                        .monospacedDigit()
                        .frame(maxWidth: 80)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Button(intent: AddRestTimeIntent()) { Text("+30s").frame(maxWidth: .infinity) }
                            .tint(.blue)
                        Button(intent: SkipRestIntent()) { Text("Skip").frame(maxWidth: .infinity) }
                            .tint(.orange)
                    }
                }
            } compactLeading: {
                Image(systemName: "timer").foregroundStyle(.orange)
            } compactTrailing: {
                Text(timerInterval: context.state.startDate...context.state.endDate, countsDown: true)
                    .monospacedDigit()
                    .frame(maxWidth: 44)
            } minimal: {
                Image(systemName: "timer").foregroundStyle(.orange)
            }
        }
    }
}
