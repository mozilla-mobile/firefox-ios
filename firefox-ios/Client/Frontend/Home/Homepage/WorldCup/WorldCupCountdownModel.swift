// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import class MozillaAppServices.FeatureHolder
import Shared

struct WorldCupCountdown {
    let days: Int
    let hours: Int
    let minutes: Int
    let components: DateComponents
}

@MainActor
final class WorldCupCountdownModel {
    static let nowOverrideDidChange = Notification.Name("worldCupNowOverrideDidChange")

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private let prefs: Prefs
    private let nimbusFeature: FeatureHolder<WorldCupWidgetFeature>

    var targetDate: Date {
        let dateString = nimbusFeature.value().countdownTargetDate
        return Self.iso8601Formatter.date(from: dateString) ?? Self.fallbackTargetDate
    }

    private static let fallbackTargetDate: Date = {
        var c = DateComponents()
        c.calendar = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")
        c.year = 2026
        c.month = 6
        c.day = 11
        c.hour = 19
        return c.date!
    }()

    var nowOverride: Date? {
        get {
            guard let interval: TimeInterval = prefs.objectForKey(
                PrefsKeys.HomepageSettings.WorldCupNowOverride
            ) else { return nil }
            return Date(timeIntervalSinceReferenceDate: interval)
        }
        set {
            if let date = newValue {
                prefs.setObject(
                    date.timeIntervalSinceReferenceDate,
                    forKey: PrefsKeys.HomepageSettings.WorldCupNowOverride
                )
            } else {
                prefs.removeObjectForKey(PrefsKeys.HomepageSettings.WorldCupNowOverride)
            }
            NotificationCenter.default.post(name: Self.nowOverrideDidChange, object: nil)
        }
    }

    var onCountdownUpdated: ((WorldCupCountdown) -> Void)?

    private var timer: Timer?
    private var overrideObserver: Any?
    private let now: () -> Date

    init(
        prefs: Prefs,
        nimbusFeature: FeatureHolder<WorldCupWidgetFeature> = FxNimbus.shared.features.worldCupWidgetFeature,
        now: (() -> Date)? = nil
    ) {
        self.prefs = prefs
        self.nimbusFeature = nimbusFeature
        self.now = now ?? {
            guard let interval: TimeInterval = prefs.objectForKey(
                PrefsKeys.HomepageSettings.WorldCupNowOverride
            ) else { return Date() }
            return Date(timeIntervalSinceReferenceDate: interval)
        }
    }

    func start() {
        stop()
        fire()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.fire()
            }
        }
        overrideObserver = NotificationCenter.default.addObserver(
            forName: WorldCupCountdownModel.nowOverrideDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async {
                self?.fire()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        if let observer = overrideObserver {
            NotificationCenter.default.removeObserver(observer)
            overrideObserver = nil
        }
    }

    var currentCountdown: WorldCupCountdown {
        let diff = Calendar.current.dateComponents([.day, .hour, .minute], from: now(), to: targetDate)
        return WorldCupCountdown(
            days: max(diff.day ?? 0, 0),
            hours: max(diff.hour ?? 0, 0),
            minutes: max(diff.minute ?? 0, 0),
            components: diff
        )
    }

    private func fire() {
        onCountdownUpdated?(currentCountdown)
    }
}
