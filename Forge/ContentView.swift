//
//  ContentView.swift
//  Forge
//
//  Created by Matthew Bunce on 2025-05-28.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = DemoData.launchTab
    /// Set when a streak widget is tapped, to open that habit's history.
    @State private var openedMetric: ActivityMetric?

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "calendar")
                }
                .tag(0)
            CyclesView()
                .tabItem {
                    Label("Training", systemImage: "figure.strengthtraining.traditional")
                }
                .tag(1)
            ProgressTabView(openedMetric: $openedMetric)
                .tabItem {
                    Label("Progress", systemImage: "chart.bar")
                }
                .tag(2)
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .syncsActivityWidgets()
        .onOpenURL { url in
            // The Next Workout widget.
            if url.scheme == "forge", url.host == "training" {
                selectedTab = 1
                return
            }
            guard let metric = ActivityMetric(url: url) else { return }
            selectedTab = 2
            openedMetric = metric
        }
    }
}


#Preview {
    ContentView()
        .modelContainer(for: [Cycles.self, Goal.self, Settings.self, CustomTemplate.self, DailyWorkItem.self, DailyWorkEntry.self, StretchEntry.self, RunPlan.self, RaceResult.self, LoggedRun.self, CustomRunPlan.self, Challenge.self], inMemory: true)
}
