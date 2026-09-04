// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

@testable import Client

@MainActor
protocol FeatureFlagTestUtility {
    var mockProfile: MockProfile! { get }
    var mockNimbusLayer: MockNimbusFeatureFlagLayer! { get }
}

extension FeatureFlagTestUtility {
    func featureFlagsProviderFactory() -> FeatureFlagsProvider {
        return FeatureFlagsProvider(
            prefs: mockProfile.prefs,
            backendLayer: mockNimbusLayer
        )
    }

    func userFeaturePreferenceManagerFactory() -> UserFeaturePreferenceManager {
        return UserFeaturePreferenceManager(
            prefs: mockProfile.prefs,
            backendLayer: mockNimbusLayer
        )
    }

    /// Sets whether a given feature is enabled or disabled for unit tests.
    func setFeatureFlag(_ flag: FeatureFlagID, isEnabled: Bool) {
        if isEnabled {
            mockNimbusLayer.enabledFlags.insert(flag)
        } else {
            mockNimbusLayer.enabledFlags.remove(flag)
        }
    }
}
