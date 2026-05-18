// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared

protocol SearchBarLocationSaverProtocol {
    @MainActor
    func saveUserSearchBarLocation(profile: Profile, userInterfaceIdiom: UIUserInterfaceIdiom)

    @MainActor
    func migrateBottomBarPositionToTopOnIPad(profile: Profile, userInterfaceIdiom: UIUserInterfaceIdiom)
}

struct SearchBarLocationSaver: SearchBarLocationProvider,
                               UserFeaturePreferenceProvider,
                               SearchBarLocationSaverProtocol {
    /// Saves the search bar location position to user preferences for existing users
    /// that didn't have the position saved yet. For users on iPhone with version1 or version2 as layout the
    /// search bar location position is set to bottom, otherwise the default is used.
    /// - Parameters:
    ///   - profile: the user's profile
    ///   - userInterfaceIdiom: the interface type for the device
    @MainActor
    func saveUserSearchBarLocation(
        profile: Profile,
        userInterfaceIdiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom
    ) {
        let isFreshInstall = profile.prefs.stringForKey(PrefsKeys.AppVersion.Latest) == nil
        let hasSearchBarPosition = profile.prefs.stringForKey(PrefsKeys.FeatureFlags.SearchBarPosition) != nil

        // no search bar position saved for existing user (not fresh install)
        guard !isFreshInstall && !hasSearchBarPosition else { return }

        guard userInterfaceIdiom != .pad else {
            userPreferences.setSearchBarPosition(.top)
            return
        }

        userPreferences.setSearchBarPosition(.bottom)
    }

    /// One-shot migration: iPad users who landed on `.bottom` due to the FXIOS-15232
    /// regression (which briefly exposed the toolbar setting on iPad) are reset to
    /// `.top`. The pref is read directly because the regular getter clamps to `.top`
    /// on iPad and would mask the stale write.
    /// TODO: FXIOS-15668 Remove this migration after enough release cycles have
    /// passed for affected users to launch a fixed build.
    @MainActor
    func migrateBottomBarPositionToTopOnIPad(
        profile: Profile,
        userInterfaceIdiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom
    ) {
        guard userInterfaceIdiom == .pad else { return }
        let saved = profile.prefs.stringForKey(PrefsKeys.FeatureFlags.SearchBarPosition)
        guard saved == SearchBarPosition.bottom.rawValue else { return }
        userPreferences.setSearchBarPosition(.top)
    }
}
