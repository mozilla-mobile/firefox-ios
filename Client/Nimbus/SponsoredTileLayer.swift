// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class SponsoredTileLayer {

    // MARK: - Public methods
    public func getMaxNumberOfTiles(from nimbus: FxNimbus = FxNimbus.shared) -> Int {
        return nimbus.features.homescreenFeature.value().sponsoredTiles.maxNumberOfTiles
    }
}
