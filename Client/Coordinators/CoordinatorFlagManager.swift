// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

/// This is a temporary struct made to manage the coordinator multiple feature flag for conveniance
struct CoordinatorFlagManager {
    /// This will be removed with FXIOS-6529
    static var isSettingsCoordinatorEnabled: Bool {
        return LegacyFeatureFlagsManager.shared.isFeatureEnabled(.settingsCoordinatorRefactor,
                                                                 checking: .buildOnly)
    }

    /// This will be removed with FXIOS-6530
    static var isLibraryCoordinatorEnabled: Bool {
        return LegacyFeatureFlagsManager.shared.isFeatureEnabled(.libraryCoordinatorRefactor,
                                                                 checking: .buildOnly)
    }

    static var isShareExtensionCoordinatorEnabled: Bool {
        NimbusManager.shared.featureFlagLayer.checkNimbusConfigFor(.shareExtensionCoordinatorRefactor)
    }

    static var isEtpCoordinatorEnabled: Bool {
        return CoordinatorFlagManager.isSettingsCoordinatorEnabled
        && LegacyFeatureFlagsManager.shared.isFeatureEnabled(.etpCoordinatorRefactor,
                                                             checking: .buildOnly)
    }
}
