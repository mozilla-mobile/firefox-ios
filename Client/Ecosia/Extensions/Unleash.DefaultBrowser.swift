// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Core

extension Unleash {

    public static func getRequiredSearches() -> Int {
        let variant = getVariant(.defaultBrowser)
        return getRequiredSearches(for: variant)
    }

    static func getRequiredSearches(for variant: Variant) -> Int {
        switch variant.name {
        case "test1": return 5
        case "test2": return 25
        case "test3": return 50
        default: return 0
        }
    }
}
