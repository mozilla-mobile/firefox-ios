// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct AddressFormData1: Codable {
    let type: String
    let category: String?
    let method: String?
    let object: String?
    let value: String
    let extra: ExtraData?

    struct ExtraData: Codable {
        let streetAddress: String
        let addressLine1: String
        let addressLine2: String
        let addressLine3: String
        let addressLevel1: String
        let addressLevel2: String
        let postalCode: String
        let country: String
        let name: String?

        enum CodingKeys: String, CodingKey {
            case streetAddress = "street_address"
            case addressLine1 = "address_line1"
            case addressLine2 = "address_line2"
            case addressLine3 = "address_line3"
            case addressLevel1 = "address_level1"
            case addressLevel2 = "address_level2"
            case postalCode = "postal_code"
            case country
            case name
        }
    }
}
