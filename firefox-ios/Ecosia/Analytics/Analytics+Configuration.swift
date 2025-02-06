// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
internal import SnowplowTracker

extension Analytics {

    /// Configuration for the Snowplow tracker.
    /// - Includes settings such as application ID, session context, application context, platform context, and geolocation context.
    /// - This configuration also enables tracking of minimal device properties like Apple ID for vendors (IDFV).
    static let trackerConfiguration = TrackerConfiguration()
        .appId(Bundle.version)
        .sessionContext(true)
        .applicationContext(true)
        .platformContext(true)
        .platformContextProperties([.appleIdfv]) // track minimal device properties
        .geoLocationContext(true)
        .deepLinkContext(false)
        .screenContext(false)

    /// Configuration for the Snowplow subject.
    /// - Sets the user ID using the unique analytics ID associated with the user.
    static let subjectConfiguration = SubjectConfiguration()
        .userId(User.shared.analyticsId.uuidString)

    /// Configuration for the daily tracking plugin.
    /// - This plugin filters events based on whether a day has passed since the last check for a specific identifier.
    /// - It specifically filters structured events related to in-app navigation and resume actions.
    /// - Returns: A configured `PluginConfiguration` that determines whether the event should be tracked.
    static var appResumeDailyTrackingPluginConfiguration: PluginConfiguration {
        let identifier = "appResumeDailyTrackingPluginConfiguration"
        let plugin = PluginConfiguration(identifier: identifier)
        return plugin.filter(schemas: [
            "se" // Structured Events
        ]) { event in
            let isInAppLabel = event.payload["se_la"] as? String == Analytics.Label.Navigation.inapp.rawValue
            let isResumeEvent = event.payload["se_ac"] as? String == Analytics.Action.Activity.resume.rawValue
            let isInAppResumeEvent = isInAppLabel && isResumeEvent

            guard isInAppResumeEvent else {
                return true
            }

            return Self.hasDayPassedSinceLastCheck(for: identifier)
        }
    }

    /// Configuration for the install tracking plugin.
    /// - This plugin filters install events, allowing them to be tracked only if it's the first installation.
    /// - Returns: A configured `PluginConfiguration` that determines whether the event should be tracked.
    static var appInstallTrackingPluginConfiguration: PluginConfiguration {
        let identifier = "appInstallTrackingPluginConfiguration"
        let plugin = PluginConfiguration(identifier: identifier)
        return plugin.filter(schemas: [
            Self.installSchema
        ]) { _ in
            return Self.isFirstInstall(for: identifier)
        }
    }
}

extension Analytics {

    /// Checks if the current installation is the first time the app has been installed.
    /// - Parameter identifier: A unique identifier used to store and retrieve the first install check status from `UserDefaults`.
    /// - Returns: A Boolean value indicating whether the app is being installed for the first time.
    static func isFirstInstall(for identifier: String) -> Bool {
        let defaults = UserDefaults.standard
        let isFirstTime = defaults.object(forKey: identifier) as? Bool ?? {
            defaults.set(false, forKey: identifier)
            return true
        }()
        return isFirstTime && EcosiaInstallType.get() != .upgrade
    }
}

extension Analytics {

    /// Checks if a day has passed since the last check for a specific event.
    /// - Parameter identifier: A unique identifier used to store and retrieve the last check date from `UserDefaults`.
    /// - Returns: A Boolean value indicating whether a day has passed since the last check. If no previous check exists, returns `true` and records the current date.
    public static func hasDayPassedSinceLastCheck(for identifier: String) -> Bool {
        let now = Date()
        let defaults = UserDefaults.standard

        // Retrieve the last check date from UserDefaults
        if let lastCheck = defaults.object(forKey: identifier) as? Date {
            // Calculate the number of days between the last check and now
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day], from: lastCheck, to: now)

            if let day = components.day {
                // if a day or more has passed
                if day >= 1 {
                    defaults.set(now, forKey: identifier) // update the last check date
                    return true
                } else {
                    // less than a day has passed
                    return false
                }
            }
        } else {
            // If no last check date exists, set the current date and return true
            defaults.set(now, forKey: identifier)
            return true
        }

        return false
    }
}
