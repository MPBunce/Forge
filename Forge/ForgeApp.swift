//
//  ForgeApp.swift
//  Forge
//
//  Created by Matthew Bunce on 2025-05-28.
//

import SwiftUI
import SwiftData
import CoreData

enum ForgeCloud {
    static let containerID = "iCloud.mpbunce.Strength-Cycles"

    static let models: [any PersistentModel.Type] = [
        Cycles.self, TrainingDay.self, Exercise.self, ExerciseSet.self,
        Goal.self, Settings.self, CustomTemplate.self, DailyWorkItem.self, DailyWorkEntry.self,
        StretchEntry.self, RunPlan.self, RaceResult.self, CustomRunPlan.self, LoggedRun.self, Challenge.self,
    ]

    #if DEBUG
    /// Creates every record type in the iCloud development database so the schema can be
    /// deployed to production in the CloudKit Console. Run once on a device signed in to
    /// iCloud by launching with `-ForgeInitCloudSchema`.
    static func initializeSchema(at url: URL) {
        guard ProcessInfo.processInfo.arguments.contains("-ForgeInitCloudSchema") else { return }
        autoreleasepool {
            let description = NSPersistentStoreDescription(url: url)
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: containerID)
            description.shouldAddStoreAsynchronously = false
            guard let model = NSManagedObjectModel.makeManagedObjectModel(for: models) else { return }
            let container = NSPersistentCloudKitContainer(name: "Forge", managedObjectModel: model)
            container.persistentStoreDescriptions = [description]
            container.loadPersistentStores { _, error in
                if let error { print("CloudKit schema: couldn't load store: \(error)") }
            }
            do {
                try container.initializeCloudKitSchema()
                print("CloudKit schema: initialized")
            } catch {
                print("CloudKit schema: failed: \(error)")
            }
            for store in container.persistentStoreCoordinator.persistentStores {
                try? container.persistentStoreCoordinator.remove(store)
            }
        }
    }
    #endif
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
        // Syncs through the user's private iCloud database; works offline and without an
        // iCloud account, and merges once one is available.
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory,
                                                    cloudKitDatabase: inMemory ? .none : .private(ForgeCloud.containerID))

        #if DEBUG
        if !inMemory { ForgeCloud.initializeSchema(at: modelConfiguration.url) }
        #endif
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
