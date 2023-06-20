// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// This is a temporary struct made to manage the feature flag for convenience
struct ReduxFlagManager {
    static var isReduxEnabled: Bool {
        return LegacyFeatureFlagsManager.shared.isFeatureEnabled(.reduxIntegration,
                                                                 checking: .buildOnly)
    }
}
