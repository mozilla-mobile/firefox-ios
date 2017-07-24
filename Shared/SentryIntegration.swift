/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Sentry

public class SentryIntegration {
    public static let shared = SentryIntegration()

    public static var crashedLastLaunch: Bool {
        return Client.shared?.crashedLastLaunch() ?? false
    }

    private let SentryDSNKey = "SentryDSN"

    private var enabled = false

    public func setup(sendUsageData: Bool) {
        assert(!enabled, "SentryIntegration.setup() should only be called once")

        if DeviceInfo.isSimulator() {
            Logger.browserLogger.error("Not enabling Sentry; Running in Simulator")
            return
        }

        if !sendUsageData {
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
            enabled = true
        } catch let error {
            Logger.browserLogger.error("Failed to initialize Sentry: \(error)")
        }

    }

    public func crash() {
        Client.shared?.crash()
    }
    
    public func send(message: String, tag: String = "general", severity: SentrySeverity = .info, completion: SentryRequestFinished? = nil) {
        if !enabled {
            if completion != nil {
                completion!(nil)
            }
            return
        }

        let event = Event(level: severity)
        event.message = message
        event.tags = ["event": tag]

        Client.shared?.send(event: event, completion: completion)
    }

    public func sendWithStacktrace(message: String, tag: String = "general", severity: SentrySeverity = .info, completion: SentryRequestFinished? = nil) {
        if !enabled {
            if completion != nil {
                completion!(nil)
            }
            return
        }

        Client.shared?.snapshotStacktrace {
            let event = Event(level: severity)
            event.message = message
            event.tags = ["event": tag]

            Client.shared?.appendStacktrace(to: event)
            event.debugMeta = nil
            Client.shared?.send(event: event, completion: completion)
        }
    }
}
