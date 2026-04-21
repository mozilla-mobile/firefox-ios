// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

/// Protocol for reading/writing user feature preferences.
/// Each property reads from Prefs, falling back to the Nimbus default.
protocol UserFeaturePreferring: Sendable {
    // Bool preferences (read)
    var isAIKillSwitchEnabled: Bool { get }
    var isFirefoxSuggestEnabled: Bool { get }
    var isSentFromFirefoxEnabled: Bool { get }
    var isSponsoredShortcutsEnabled: Bool { get }
    var isHomepageBookmarksSectionEnabled: Bool { get }
    var isHomepageJumpBackInSectionEnabled: Bool { get }

    // Typed preferences (read)
    var searchBarPosition: SearchBarPosition { get }
    var startAtHomeSetting: StartAtHome { get }

    // Setters
    func setAIKillSwitchEnabled(_ enabled: Bool)
    func setFirefoxSuggestEnabled(_ enabled: Bool)
    func setSentFromFirefoxEnabled(_ enabled: Bool)
    func setSponsoredShortcutsEnabled(_ enabled: Bool)
    func setHomepageBookmarksSectionEnabled(_ enabled: Bool)
    func setHomepageJumpBackInSectionEnabled(_ enabled: Bool)
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

    // MARK: - Bool preferences

    var isAIKillSwitchEnabled: Bool {
        prefs.boolForKey(PrefsKeys.Settings.aiKillSwitchFeature)
        ?? nimbusLayer.checkNimbusConfigFor(.aiKillSwitch)
    }

    var isFirefoxSuggestEnabled: Bool {
        prefs.boolForKey(PrefsKeys.FeatureFlags.FirefoxSuggest)
        ?? nimbusLayer.checkNimbusConfigFor(.firefoxSuggestFeature)
    }

    var isSentFromFirefoxEnabled: Bool {
        prefs.boolForKey(PrefsKeys.FeatureFlags.SentFromFirefox)
        ?? nimbusLayer.checkNimbusConfigFor(.sentFromFirefox)
    }

    var isSponsoredShortcutsEnabled: Bool {
        prefs.boolForKey(PrefsKeys.FeatureFlags.SponsoredShortcuts)
        ?? nimbusLayer.checkNimbusConfigFor(.hntSponsoredShortcuts)
    }

    var isHomepageBookmarksSectionEnabled: Bool {
        prefs.boolForKey(PrefsKeys.HomepageSettings.BookmarksSection)
        ?? nimbusLayer.checkNimbusConfigFor(.homepageBookmarksSectionDefault)
    }

    var isHomepageJumpBackInSectionEnabled: Bool {
        prefs.boolForKey(PrefsKeys.HomepageSettings.JumpBackInSection)
        ?? nimbusLayer.checkNimbusConfigFor(.homepageJumpBackinSectionDefault)
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

    // MARK: - Setters

    func setAIKillSwitchEnabled(_ enabled: Bool) {
        prefs.setBool(enabled, forKey: PrefsKeys.Settings.aiKillSwitchFeature)
    }

    func setFirefoxSuggestEnabled(_ enabled: Bool) {
        prefs.setBool(enabled, forKey: PrefsKeys.FeatureFlags.FirefoxSuggest)
    }

    func setSentFromFirefoxEnabled(_ enabled: Bool) {
        prefs.setBool(enabled, forKey: PrefsKeys.FeatureFlags.SentFromFirefox)
    }

    func setSponsoredShortcutsEnabled(_ enabled: Bool) {
        prefs.setBool(enabled, forKey: PrefsKeys.FeatureFlags.SponsoredShortcuts)
    }

    func setHomepageBookmarksSectionEnabled(_ enabled: Bool) {
        prefs.setBool(enabled, forKey: PrefsKeys.HomepageSettings.BookmarksSection)
    }

    func setHomepageJumpBackInSectionEnabled(_ enabled: Bool) {
        prefs.setBool(enabled, forKey: PrefsKeys.HomepageSettings.JumpBackInSection)
    }

    func setSearchBarPosition(_ position: SearchBarPosition) {
        prefs.setString(position.rawValue, forKey: PrefsKeys.FeatureFlags.SearchBarPosition)
    }

    func setStartAtHomeSetting(_ setting: StartAtHome) {
        prefs.setString(setting.rawValue, forKey: PrefsKeys.FeatureFlags.StartAtHome)
    }
}

// MARK: - DI Access Protocol

/// Adopt this protocol to access user feature preferences via AppContainer.
/// Replaces FeatureFlaggable for user preference checks.
protocol HasUserFeaturePreferences {
    var userPreferences: UserFeaturePreferring { get }
}

extension HasUserFeaturePreferences {
    var userPreferences: UserFeaturePreferring {
        AppContainer.shared.resolve()
    }
}
