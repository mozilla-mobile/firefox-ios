// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Core

struct DefaultBrowserExperiment {
    
    private init() {}

    static func minPromoSearches() -> Int {
        let variant = Unleash.getVariant(.defaultBrowser)
        return minSearches(for: variant)
    }

    static func minSearches(for variant: Unleash.Variant) -> Int {
        switch variant.name {
        case "control": return 0
        case "test1": return 5
        case "test2": return 25
        case "test3": return 50
        default: return .max
        }
    }

    static func isInPromoTest() -> Bool {
        let variant = Unleash.getVariant(.defaultBrowser)
        return variant.name.hasPrefix("test")
    }
}
