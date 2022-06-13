// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol HasNimbusFeatureFlags { }

extension HasNimbusFeatureFlags {
    var nimbusFlags: NimbusFeatureFlagLayer {
        return NimbusManager.shared.featureFlagLayer
    }
}

protocol HasNimbusSearchBar { }

extension HasNimbusSearchBar {
    var nimbusSearchBar: NimbusSearchBarLayer {
        return NimbusManager.shared.bottomSearchBarLayer
    }
}

protocol HasNimbusSponsoredTiles { }

extension HasNimbusSponsoredTiles {
    var nimbusSponoredTiles: NimbusSponsoredTileLayer {
        return NimbusManager.shared.sponsoredTileLayer
    }
}

class NimbusManager {

    // MARK: - Singleton

    /// To help with access control, we should use protocols to access the required
    /// layers. `.shared` should, ideally, never be directly accessed.
    static let shared = NimbusManager()

    // MARK: - Properties
    var featureFlagLayer: NimbusFeatureFlagLayer
    var sponsoredTileLayer: NimbusSponsoredTileLayer
    var bottomSearchBarLayer: NimbusSearchBarLayer

    init(with featureFlagLayer: NimbusFeatureFlagLayer = NimbusFeatureFlagLayer(),
         sponsoredTileLayer: NimbusSponsoredTileLayer = NimbusSponsoredTileLayer(),
         bottomSearchBarLayer: NimbusSearchBarLayer = NimbusSearchBarLayer()
    ) {
        self.featureFlagLayer = featureFlagLayer
        self.sponsoredTileLayer = sponsoredTileLayer
        self.bottomSearchBarLayer = bottomSearchBarLayer
    }
}
