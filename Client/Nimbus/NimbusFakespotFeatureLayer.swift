// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class NimbusFakespotFeatureLayer {
    private let fakespotFeature = FxNimbus.shared.features.fakespotFeature.value()

    func getRegexProductIDPatterns() -> [String] {
        fakespotFeature.config.compactMap { item in
            item.value.productIdFromUrlRegex
        }
    }
}
