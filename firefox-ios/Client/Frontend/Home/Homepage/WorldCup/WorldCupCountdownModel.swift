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
    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

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

    var onCountdownUpdated: ((WorldCupCountdown) -> Void)?
    /// Called once when the countdown reaches zero (i.e. `now >= targetDate`).
    /// The model stops its internal timer before invoking the callback.
    var onWorldCupStarted: (() -> Void)?

    private var timer: Timer?
    private let now: () -> Date
    private var hasNotifiedStart = false

    init(
        nimbusFeature: FeatureHolder<WorldCupWidgetFeature> = FxNimbus.shared.features.worldCupWidgetFeature,
        now: @escaping () -> Date = { Date() }
    ) {
        self.nimbusFeature = nimbusFeature
        self.now = now
    }

    func start() {
        stop()
        fire()
        guard timer == nil, !hasReachedZero else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.fire()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
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

    private var hasReachedZero: Bool {
        return now() >= targetDate
    }

    private func fire() {
        onCountdownUpdated?(currentCountdown)
        guard hasReachedZero, !hasNotifiedStart else { return }
        hasNotifiedStart = true
        stop()
        onWorldCupStarted?()
    }
}
