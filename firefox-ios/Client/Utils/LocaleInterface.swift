// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol LocaleInterface {
    var localeRegionCode: String? { get }
}

extension Locale: LocaleInterface {
    var localeRegionCode: String? {
        return self.regionCode
    }
}
