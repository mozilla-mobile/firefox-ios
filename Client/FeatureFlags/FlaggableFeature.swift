/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared

struct FlaggableFeature {
    // MARK: - Variables
    private let profile: Profile
    private let buildChannels: [AppBuildChannel]

    var featureID: FeatureFlagName

    /// Returns whether or not the feature is active.
    ///
    /// This variable returns a `Bool` based on a priority queue.
    ///
    /// 1. It will check whether or not there exists a value for
    /// the feature written on disk. Users generally set these states
    /// from the debug menu and, if they have set something manually,
    /// we will respect that and return the respective value.
    ///
    /// 2. If there is no setting written to the disk, then every feature
    /// has an underlying default state for each build channel (Release,
    /// Beta, Developer) and that value will be returned.
    var isActive: Bool {
        if let key = featureKey(), let existingPref = profile.prefs.boolForKey(key) {
            return existingPref

        } else {
            #if MOZ_CHANNEL_RELEASE
            return buildChannels.contains(.release)
            #elseif MOZ_CHANNEL_BETA
            return buildChannels.contains(.beta)
            #elseif MOZ_CHANNEL_FENNEC
            return buildChannels.contains(.developer)
            #else
            return buildChannels.contains(.other)
            #endif
        }
    }

    init(withID featureID: FeatureFlagName, and profile: Profile, enabledFor channels: [AppBuildChannel]) {
        self.featureID = featureID
        self.profile = profile
        self.buildChannels = channels
    }

    /// Toggles a feature On or Off, and saves the status to UserDefaults.
    ///
    /// Not all features are user togglable. If there exists no feature key - as defined
    /// in the `featureKey()` function - with which to write to UserDefaults, then the
    /// feature cannot be turned on/off and its state can only be set when initialized,
    /// based on build channel.
    public func toggle() {
        guard let key = featureKey() else { return }
        profile.prefs.setBool(!isActive, forKey: key)
    }

    private func featureKey() -> String? {
        switch featureID {
        case .chronologicalTabs:
            return PrefsKeys.ChronTabsPrefKey
        case .inactiveTabs:
            return PrefsKeys.KeyEnableInactiveTabs
        case .jumpBackIn:
            return PrefsKeys.jumpBackInSectionEnabled
        case .recentlySaved:
            return PrefsKeys.recentlySavedSectionEnabled
        case .startAtHome:
            return PrefsKeys.StartAtHome
        default:
            return nil
        }
    }
}
