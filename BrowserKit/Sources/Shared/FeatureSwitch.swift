// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

/// Steadily growing set of feature switches controlling access to features by populations of Release users.
open class FeatureSwitches {
}

/// Small class to allow a percentage of users to access a given feature.
/// It is deliberately low tech, and is not remotely changeable.
/// Randomized bucketing is only applied when the app's release build channel.
open class FeatureSwitch {
    let featureID: String
    let buildChannel: AppBuildChannel
    let nonChannelValue: Bool
    let percentage: Int
    fileprivate let switchKey: String
    init(
        named featureID: String,
        _ value: Bool = true,
        allowPercentage percentage: Int,
        buildChannel: AppBuildChannel = .release
    ) {
        self.featureID = featureID
        self.percentage = percentage
        self.buildChannel = buildChannel
        self.nonChannelValue = value
        self.switchKey = "feature_switches.\(self.featureID)"
    }

    /// Is this user a member of the bucket that is allowed to use this feature.
    /// Bucketing is decided with the hash of a UUID, which is randomly generated and cached
    /// in the preferences.
    /// This gives us stable properties across restarts and new releases.
    open func isMember(_ prefs: Prefs) -> Bool {
        // Only use bucketing if we're in the correct build channel, and feature flag is true.
        guard buildChannel == AppConstants.buildChannel, nonChannelValue else {
            return nonChannelValue
        }

        // Check if this feature has been enabled by the user
        let key = "\(self.switchKey).enabled"
        if let isEnabled = prefs.boolForKey(key) {
            return isEnabled
        }

        return lowerCaseS(prefs) < self.percentage
    }

    /// Is this user always a member of the test set, whatever the percentage probability?
    /// This _only_ tests the probabilities, not the other conditions.
    open func alwaysMembership(_ prefs: Prefs) -> Bool {
        return lowerCaseS(prefs) == 99
    }

    /// Reset the random component of this switch (`lowerCaseS`). This is primarily useful for testing.
    open func resetMembership(_ prefs: Prefs) {
        let uuidKey = "\(self.switchKey).uuid"
        prefs.removeObjectForKey(uuidKey)
    }

    // If the set of all possible values the switch can be in is `S` (integers between 0 and 99)
    // then the specific value is `s`.
    // We use this to compare with the probability of membership.
    fileprivate func lowerCaseS(_ prefs: Prefs) -> Int {
        // Use a branch of the prefs.
        let uuidKey = "\(self.switchKey).uuid"

        let uuidString: String
        if let string = prefs.stringForKey(uuidKey) {
            uuidString = string
        } else {
            uuidString = UUID().uuidString
            prefs.setString(uuidString, forKey: uuidKey)
        }

        let hash = abs(uuidString.hashValue)

        return hash % 100
    }

    open func setMembership(_ isEnabled: Bool, for prefs: Prefs) {
        let key = "\(self.switchKey).enabled"
        prefs.setBool(isEnabled, forKey: key)
    }
}
