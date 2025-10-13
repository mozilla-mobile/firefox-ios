// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Ecosia

struct MockLocale: RegionLocatable {
    var regionIdentifierLowercasedWithFallbackValue: String
    var englishLocalizedCountryName: String?

    init(_ countryIdentier: String, countryName: String? = nil) {
        self.regionIdentifierLowercasedWithFallbackValue = countryIdentier
        self.englishLocalizedCountryName = countryName
    }
}
