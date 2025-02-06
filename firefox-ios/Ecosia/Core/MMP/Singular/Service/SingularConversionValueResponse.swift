// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct SingularConversionValueResponse: Codable, Equatable {
    let conversionValue: Int
    let coarseValue: Int?
    let lockWindow: Bool?

    enum CodingKeys: String, CodingKey {
        case conversionValue = "conversion_value"
        case coarseValue = "skan_updated_coarse_value"
        case lockWindow = "skan_updated_lock_window_value"
    }

    var isValid: Bool {
        (0...63 ~= conversionValue) && (0...2 ~= coarseValue ?? 1)
    }
}
