// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Glean

struct TermsOfServiceManager: FeatureFlaggable {
    var prefs: Prefs

    var isFeatureEnabled: Bool {
        featureFlags.isFeatureEnabled(.tosFeature, checking: .buildAndUser)
    }

    var isAccepted: Bool {
        prefs.intForKey(PrefsKeys.TermsOfServiceAccepted) == 1
    }

    var shouldShowScreen: Bool {
        guard featureFlags.isFeatureEnabled(.tosFeature, checking: .buildAndUser) else { return false }

        return prefs.intForKey(PrefsKeys.TermsOfServiceAccepted) == nil
    }

    func setAccepted() {
        prefs.setInt(1, forKey: PrefsKeys.TermsOfServiceAccepted)
    }

    func shouldSendTechnicalData(value: Bool) {
        // AdjustHelper.setEnabled($0)
        DefaultGleanWrapper.shared.setUpload(isEnabled: value)

        if !value {
            prefs.removeObjectForKey(PrefsKeys.Usage.profileId)

            // set dummy uuid to make sure the previous one is deleted
            if let uuid = UUID(uuidString: "beefbeef-beef-beef-beef-beeefbeefbee") {
                GleanMetrics.Usage.profileId.set(uuid)
            }
        }

        Experiments.setTelemetrySetting(value)
    }
}
