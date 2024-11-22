// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

class MockFeatureFlagManager: FeatureFlaggable {
    private var overriddenFeatures: [NimbusFeatureFlagID: Bool] = [:]

    func isFeatureEnabled(_ featureID: NimbusFeatureFlagID, checking channelsToCheck: FlaggableFeatureCheckOptions) -> Bool {
        guard let value = overriddenFeatures[featureID] else {
            // ?? Override all features to true
            return true
        }
        return value
    }

    func overrideFeature(_ featureID: NimbusFeatureFlagID, value: Bool) {
        overriddenFeatures[featureID] = value
    }

    func clearOverriddenFeatures() {
        overriddenFeatures.removeAll()
    }
}
