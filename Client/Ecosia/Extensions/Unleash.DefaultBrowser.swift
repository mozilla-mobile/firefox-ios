// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Core

extension Unleash {

    static func minPromoSearches() -> Int {
        let variant = getVariant(.defaultBrowser)
        return minSearches(for: variant)
    }

    static func minSearches(for variant: Variant) -> Int {
        switch variant.name {
        case "control": return 0
        case "test1": return 5
        case "test2": return 25
        case "test3": return 50
        default: return .max
        }
    }

    static func isInPromoTest() -> Bool {
        let variant = getVariant(.defaultBrowser)
        return variant.name.hasPrefix("test")
    }
}
