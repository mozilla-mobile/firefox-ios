// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol TelemetryRecording {
    func recordShareExtensionOpened()
}

final class TelemetryService: TelemetryRecording {
    private let bundleConfiguration: BundleConfigurationProviding
    private let telemetryKey = "profile.AppExtensionTelemetryOpenUrl"

    init(bundleConfiguration: BundleConfigurationProviding = BundleConfiguration()) {
        self.bundleConfiguration = bundleConfiguration
    }

    func recordShareExtensionOpened() {
        guard let sharedContainerIdentifier = bundleConfiguration.sharedContainerIdentifier,
              let userDefaults = UserDefaults(suiteName: sharedContainerIdentifier) else {
            return
        }

        userDefaults.set(true, forKey: telemetryKey)
    }
}
