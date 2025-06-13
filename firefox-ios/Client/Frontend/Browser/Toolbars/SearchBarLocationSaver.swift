// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared

protocol SearchBarLocationSaverProtocol {
    func saveUserSearchBarLocation(profile: Profile, userInterfaceIdiom: UIUserInterfaceIdiom)
}

struct SearchBarLocationSaver: SearchBarLocationProvider, FeatureFlaggable, SearchBarLocationSaverProtocol {
    /// Saves the search bar location position to user preferences for existing users
    /// that didn't have the position saved yet. For users on iPhone with version1 or version2 as layout the
    /// search bar location position is set to bottom, otherwise the default is used.
    /// - Parameters:
    ///   - profile: the user's profile
    ///   - userInterfaceIdiom: the interface type for the device
    func saveUserSearchBarLocation(profile: Profile,
                                   userInterfaceIdiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom) {
        let isFreshInstall = profile.prefs.stringForKey(PrefsKeys.AppVersion.Latest) == nil
        let hasSearchBarPosition = profile.prefs.stringForKey(PrefsKeys.FeatureFlags.SearchBarPosition) != nil

        // no search bar position saved for existing user (not fresh install)
        guard !isFreshInstall && !hasSearchBarPosition else { return }

        let isToolbarRefactorEnabled = featureFlags.isFeatureEnabled(.toolbarRefactor, checking: .buildOnly)
        let layout = FxNimbus.shared.features.toolbarRefactorFeature.value().layout
        let isVersionLayout = layout == .version1 || layout == .version2

        guard userInterfaceIdiom != .pad, isToolbarRefactorEnabled, isVersionLayout else {
            let isAtBottom = isBottomSearchBar
            let searchBarPosition: SearchBarPosition = isAtBottom ? .bottom : .top
            featureFlags.set(feature: .searchBarPosition, to: searchBarPosition)
            return
        }

        // Set the address bar to the bottom for new users enrolled in `version1` or `version2` toolbar experiment.
        featureFlags.set(feature: .searchBarPosition, to: SearchBarPosition.bottom)
    }
}
