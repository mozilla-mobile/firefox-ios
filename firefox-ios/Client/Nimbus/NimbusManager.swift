// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// TODO: Roux remove with 15192
protocol HasNimbusFeatureFlagLayer { }

extension HasNimbusFeatureFlagLayer {
    var nimbusFlags: NimbusFeatureFlagLayer {
        return NimbusManager.shared.featureFlagLayer
    }
}

final class NimbusManager: Sendable {
    // MARK: - Singleton

    /// To help with access control, we should use protocols to access the required
    /// layers. `.shared` should, ideally, never be directly accessed.
    static let shared = NimbusManager()

    // MARK: - Properties
    let featureFlagLayer: NimbusFeatureFlagLayer

    init(with featureFlagLayer: NimbusFeatureFlagLayer = NimbusFeatureFlagLayer()) {
        self.featureFlagLayer = featureFlagLayer
    }
}
