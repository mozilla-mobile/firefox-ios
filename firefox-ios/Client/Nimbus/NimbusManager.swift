// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class NimbusManager: Sendable {
    // MARK: - Singleton
    static let shared = NimbusManager()

    // MARK: - Properties
    let featureFlagLayer: NimbusFeatureFlagLayer

    init(with featureFlagLayer: NimbusFeatureFlagLayer = NimbusFeatureFlagLayer()) {
        self.featureFlagLayer = featureFlagLayer
    }
}
