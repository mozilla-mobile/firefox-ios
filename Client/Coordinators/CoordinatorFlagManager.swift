// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

/// This is a temporary struct made to manage the feature flag for conveniance
/// This will be removed with FXIOS-6036
struct CoordinatorFlagManager {
    static var isCoordinatorEnabled: Bool {
        return FeatureFlagsManager.shared.isFeatureEnabled(.coordinatorsRefactor,
                                                           checking: .buildOnly)
    }
}
