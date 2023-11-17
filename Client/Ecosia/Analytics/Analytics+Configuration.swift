// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SnowplowTracker
import Core

extension Analytics {
    
    static let trackerConfiguration = TrackerConfiguration()
        .appId(Bundle.version)
        .sessionContext(true)
        .applicationContext(true)
        .platformContext(true)
        .platformContextProperties([]) // track minimal device properties
        .geoLocationContext(true)
        .deepLinkContext(false)
        .screenContext(false)
    
    static let subjectConfiguration = SubjectConfiguration()
        .userId(User.shared.analyticsId.uuidString)

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
}

extension Analytics {
    
    /// Function to check if a day has passed since the last check for a specific identifier.
    /// - Parameter identifier: The unique identifier used to save the last check date in UserDefaults.
    /// - Returns: Boolean. True if a day or more has passed since the last check OR in case of first time checking, False otherwise.
    static func hasDayPassedSinceLastCheck(for identifier: String) -> Bool {
        let now = Date()
        let defaults = UserDefaults.standard
        
        // get the date of the last check from UserDefaults
        if let lastCheck = defaults.object(forKey: identifier) as? Date {
            // calculate the difference in days between now and the last check
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
            // if the last check date does not exist in UserDefaults, set it to now
            // We return `true` in this special scenario to mark the fact that there was no last check
            defaults.set(now, forKey: identifier)
            return true
        }
        
        return false
    }
}
