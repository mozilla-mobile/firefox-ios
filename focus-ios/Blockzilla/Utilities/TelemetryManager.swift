// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class TelemetryManager {
    static let shared = TelemetryManager()

    // Flag to disable/enable the telemetry feature
    let isTelemetryFeatureEnabled = false

    private init() {}

    var isGleanEnabled: Bool {
        // Override the feature using the global flag
        if !isTelemetryFeatureEnabled {
            return false
        }

        // Default to the value in UserDefaults if the feature is not globally disabled
        return Settings.getToggle(.sendAnonymousUsageData)
    }

    var isNewTosEnabled: Bool {
        if let dailyUsagePing = Settings.getToggleIfAvailable(.dailyUsagePing) {
            // If dailyUsagePing is explicitly set, use its value
            return dailyUsagePing
        } else if let sendAnonymousUsageData = Settings.getToggleIfAvailable(.sendAnonymousUsageData) {
            // If dailyUsagePing is not set, fall back to sendAnonymousUsageData
            // Persist this value into dailyUsagePing for future consistency
            Settings.set(sendAnonymousUsageData, forToggle: .dailyUsagePing)
            return sendAnonymousUsageData
        } else {
            // Default to true if neither setting is available
            Settings.set(true, forToggle: .dailyUsagePing)
            return true
        }
    }
}
