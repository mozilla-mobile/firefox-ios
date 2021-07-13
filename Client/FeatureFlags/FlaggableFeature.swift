/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared

/// A handy struct to set
struct PipelineBuildChannel {
    private var enabledChannels: [AppBuildChannel]

    init(isEnabledFor channels: [AppBuildChannel]) {
        self.enabledChannels = channels
    }

    func isChannelEnabled(_ channel: AppBuildChannel) -> Bool {
        return enabledChannels.contains(channel)
    }
}

struct FlaggableFeature: FFlaggableFeature {
    // MARK: - Variables
    private let profile: Profile
    private let buildChannels: PipelineBuildChannel

    var featureID: FeatureFlagID

    var isActive: Bool {
        if let key = featureKey(), let existingPref = profile.prefs.boolForKey(key) {
            return existingPref

        } else {
            #if MOZ_CHANNEL_RELEASE
            return buildChannels.isChannelEnabled(.release)
            #elseif MOZ_CHANNEL_BETA
            return buildChannels.isChannelEnabled(.beta)
            #elseif MOZ_CHANNEL_FENNEC
            return buildChannels.isChannelEnabled(.developer)
            #else
            return buildChannels.isChannelEnabled(.other)
            #endif
        }
    }

    init(withID featureID: FeatureFlagID, and profile: Profile, for channels: PipelineBuildChannel) {
        self.featureID = featureID
        self.profile = profile
        self.buildChannels = channels
    }

    /// Toggles a feature On or Off, and saves the status to UserDefaults.
    ///
    /// Not all features are togglable. If there exists no feature key with which
    /// to write to UserDefaults, then the feature cannot be turned on or off and
    /// its state can only be set when initialized, based on build channel.
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
        case .recentlySaved:
            return PrefsKeys.recentlySavedSectionEnabled
        default:
            return nil
        }
    }
}
