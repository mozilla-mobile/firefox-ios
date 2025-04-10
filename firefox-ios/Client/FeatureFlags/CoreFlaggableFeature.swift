// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// Core features are features that are used for developer purposes and are
/// not directly user impacting. As such, the majority of features implemented
/// should NOT be considered core features.
enum CoreFeatureFlagID {
    case adjustEnvironmentProd
    case useMockData
    case useStagingContileAPI
}

struct CoreFlaggableFeature {
    // MARK: - Variables
    private let buildChannels: [AppBuildChannel]
    private var featureID: CoreFeatureFlagID

    // MARK: - Initializers
    init(withID featureID: CoreFeatureFlagID,
         enabledFor channels: [AppBuildChannel]
    ) {
        self.featureID = featureID
        self.buildChannels = channels
    }

    // MARK: - Public methods

    /// Returns whether or not the feature is active for the build.
    public func isActiveForBuild() -> Bool {
        #if MOZ_CHANNEL_release
            return buildChannels.contains(.release)
        #elseif MOZ_CHANNEL_beta
            return buildChannels.contains(.beta)
        #elseif MOZ_CHANNEL_developer
            return buildChannels.contains(.developer)
        #else
            return buildChannels.contains(.other)
        #endif
    }
}
