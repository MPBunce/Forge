//
//  RestTimerBar.swift
//  Forge
//
//  Forge Plus: the rest countdown that appears after you tick off a set.
//

import SwiftUI

struct RestTimerBar: View {
    private var timer = RestTimer.shared

    var body: some View {
        if let end = timer.endDate {
            HStack(spacing: 14) {
                Image(systemName: "timer")
                    .font(.title3)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Rest")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(timerInterval: Date()...max(end, Date()), countsDown: true)
                        .font(.title2.weight(.semibold).monospacedDigit())
                }
                Spacer()
                Button("+30s") { timer.add(30) }
                    .buttonStyle(.bordered)
                Button("Skip") { withAnimation { timer.stop() } }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 12)
            .padding(.bottom, 6)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .sensoryFeedback(.success, trigger: timer.endDate == nil)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Rest timer")
        }
    }
}
