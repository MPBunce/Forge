//
//  ForgeApp.swift
//  Forge
//
//  Created by Matthew Bunce on 2025-05-28.
//

import SwiftUI
import SwiftData

enum ForgeCloud {
    static let containerID = "iCloud.mpbunce.Strength-Cycles"
}

@main
struct ForgeApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Cycles.self,
            Goal.self,
            Settings.self,
            CustomTemplate.self,
            DailyWorkItem.self,
            DailyWorkEntry.self,
            StretchEntry.self,
            RunPlan.self,
            RaceResult.self,
            CustomRunPlan.self,
            LoggedRun.self,
            Challenge.self
        ])
        #if DEBUG
        // Screenshot demo data lives in memory only, so it never touches the real store.
        let inMemory = DemoData.isEnabled
        #else
        let inMemory = false
        #endif
        // iCloud sync is on hold: the models are ready for it (defaults everywhere, optional
        // inverse relationships), so turning it on later is `.private(ForgeCloud.containerID)` here,
        // plus the iCloud entitlements and a CloudKit schema deployment.
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory,
                                                    cloudKitDatabase: .none)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            #if DEBUG
            if DemoData.isEnabled {
                MainActor.assumeIsolated { DemoData.seed(into: container.mainContext) }
            }
            #endif
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    /// The quote shows on first launch only (and always in screenshot demo mode).
    @State private var showingSplash: Bool = {
        #if DEBUG
        if DemoData.isEnabled { return true }
        #endif
        return !UserDefaults.standard.bool(forKey: PreferenceKeys.hasSeenSplash)
    }()
    @AppStorage(PreferenceKeys.appearance) private var appearance = AppearanceMode.system.rawValue

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                if showingSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                        .onTapGesture { dismissSplash() }
                }
            }
            .preferredColorScheme(AppearanceMode(rawValue: appearance)?.colorScheme)
            .task { PlusStore.shared.start() }
            .task {
                guard showingSplash else { return }
                try? await Task.sleep(for: .seconds(3))
                dismissSplash()
            }
        }
        .modelContainer(sharedModelContainer)
    }

    private func dismissSplash() {
        UserDefaults.standard.set(true, forKey: PreferenceKeys.hasSeenSplash)
        withAnimation(.easeInOut(duration: 0.6)) { showingSplash = false }
    }
}
