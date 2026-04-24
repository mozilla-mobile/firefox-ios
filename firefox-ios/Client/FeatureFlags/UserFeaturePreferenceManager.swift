// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

/// Protocol for reading/writing user feature preferences.
/// Bool preferences use the generic get/set keyed by FeatureFlagID.
/// Typed (non-bool) preferences have named properties.
protocol UserFeaturePreferring: Sendable {
    // Generic bool preference
    func getPreferenceFor(_ flag: FeatureFlagID) -> Bool
    func setPreferenceFor(_ flag: FeatureFlagID, to value: Bool)

    // Typed preferences
    var searchBarPosition: SearchBarPosition { get }
    var startAtHomeSetting: StartAtHome { get }

    func setSearchBarPosition(_ position: SearchBarPosition)
    func setStartAtHomeSetting(_ setting: StartAtHome)
}

final class UserFeaturePreferenceManager: UserFeaturePreferring, @unchecked Sendable {
    private let prefs: Prefs
    private let nimbusLayer: NimbusFeatureFlagLayer

    init(
        prefs: Prefs,
        nimbusLayer: NimbusFeatureFlagLayer = NimbusManager.shared.featureFlagLayer
    ) {
        self.prefs = prefs
        self.nimbusLayer = nimbusLayer
    }

    // MARK: - Generic bool preferences

    func getPreferenceFor(_ flag: FeatureFlagID) -> Bool {
        guard let key = flag.userPrefsKey else {
            return checkDefaultValue(for: flag)
        }
        return prefs.boolForKey(key) ?? checkDefaultValue(for: flag)
    }

    // Some features might have a differnt default value than what's provided by
    // the backend. Here, we can set our own default values.
    private func checkDefaultValue(for flag: FeatureFlagID) -> Bool {
        if flag == .aiKillSwitch {
            return false
        } else {
            return nimbusLayer.checkNimbusConfigFor(flag)
        }
    }

    func setPreferenceFor(_ flag: FeatureFlagID, to value: Bool) {
        guard let key = flag.userPrefsKey else { return }
        prefs.setBool(value, forKey: key)
    }

    // MARK: - Typed preferences

    var searchBarPosition: SearchBarPosition {
        if let raw = prefs.stringForKey(PrefsKeys.FeatureFlags.SearchBarPosition),
           let position = SearchBarPosition(rawValue: raw) {
            return position
        }
        return .top
    }

    var startAtHomeSetting: StartAtHome {
        if let raw = prefs.stringForKey(PrefsKeys.FeatureFlags.StartAtHome),
           let setting = StartAtHome(rawValue: raw) {
            return setting
        }
        return FxNimbus.shared.features.startAtHomeFeature.value().setting
    }

    // MARK: - Typed setters

    func setSearchBarPosition(_ position: SearchBarPosition) {
        prefs.setString(position.rawValue, forKey: PrefsKeys.FeatureFlags.SearchBarPosition)
    }

    func setStartAtHomeSetting(_ setting: StartAtHome) {
        prefs.setString(setting.rawValue, forKey: PrefsKeys.FeatureFlags.StartAtHome)
    }
}

// MARK: - DI Access Protocol

/// Adopt this protocol to access user feature preferences via AppContainer.
protocol UserFeaturePreferenceProvider {
    var userPreferences: UserFeaturePreferring { get }
}

extension UserFeaturePreferenceProvider {
    var userPreferences: UserFeaturePreferring {
        AppContainer.shared.resolve()
    }
}
