/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Sentry

public class SentryIntegration {
    public static let shared = SentryIntegration()

    public static var crashedLastLaunch: Bool {
        return SentrySDK.crashedLastRun
    }

    private let SentryDSNKey = "SentryDSN"

    private var enabled = false

    public func setup(sendUsageData: Bool) {
        assert(!enabled, "SentryIntegration.setup() should only be called once")

        if AppInfo.isSimulator() {
            print("Not starting Sentry: running in the simulator")
            return
        }

        if !sendUsageData {
            print("Not starting Sentry: disabled by user")
            return
        }

        guard let dsn = Bundle.main.object(forInfoDictionaryKey: SentryDSNKey) as? String, !dsn.isEmpty else {
            print("Not starting Sentry: \(SentryDSNKey) is missing or empty in Info.plist")
            return
        }

        SentrySDK.start { options in
            options.dsn = dsn
        }
                    
        enabled = true
    }

    public func crash() {
        SentrySDK.crash()
    }
}
