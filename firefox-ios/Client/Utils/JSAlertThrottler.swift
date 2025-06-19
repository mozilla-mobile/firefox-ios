// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Utility that tracks Javascript alert presentations shown
/// over a short span of time, to prevent abuse or DOS attacks.
final class JSAlertThrottler {
    struct Thresholds {
        static let maxConsecutiveAlerts = 5
        static let defaultResetTime: TimeInterval = 20
    }
    var alertCount = 0
    var lastAlertDate = Date.distantPast
    private let timespan: TimeInterval

    init(resetTime: TimeInterval = Thresholds.defaultResetTime) {
        timespan = resetTime
    }

    // MARK: - Public API

    func canShowAlert() -> Bool {
        let alertCountOK = alertCount < Thresholds.maxConsecutiveAlerts
        let timeOK = lastAlertDate.timeIntervalSinceNow < (timespan * -1.0)
        return alertCountOK || timeOK
    }

    func willShowJSAlert() {
        let timeSinceLastAlert = lastAlertDate.timeIntervalSinceNow * -1.0
        if timeSinceLastAlert >= timespan {
            // Our reasonable time limit has passed, which means we can reset our
            // alert count and allow any further alerts.
            alertCount = 1
            lastAlertDate = Date()
        } else {
            alertCount += 1
        }
    }
}
