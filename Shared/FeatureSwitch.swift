/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/// Steadily growing set of feature switches controlling access to features by populations of Release users.
open class FeatureSwitches {
    open static let activityStream =
        FeatureSwitch(named: "activity_stream", AppConstants.MOZ_AS_PANEL, allowPercentage: 10)
}

/// Small class to allow a percentage of users to access a given feature.
/// It is deliberately low tech, and is not remotely changeable.
/// Randomized bucketing is only applied when the app's release build channel.
open class FeatureSwitch {
    let featureID: String
    let buildChannel: AppBuildChannel
    let nonChannelValue: Bool
    let percentage: Int

    init(named featureID: String, _ value: Bool = true, allowPercentage percentage: Int, buildChannel: AppBuildChannel = .release) {
        self.featureID = featureID
        self.percentage = percentage
        self.buildChannel = buildChannel
        self.nonChannelValue = value
    }

    /// Is this user a member of the bucket that is allowed to use this feature.
    /// Bucketing is decided with the hash of a UUID, which is randomly generated and cached 
    /// in the preferences.
    /// This gives us stable properties across restarts and new releases.
    open func isMember(_ prefs: Prefs) -> Bool {
        // Only use bucketing if we're in the correct build channel, and feature flag is true.
        guard buildChannel == AppConstants.BuildChannel, nonChannelValue else {
            return nonChannelValue
        }

        // Use a branch of the prefs.
        let uuidKey = "feature_switches/\(self.featureID)_uuid"

        let uuidString: String
        if let string = prefs.stringForKey(uuidKey) {
            uuidString = string
        } else {
            uuidString = UUID().uuidString
            prefs.setString(uuidString, forKey: uuidKey)
        }

        let hash = abs(uuidString.hashValue)
        return hash % 100 < self.percentage
    }
}
