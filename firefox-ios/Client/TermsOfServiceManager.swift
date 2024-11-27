// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

struct TermsOfServiceManager: FeatureFlaggable {
    var prefs: Prefs

    var shouldShowScreen: Bool {
        guard featureFlags.isFeatureEnabled(.tosFeature, checking: .buildAndUser) else { return false }

        return prefs.intForKey(PrefsKeys.TermsOfServiceAccepted) == nil
    }

    func setAccepted() {
        prefs.setInt(1, forKey: PrefsKeys.TermsOfServiceAccepted)
    }
}
