// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class FxHomeLogoHeaderViewModel {

    private let profile: Profile

    init(profile: Profile) {
        self.profile = profile
    }

    func shouldRunLogoAnimation() -> Bool {
        let localesAnimationIsAvailableFor = ["en_US", "es_US"]
        guard profile.prefs.intForKey(PrefsKeys.IntroSeen) != nil,
              !UserDefaults.standard.bool(forKey: PrefsKeys.WallpaperLogoHasShownAnimation),
              localesAnimationIsAvailableFor.contains(Locale.current.identifier)
        else { return false }

        return true
    }
}

// MARK: FXHomeViewModelProtocol
extension FxHomeLogoHeaderViewModel: FXHomeViewModelProtocol, FeatureFlaggable {

    var sectionType: FirefoxHomeSectionType {
        return .logoHeader
    }

    var isEnabled: Bool {
        return featureFlags.isFeatureEnabled(.wallpapers, checking: .buildOnly)
    }
}
