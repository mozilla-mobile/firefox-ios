// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

final class PrivateTabsLockFeatureGate: FeatureFlaggable {
    
    private let prefs: Prefs
    init(prefs: Prefs) {
        self.prefs = prefs
    }
    
    var isEnabled: Bool {
        let shouldLock = prefs.boolForKey(PrefsKeys.Settings.lockPrivateTabs) ?? false
        let featureEnabled = featureFlags.isFeatureEnabled(.privateTabsLock, checking: .buildOnly)
        return shouldLock && featureEnabled
    }
}
