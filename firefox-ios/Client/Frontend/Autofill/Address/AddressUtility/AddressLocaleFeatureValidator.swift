// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct AddressLocaleFeatureValidator {
    static let supportedRegions = ["CA", "US"]

    static func isValidRegion(locale: Locale = Locale.current) -> Bool {
        guard let regionCode = locale.regionCode else {
            return false
        }
        return supportedRegions.contains(regionCode)
    }
}
