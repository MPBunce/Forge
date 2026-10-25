//
//  RestTimer.swift
//  Forge
//
//  Forge Plus: counts down the rest after a set, and notifies you when it's over if
//  Forge is in the background.
//

import Foundation
import Observation
import UserNotifications

@MainActor
@Observable
final class RestTimer {
    static let shared = RestTimer()

    static let durations = [60, 90, 120, 150, 180, 240, 300]
    static let defaultSeconds = 120

    /// The rest setting existed (at 90s) before the timer did, so nobody chose it: move it
    /// to the 2-minute default once.
    static func migrateDefault(_ settings: Settings?) {
        let key = "restTimerDefaultMigrated"
        guard let settings, !UserDefaults.standard.bool(forKey: key) else { return }
        if settings.defaultRestTime == 90 { settings.defaultRestTime = defaultSeconds }
        UserDefaults.standard.set(true, forKey: key)
    }

    /// When the current rest ends, or nil when no rest is running.
    private(set) var endDate: Date?
    private(set) var total: TimeInterval = 0

    private let notificationID = "forge.restTimer"
    private var finishTask: Task<Void, Never>?

    private init() {}

    var isRunning: Bool { endDate.map { $0 > .now } ?? false }

    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: PreferenceKeys.restTimerEnabled) as? Bool ?? true
    }

    /// Starts a rest if Plus is on and the timer isn't switched off.
    func startIfEnabled(seconds: Int) {
        guard ForgePlus.shared.isActive, Self.isEnabled, seconds > 0 else { return }
        start(seconds: TimeInterval(seconds))
    }

    func start(seconds: TimeInterval) {
        total = seconds
        endDate = Date().addingTimeInterval(seconds)
        reschedule()
    }

    func add(_ seconds: TimeInterval) {
        guard let end = endDate else { return }
        let newEnd = max(Date(), end).addingTimeInterval(seconds)
        total += seconds
        endDate = newEnd
        reschedule()
    }

    func stop() {
        endDate = nil
        finishTask?.cancel()
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
    }

    private func reschedule() {
        guard let end = endDate else { return }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notificationID])

        finishTask?.cancel()
        finishTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(max(0, end.timeIntervalSinceNow)))
            guard !Task.isCancelled else { return }
            self?.endDate = nil
        }

        let id = notificationID
        Task {
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Rest over"
            content.body = "Time for your next set."
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, end.timeIntervalSinceNow), repeats: false)
            try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }
    }
}
