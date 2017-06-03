/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Sentry

class SentryIntegration {
    static let shared = SentryIntegration()

    private let SentryDSNKey = "SentryDSN"

    var enabled = false

    func setup(profile: Profile) {
        assert(!enabled, "SentryIntegration.setup() should only be called once")

        if !(profile.prefs.boolForKey("settings.sendUsageData") ?? true) {
            Logger.browserLogger.error("Not enabling Sentry; Not enabled by user choice")
            return
        }

        guard let dsn = Bundle.main.object(forInfoDictionaryKey: SentryDSNKey) as? String, !dsn.isEmpty else {
            Logger.browserLogger.error("Not enabling Sentry; Not configured in Info.plist")
            return
        }

        Logger.browserLogger.error("Enabling Sentry crash handler")
        
        do {
            Client.shared = try Client(dsn: dsn)
            try Client.shared?.startCrashHandler()
        } catch let error {
            Logger.browserLogger.error("Failed to initialize Sentry: \(error)")
        }

    }

    var crashedLastLaunch: Bool {
        return Client.shared?.crashedLastLaunch() ?? false
    }

    func crash() {
        Client.shared?.crash()
    }
}
